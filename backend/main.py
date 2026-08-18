from fastapi import (
    FastAPI,
    File,
    UploadFile,
    Header,
    HTTPException,
)

from fastapi.middleware.cors import (
    CORSMiddleware,
)

import firebase_admin

from firebase_admin import (
    auth,
    credentials,
    firestore,
)

import tensorflow as tf

from tensorflow.keras.applications.mobilenet_v2 import (
    preprocess_input,
)

import numpy as np

from PIL import Image

import io
import os
import json

from supabase_storage import (
    upload_expert_review_image,
    create_expert_review_signed_url,
)


# ============================================================
# FASTAPI APP
# ============================================================

app = FastAPI()


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================
# FILE PATHS
# ============================================================

BASE_DIR = os.path.dirname(
    os.path.abspath(__file__)
)


MODEL_PATH = os.path.join(
    BASE_DIR,
    "model.h5",
)


LABELS_PATH = os.path.join(
    BASE_DIR,
    "labels.txt",
)


FIREBASE_SERVICE_ACCOUNT_PATH = os.path.join(
    BASE_DIR,
    "firebase-service-account.json",
)


# ============================================================
# FIREBASE ADMIN
# ============================================================

# Cloud deployment:
# Set FIREBASE_SERVICE_ACCOUNT_JSON as an environment variable
# containing the full Firebase service-account JSON.
#
# Local development:
# If the environment variable is not set, the backend falls
# back to firebase-service-account.json in this folder.

FIREBASE_SERVICE_ACCOUNT_JSON = os.getenv(
    "FIREBASE_SERVICE_ACCOUNT_JSON"
)


if not firebase_admin._apps:

    if FIREBASE_SERVICE_ACCOUNT_JSON:

        try:

            firebase_service_account = json.loads(
                FIREBASE_SERVICE_ACCOUNT_JSON
            )

            firebase_credential = credentials.Certificate(
                firebase_service_account
            )

        except Exception as error:

            raise RuntimeError(
                "Invalid FIREBASE_SERVICE_ACCOUNT_JSON "
                f"environment variable: {error}"
            )

    else:

        if not os.path.exists(
            FIREBASE_SERVICE_ACCOUNT_PATH
        ):

            raise RuntimeError(
                "Firebase credentials were not found. "
                "Set FIREBASE_SERVICE_ACCOUNT_JSON "
                "for cloud deployment or place "
                "firebase-service-account.json "
                "inside the backend folder."
            )

        firebase_credential = credentials.Certificate(
            FIREBASE_SERVICE_ACCOUNT_PATH
        )

    firebase_admin.initialize_app(
        firebase_credential
    )


firestore_db = firestore.client()


# ============================================================
# VERIFY FIREBASE USER
# ============================================================

def verify_firebase_user(
    authorization: str | None,
) -> dict:

    if not authorization:

        raise HTTPException(
            status_code=401,
            detail=(
                "Authorization header is missing."
            ),
        )


    if not authorization.startswith(
        "Bearer "
    ):

        raise HTTPException(
            status_code=401,
            detail=(
                "Invalid authorization format."
            ),
        )


    token = authorization.replace(
        "Bearer ",
        "",
        1,
    ).strip()


    if not token:

        raise HTTPException(
            status_code=401,
            detail=(
                "Firebase ID token is missing."
            ),
        )


    try:

        decoded_token = (
            auth.verify_id_token(
                token
            )
        )

        return decoded_token


    except Exception as error:

        print(
            "FIREBASE TOKEN ERROR:",
            error,
        )

        raise HTTPException(
            status_code=401,
            detail=(
                "Invalid or expired Firebase token."
            ),
        )


# ============================================================
# GET USER ROLE
# ============================================================

def get_user_role(
    user_id: str,
) -> str:

    document = (
        firestore_db
        .collection("users")
        .document(user_id)
        .get()
    )


    if not document.exists:

        raise HTTPException(
            status_code=403,
            detail=(
                "User record was not found."
            ),
        )


    data = (
        document.to_dict()
        or {}
    )


    is_active = data.get(
        "isActive",
        False,
    )


    if is_active is not True:

        raise HTTPException(
            status_code=403,
            detail=(
                "This account is inactive."
            ),
        )


    role = str(
        data.get(
            "role",
            "",
        )
    ).strip().lower()


    if role not in [
        "farmer",
        "agriculturist",
    ]:

        raise HTTPException(
            status_code=403,
            detail=(
                "Invalid user role."
            ),
        )


    return role


# ============================================================
# LOAD CNN MODEL
# ============================================================

