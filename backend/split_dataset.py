import os
import random
import shutil
from pathlib import Path

SOURCE_DIR = Path("dataset")
OUTPUT_DIR = Path("dataset_split")

TRAIN_RATIO = 0.70
VAL_RATIO = 0.15
TEST_RATIO = 0.15

IMAGE_EXTENSIONS = [".jpg", ".jpeg", ".png", ".webp"]

random.seed(42)

for class_folder in SOURCE_DIR.iterdir():
    if not class_folder.is_dir():
        continue

    class_name = class_folder.name

    images = [
        file for file in class_folder.iterdir()
        if file.suffix.lower() in IMAGE_EXTENSIONS
    ]

    random.shuffle(images)

    total = len(images)
    train_count = int(total * TRAIN_RATIO)
    val_count = int(total * VAL_RATIO)

    train_images = images[:train_count]
    val_images = images[train_count:train_count + val_count]
    test_images = images[train_count + val_count:]

    for split_name, split_images in {
        "train": train_images,
        "validation": val_images,
        "test": test_images,
    }.items():
        split_class_dir = OUTPUT_DIR / split_name / class_name
        split_class_dir.mkdir(parents=True, exist_ok=True)

        for image in split_images:
            shutil.copy2(image, split_class_dir / image.name)

    print(f"{class_name}:")
    print(f"  Total: {total}")
    print(f"  Train: {len(train_images)}")
    print(f"  Validation: {len(val_images)}")
    print(f"  Test: {len(test_images)}")

print("\nDataset split completed!")