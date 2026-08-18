import os
import numpy as np
from PIL import Image
import tensorflow as tf
from tensorflow.keras.applications.mobilenet_v2 import preprocess_input

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

H5_PATH = os.path.join(BASE_DIR, "model.h5")
TFLITE_PATH = os.path.join(BASE_DIR, "model.tflite")
LABELS_PATH = os.path.join(BASE_DIR, "labels.txt")
IMAGE_PATH = os.path.join(BASE_DIR, "Powdery_Mildew (1).jpg")

IMG_SIZE = (224, 224)

for path in [H5_PATH, TFLITE_PATH, LABELS_PATH, IMAGE_PATH]:
    if not os.path.exists(path):
        raise FileNotFoundError(f"Missing file: {path}")

with open(LABELS_PATH, "r", encoding="utf-8") as f:
    labels = [line.strip() for line in f if line.strip()]

image = Image.open(IMAGE_PATH).convert("RGB")
image = image.resize(IMG_SIZE)
image_array = np.array(image).astype("float32")
input_data = np.expand_dims(image_array, axis=0)

print("=" * 55)
print("MODEL COMPARISON TEST")
print("=" * 55)
print("TensorFlow:", tf.__version__)
print("Image:", os.path.basename(IMAGE_PATH))
print("Labels:", labels)

# H5
print("\nLoading H5 model...")
h5_model = tf.keras.models.load_model(
    H5_PATH,
    custom_objects={"preprocess_input": preprocess_input},
    compile=False,
    safe_mode=False,
)
h5_output = h5_model.predict(input_data, verbose=0)[0]
h5_index = int(np.argmax(h5_output))
h5_confidence = float(h5_output[h5_index]) * 100

# TFLite
print("Loading TFLite model...")
interpreter = tf.lite.Interpreter(model_path=TFLITE_PATH)
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

expected_dtype = input_details[0]["dtype"]
tflite_input = input_data.astype(expected_dtype)

interpreter.set_tensor(input_details[0]["index"], tflite_input)
interpreter.invoke()
tflite_output = interpreter.get_tensor(output_details[0]["index"])[0]

tflite_index = int(np.argmax(tflite_output))
tflite_confidence = float(tflite_output[tflite_index]) * 100

print("\n" + "=" * 55)
print("H5 MODEL")
print("=" * 55)
print("Prediction :", labels[h5_index])
print(f"Confidence : {h5_confidence:.2f}%")
print("Raw output :", h5_output)

print("\n" + "=" * 55)
print("TFLITE MODEL")
print("=" * 55)
print("Prediction :", labels[tflite_index])
print(f"Confidence : {tflite_confidence:.2f}%")
print("Raw output :", tflite_output)

print("\n" + "=" * 55)
if h5_index == tflite_index:
    difference = abs(h5_confidence - tflite_confidence)
    print("RESULT: MATCH")
    print(f"Confidence difference: {difference:.4f}%")
    if difference < 1.0:
        print("The TFLite conversion looks excellent.")
    else:
        print("The class matches, but review the confidence difference.")
else:
    print("RESULT: DO NOT MATCH")
    print("Do not integrate the TFLite model into Flutter yet.")
print("=" * 55)