print(
    "BACKEND FOLDER:",
    BASE_DIR,
)

print(
    "MODEL PATH:",
    MODEL_PATH,
)

print(
    "MODEL EXISTS:",
    os.path.exists(
        MODEL_PATH
    ),
)

print(
    "LABELS PATH:",
    LABELS_PATH,
)

print(
    "LABELS EXISTS:",
    os.path.exists(
        LABELS_PATH
    ),
)


model = tf.keras.models.load_model(
    MODEL_PATH,
    custom_objects={
        "preprocess_input":
            preprocess_input,
    },
    safe_mode=False,
)


with open(
    LABELS_PATH,
    "r",
    encoding="utf-8",
) as file:

    class_names = [
        line.strip()
        for line
        in file.readlines()
        if line.strip()
    ]


print(
    "MODEL LOADED SUCCESSFULLY"
)

print(
    "LABELS:",
    class_names,
)


IMG_SIZE = (
    224,
    224,
)


# ============================================================
# EXPERT REVIEW IMAGE SETTINGS
# ============================================================

# Maximum image size:
# 5 MB

MAX_EXPERT_IMAGE_SIZE = (
    5 * 1024 * 1024
)


# Supported MIME types.
#
# .jpg  -> image/jpeg
# .jpeg -> image/jpeg
# .png  -> image/png

ALLOWED_IMAGE_TYPES = {
    "image/jpeg",
    "image/jpg",
    "image/png",
}


# ============================================================
# HOME
# ============================================================

@app.get("/")
def home():

    return {
        "message":
            "Backend Running",

        "labels":
            class_names,

        "model_path":
            MODEL_PATH,

        "expert_review_storage":
            "Supabase",

        "supported_images": [
            "JPG",
            "JPEG",
            "PNG",
        ],
    }


# ============================================================
# CNN PREDICTION
# ============================================================

@app.post("/predict")
async def predict(
    file: UploadFile = File(...),
):

    image_bytes = (
        await file.read()
    )


    try:

        image = Image.open(
            io.BytesIO(
                image_bytes
            )
        ).convert(
            "RGB"
        )

    except Exception:

        raise HTTPException(
            status_code=400,
            detail=(
                "The uploaded file is not "
                "a valid image."
            ),
        )


    image = image.resize(
        IMG_SIZE
    )


    # Do NOT call preprocess_input here.
    # It already exists inside the model.

    img_array = np.array(
        image
    ).astype(
        "float32"
    )


    img_array = np.expand_dims(
        img_array,
        axis=0,
    )


    prediction = model.predict(
        img_array
    )


    print(
        "RAW PREDICTION:",
        prediction[0],
    )


    predicted_index = int(
        np.argmax(
            prediction[0]
        )
    )


    confidence = float(
        np.max(
            prediction[0]
        )
    )


    disease = class_names[
        predicted_index
    ]


    print(
        "PREDICTED INDEX:",
        predicted_index,
    )

    print(
        "PREDICTED DISEASE:",
        disease,
    )

    print(
        "CONFIDENCE:",
        confidence,
    )


    return {
        "disease":
            disease,

        "confidence":
            round(
                confidence * 100,
                2,
            ),

        "all_predictions": {

            class_names[i]:
                round(
                    float(
                        prediction[0][i]
                    ) * 100,
                    2,
                )

            for i in range(
                len(class_names)
            )
        },
    }


# ============================================================
# EXPERT REVIEW IMAGE UPLOAD
# ============================================================

