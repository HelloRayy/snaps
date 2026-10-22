import os
import urllib.request
from PIL import Image

ANIMALS = [
    "bear", "bunny", "cat", "deer", "dino", "fox", "frog",
    "hamster", "hedgehog", "koala", "mouse", "otter", "owl",
    "panda", "penguin", "pug", "raccoon", "redpanda", "sheep",
    "sloth", "tiger"
]

EMOTIONS = [
    ("blink", 0, 0),
    ("heart", 0, 1),
    ("sparkle", 0, 2),
    ("surprised", 1, 0),
    ("wink", 1, 1),
    ("bashful", 1, 2),
    ("sleepy", 2, 0),
    ("dizzy", 2, 1),
    ("delighted", 2, 2),
]

BASE_URL = "https://koboyo.com/page-mascot/mascots"
OUT_BASE = "assets/mascots"

HEADERS = {
    "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Referer": "https://koboyo.com/page-mascot"
}

def download_file(url, target_path):
    req = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(req) as resp, open(target_path, "wb") as f:
        f.write(resp.read())

os.makedirs(OUT_BASE, exist_ok=True)

for animal in ANIMALS:
    animal_dir = os.path.join(OUT_BASE, animal)
    os.makedirs(animal_dir, exist_ok=True)
    
    dir_url = f"{BASE_URL}/{animal}-directions.webp"
    react_url = f"{BASE_URL}/{animal}-reactions.webp"
    
    dir_path = os.path.join(animal_dir, "directions.webp")
    react_path = os.path.join(animal_dir, "reactions.webp")
    
    print(f"[{animal}] Downloading directions & reactions...")
    download_file(dir_url, dir_path)
    download_file(react_url, react_path)
    
    # Slice 9 emotions (3x3 grid, each 360x360 -> resized to 64x64)
    sheet = Image.open(react_path)
    cell_w = sheet.width // 3
    cell_h = sheet.height // 3
    
    for emotion_name, row, col in EMOTIONS:
        emotion_file = os.path.join(animal_dir, f"{emotion_name}.webp")
        # Keep existing custom fox/koala crops if present, or generate if not
        if animal in ["fox", "koala"] and os.path.exists(emotion_file):
            continue
            
        box = (col * cell_w, row * cell_h, (col + 1) * cell_w, (row + 1) * cell_h)
        cell = sheet.crop(box).resize((64, 64), Image.Resampling.LANCZOS)
        cell.save(emotion_file, "WEBP", quality=90)
        
    print(f"[{animal}] Finished successfully.")

print("All 21 mascots processed!")
