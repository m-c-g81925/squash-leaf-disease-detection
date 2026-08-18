import os
from pathlib import Path
from uuid import uuid4

from dotenv import load_dotenv
from supabase import Client, create_client


# ============================================================
# LOAD ENVIRONMENT VARIABLES
# ============================================================

BASE_DIR = Path(__file__).resolve().parent

load_dotenv(
    BASE_DIR / ".env"
)


SUPABASE_URL = os.getenv(
    "SUPABASE_URL"
)

SUPABASE_SECRET_KEY = os.getenv(
    "SUPABASE_SECRET_KEY"
)

SUPABASE_BUCKET = os.getenv(
    "SUPABASE_BUCKET",
    "expert-review-images",
)


if not SUPABASE_URL:
    raise RuntimeError(
        "SUPABASE_URL is missing from .env"
    )


if not SUPABASE_SECRET_KEY:
    raise RuntimeError(
        "SUPABASE_SECRET_KEY is missing from .env"
    )


# ============================================================
# SUPABASE CLIENT
# ============================================================

supabase: Client = create_client(
    SUPABASE_URL,
    SUPABASE_SECRET_KEY,
)


# ============================================================
# UPLOAD EXPERT REVIEW IMAGE
# ============================================================

def upload_expert_review_image(
    image_bytes: bytes,
    user_id: str,
    content_type: str,
) -> str:
    """
    Upload an expert-review image to the private
    Supabase Storage bucket.

    Supported:
    - .jpg
    - .jpeg
    - .png

    Returns the private storage path.
    """

    content_type = (
        content_type
        .lower()
        .strip()
    )


    # JPG and JPEG both use image/jpeg.
    if content_type in (
        "image/jpeg",
        "image/jpg",
    ):
        extension = "jpg"

        # Always normalize JPG/JPEG to the
        # standard MIME type.
        content_type = "image/jpeg"


    elif content_type == "image/png":
        extension = "png"


    else:
        raise ValueError(
            "Only JPG, JPEG, and PNG images are allowed."
        )


    # Generate a unique filename.
    filename = (
        f"{uuid4()}.{extension}"
    )


    # Each Firebase farmer gets their own
    # folder inside Supabase Storage.
    storage_path = (
        f"{user_id}/{filename}"
    )


    # Upload to private Supabase bucket.
    supabase.storage.from_(
        SUPABASE_BUCKET
    ).upload(
        path=storage_path,
        file=image_bytes,
        file_options={
            "content-type": content_type,
            "upsert": "false",
        },
    )


    print(
        "SUPABASE IMAGE UPLOADED:",
        storage_path,
    )


    return storage_path


# ============================================================
# CREATE TEMPORARY SIGNED URL
# ============================================================

def create_expert_review_signed_url(
    storage_path: str,
    expires_in: int = 300,
) -> str:
    """
    Generate a temporary signed URL for an image
    stored inside the private Supabase bucket.

    Default expiration:
    300 seconds = 5 minutes.
    """

    result = (
        supabase.storage
        .from_(SUPABASE_BUCKET)
        .create_signed_url(
            storage_path,
            expires_in,
        )
    )


    signed_url = (
        result.get("signedURL")
        or result.get("signedUrl")
    )


    if not signed_url:
        raise RuntimeError(
            "Supabase did not return a signed image URL."
        )


    return signed_url