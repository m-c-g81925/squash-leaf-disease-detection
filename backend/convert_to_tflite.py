import os

import tensorflow as tf
from tensorflow.keras.applications.mobilenet_v2 import preprocess_input

# ------------------------------------------------------------
# Paths
# ------------------------------------------------------------
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, "model.h5")
TFLITE_PATH = os.path.join(BASE_DIR, "model.tflite")

print("TensorFlow version:", tf.__version__)
print("Model path:", MODEL_PATH)
print("Model exists:", os.path.exists(MODEL_PATH))

if not os.path.exists(MODEL_PATH):
    raise FileNotFoundError(
        f"model.h5 was not found in this folder:\n{BASE_DIR}"
    )

# ------------------------------------------------------------
# Load the same Keras model used by the FastAPI backend.
# Your model contains preprocess_input, so we provide it as a
# custom object just like the working FastAPI code does.
# ------------------------------------------------------------
print("\nLoading model.h5...")

model = tf.keras.models.load_model(
    MODEL_PATH,
    custom_objects={
        "preprocess_input": preprocess_input,
    },
    compile=False,
    safe_mode=False,
)

print("Model loaded successfully.")
print("Input shape:", model.input_shape)
print("Output shape:", model.output_shape)

# ------------------------------------------------------------
# Convert Keras model to TensorFlow Lite.
# We start with standard float32 conversion so prediction
# behavior stays as close as possible to the original model.
# ------------------------------------------------------------
print("\nConverting model to TensorFlow Lite...")

converter = tf.lite.TFLiteConverter.from_keras_model(model)

tflite_model = converter.convert()

# ------------------------------------------------------------
# Save model.tflite beside model.h5.
# ------------------------------------------------------------
with open(TFLITE_PATH, "wb") as file:
    file.write(tflite_model)

size_mb = os.path.getsize(TFLITE_PATH) / (1024 * 1024)

print("\nConversion completed successfully!")
print("TFLite model:", TFLITE_PATH)
print(f"TFLite size: {size_mb:.2f} MB")
print("\nKeep your original model.h5 as a backup.")