@app.post(
    "/expert-review/upload"
)
async def upload_expert_review(
    file: UploadFile = File(...),

    authorization: str | None = Header(
        default=None
    ),
):

    # --------------------------------------------------------
    # VERIFY FIREBASE LOGIN
    # --------------------------------------------------------

    decoded_token = (
        verify_firebase_user(
            authorization
        )
    )


    user_id = decoded_token.get(
        "uid"
    )


    if not user_id:

        raise HTTPException(
            status_code=401,
            detail=(
                "Firebase UID was not found."
            ),
        )


    # --------------------------------------------------------
    # VERIFY FARMER ROLE
    # --------------------------------------------------------

    role = get_user_role(
        user_id
    )


    if role != "farmer":

        raise HTTPException(
            status_code=403,
            detail=(
                "Only farmers can upload "
                "expert-review images."
            ),
        )


    # --------------------------------------------------------
    # CHECK IMAGE TYPE
    # --------------------------------------------------------

    content_type = (
        file.content_type
        or ""
    ).lower().strip()


    print(
        "RECEIVED IMAGE TYPE:",
        content_type,
    )

    print(
        "RECEIVED FILENAME:",
        file.filename,
    )


    if content_type not in (
        ALLOWED_IMAGE_TYPES
    ):

        raise HTTPException(
            status_code=400,
            detail=(
                "Only JPG, JPEG, and PNG "
                "images are allowed."
            ),
        )


    # Normalize non-standard image/jpg.
    if content_type == "image/jpg":
        content_type = "image/jpeg"


    # --------------------------------------------------------
    # READ IMAGE
    # --------------------------------------------------------

    image_bytes = (
        await file.read()
    )


    if not image_bytes:

        raise HTTPException(
            status_code=400,
            detail=(
                "The image file is empty."
            ),
        )


    # --------------------------------------------------------
    # CHECK FILE SIZE
    # --------------------------------------------------------

    if len(
        image_bytes
    ) > MAX_EXPERT_IMAGE_SIZE:

        raise HTTPException(
            status_code=400,
            detail=(
                "The image is larger "
                "than the 5 MB limit."
            ),
        )


    # --------------------------------------------------------
    # VERIFY THAT THE FILE IS ACTUALLY AN IMAGE
    # --------------------------------------------------------

    try:

        image = Image.open(
            io.BytesIO(
                image_bytes
            )
        )

        image.verify()


    except Exception:

        raise HTTPException(
            status_code=400,
            detail=(
                "The selected file is not "
                "a valid image."
            ),
        )


    # --------------------------------------------------------
    # UPLOAD TO SUPABASE
    # --------------------------------------------------------

    try:

        storage_path = (
            upload_expert_review_image(
                image_bytes=image_bytes,
                user_id=user_id,
                content_type=content_type,
            )
        )


        print(
            "EXPERT IMAGE UPLOADED:",
            storage_path,
        )


        return {
            "success": True,
            "imagePath":
                storage_path,
        }


    except ValueError as error:

        print(
            "IMAGE TYPE ERROR:",
            error,
        )


        raise HTTPException(
            status_code=400,
            detail=str(
                error
            ),
        )


    except Exception as error:

        print(
            "SUPABASE UPLOAD ERROR:",
            error,
        )


        raise HTTPException(
            status_code=500,
            detail=(
                "Unable to upload "
                "the expert-review image."
            ),
        )


# ============================================================
# GET PRIVATE EXPERT REVIEW IMAGE
# ============================================================

@app.get(
    "/expert-review/image"
)
async def get_expert_review_image(
    image_path: str,

    authorization: str | None = Header(
        default=None
    ),
):

    # --------------------------------------------------------
    # VERIFY FIREBASE LOGIN
    # --------------------------------------------------------

    decoded_token = (
        verify_firebase_user(
            authorization
        )
    )


    current_user_id = (
        decoded_token.get(
            "uid"
        )
    )


    if not current_user_id:

        raise HTTPException(
            status_code=401,
            detail=(
                "Firebase UID was not found."
            ),
        )


    # --------------------------------------------------------
    # GET USER ROLE
    # --------------------------------------------------------

    role = get_user_role(
        current_user_id
    )


    # --------------------------------------------------------
    # VALIDATE IMAGE PATH
    # --------------------------------------------------------

    clean_path = (
        image_path.strip()
    )


    if not clean_path:

        raise HTTPException(
            status_code=400,
            detail=(
                "Image path is missing."
            ),
        )


    if (
        ".." in clean_path
        or clean_path.startswith("/")
    ):

        raise HTTPException(
            status_code=400,
            detail=(
                "Invalid image path."
            ),
        )


    # First folder is the farmer's
    # Firebase UID.

    owner_user_id = (
        clean_path.split(
            "/",
            1,
        )[0]
    )


    # Agriculturists can view submitted
    # images.
    #
    # Farmers can only view their own.

    if (
        role != "agriculturist"
        and owner_user_id
        != current_user_id
    ):

        raise HTTPException(
            status_code=403,
            detail=(
                "You do not have permission "
                "to view this image."
            ),
        )


    # --------------------------------------------------------
    # CREATE TEMPORARY SIGNED URL
    # --------------------------------------------------------

    try:

        signed_url = (
            create_expert_review_signed_url(
                storage_path=
                    clean_path,

                # Five minutes.
                expires_in=300,
            )
        )


        return {
            "success": True,

            "signedUrl":
                signed_url,

            "expiresIn":
                300,
        }


    except Exception as error:

        print(
            "SIGNED URL ERROR:",
            error,
        )


        raise HTTPException(
            status_code=500,
            detail=(
                "Unable to open "
                "the expert-review image."
            ),
        )