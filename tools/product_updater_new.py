
import json
from pathlib import Path

PROJECT_DIR = Path(__file__).resolve().parent.parent
INPUT_FILE = PROJECT_DIR / "tools" / "products_to_update.json"
OUTPUT_FILE = PROJECT_DIR / "tools" / "products_validated.json"


def validate_products(products):
    if not isinstance(products, list):
        raise ValueError("The JSON root must be a list of products.")

    validated = []
    seen_ids = set()

    for index, product in enumerate(products, start=1):
        if not isinstance(product, dict):
            raise ValueError(f"Product {index} must be an object.")

        product_id = str(product.get("productId", "")).strip()
        name = str(product.get("name", "")).strip()

        if not product_id or not name:
            raise ValueError(
                f"Product {index} needs productId and name."
            )

        if product_id in seen_ids:
            raise ValueError(f"Duplicate productId: {product_id}")

        seen_ids.add(product_id)

        price = product.get("price")
        original_price = product.get("originalPrice")

        if (
            isinstance(price, bool)
            or not isinstance(price, (int, float))
            or price <= 0
        ):
            raise ValueError(f"{product_id}: price must be positive.")

        if (
            isinstance(original_price, bool)
            or not isinstance(original_price, (int, float))
            or original_price < price
        ):
            raise ValueError(
                f"{product_id}: originalPrice must be >= price."
            )

        item = dict(product)
        item["productId"] = product_id
        item["name"] = name
        item["price"] = price
        item["originalPrice"] = original_price
        item["discountPercent"] = round(
            (original_price - price) / original_price * 100, 2
        )

        validated.append(item)

    return validated


def main():
    if not INPUT_FILE.exists():
        raise FileNotFoundError(f"Missing input: {INPUT_FILE}")

    products = json.loads(INPUT_FILE.read_text(encoding="utf-8"))
    validated = validate_products(products)

    OUTPUT_FILE.write_text(
        json.dumps(validated, indent=2),
        encoding="utf-8",
    )

    print(f"Validated {len(validated)} product(s).")
    print(f"Output saved to: {OUTPUT_FILE}")
    print("No Firestore changes were made.")
    print("Prices are supplied test data, not live store prices.")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, json.JSONDecodeError) as error:
        raise SystemExit(f"ERROR: {error}")
