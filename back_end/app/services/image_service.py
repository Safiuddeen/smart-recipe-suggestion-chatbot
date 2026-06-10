import requests
from bs4 import BeautifulSoup


def extract_image_from_page(page_url: str):
    if not page_url:
        return None

    try:
        headers = {
            "User-Agent": "Mozilla/5.0"
        }

        response = requests.get(page_url, headers=headers, timeout=10)

        if response.status_code != 200:
            return None

        soup = BeautifulSoup(response.text, "html.parser")

        # 1️⃣ Open Graph image (BEST QUALITY usually)
        og_image = soup.find("meta", property="og:image")
        if og_image and og_image.get("content"):
            return og_image["content"]

        # 2️⃣ Try srcset (HIGH RES images)
        img_tag = soup.find("img", srcset=True)
        if img_tag:
            srcset = img_tag["srcset"].split(",")
            highest = srcset[-1].strip().split(" ")[0]
            return highest

        # 3️⃣ fallback first image
        img_tag = soup.find("img")
        if img_tag and img_tag.get("src"):
            return img_tag["src"]

    except Exception as e:
        print("Image extraction error:", e)

    return None