
/**
 * DealEnds Product Importer
 *
 * PURPOSE:
 * Fetch products from an authorized product feed and save them
 * to Firebase Firestore's "products" collection.
 *
 * IMPORTANT:
 * This does not find live prices by itself. You need an authorized
 * feed URL and token from a product/affiliate provider.
 *
 * REQUIRED ENVIRONMENT VARIABLES:
 * PRODUCT_FEED_URL
 * PRODUCT_FEED_TOKEN
 *
 * REQUIREMENTS:
 * - Node.js 18 or newer
 * - firebase-admin package installed
 * - Firebase Admin credentials configured securely
 *
 * RUN:
 * npm install firebase-admin
 * node import-products.js
 */

"use strict";

const admin = require("firebase-admin");

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

const ALLOWED_STORE_HOSTS = {
  amazon: ["amazon.in", "www.amazon.in"],
  flipkart: ["flipkart.com", "www.flipkart.com"],
  myntra: ["myntra.com", "www.myntra.com"],
  croma: ["croma.com", "www.croma.com"],
  reliance: ["reliancedigital.in", "www.reliancedigital.in"],
};

function requiredText(value, field) {
  if (typeof value !== "string" || !value.trim()) {
    throw new Error(`${field} is required.`);
  }

  return value.trim();
}

function httpsUrl(value, field) {
  let url;

  try {
    url = new URL(requiredText(value, field));
  } catch {
    throw new Error(`${field} must be a valid HTTPS URL.`);
  }

  if (
    url.protocol !== "https:" ||
    !url.hostname ||
    url.username ||
    url.password
  ) {
    throw new Error(`${field} must be a safe HTTPS URL.`);
  }

  return url;
}

function validateStoreHost(store, url, field) {
  const key = store.toLowerCase().replace(/\s+/g, "");
  const allowed = ALLOWED_STORE_HOSTS[key];

  if (!allowed) {
    throw new Error(
      `Store "${store}" is not configured in ALLOWED_STORE_HOSTS.`
    );
  }

  if (!allowed.includes(url.hostname.toLowerCase())) {
    throw new Error(`${field} uses an unapproved ${store} domain.`);
  }
}

function validateProduct(item) {
  if (!item || typeof item !== "object" || Array.isArray(item)) {
    throw new Error("Product must be an object.");
  }

  const id = requiredText(item.id, "id");

  if (!/^[A-Za-z0-9_-]{1,120}$/.test(id)) {
    throw new Error("id contains invalid characters.");
  }

  const name = requiredText(item.name, "name");
  const store = requiredText(item.store, "store");

  const productUrl = httpsUrl(item.productUrl, "productUrl");
  validateStoreHost(store, productUrl, "productUrl");

  const price = Number(item.price);

  if (!Number.isFinite(price) || price <= 0) {
    throw new Error("price must be greater than zero.");
  }

  const product = {
    name,
    store,
    productUrl: productUrl.toString(),
    price,
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    dataSource: "authorized-feed",
  };

  if (item.originalPrice != null) {
    const originalPrice = Number(item.originalPrice);

    if (
      !Number.isFinite(originalPrice) ||
      originalPrice < price ||
      originalPrice <= 0
    ) {
      throw new Error("originalPrice must be at least price.");
    }

    product.originalPrice = originalPrice;
    product.discountPercent = Math.round(
      ((originalPrice - price) / originalPrice) * 100
    );
  }

  for (const field of ["category", "brand"]) {
    if (item[field] != null) {
      product[field] = requiredText(item[field], field);
    }
  }

  if (item.imageUrl != null) {
    product.imageUrl = httpsUrl(item.imageUrl, "imageUrl").toString();
  }

  if (item.affiliateUrl != null) {
    const affiliateUrl = httpsUrl(item.affiliateUrl, "affiliateUrl");
    validateStoreHost(store, affiliateUrl, "affiliateUrl");
    product.affiliateUrl = affiliateUrl.toString();
  }

  return { id, product };
}

async function importProducts() {
  const feedUrl = process.env.PRODUCT_FEED_URL;
  const feedToken = process.env.PRODUCT_FEED_TOKEN;

  if (!feedUrl || !feedToken) {
    throw new Error(
      "Set PRODUCT_FEED_URL and PRODUCT_FEED_TOKEN before running."
    );
  }

  const url = httpsUrl(feedUrl, "PRODUCT_FEED_URL");

  const response = await fetch(url, {
    headers: {
      Authorization: `Bearer ${feedToken}`,
      Accept: "application/json",
    },
    signal: AbortSignal.timeout(20000),
  });

  if (!response.ok) {
    throw new Error(`Product feed returned HTTP ${response.status}.`);
  }

  const payload = await response.json();

  if (!payload || !Array.isArray(payload.products)) {
    throw new Error('Feed must return a JSON "products" array.');
  }

  let imported = 0;
  const errors = [];
  const batchSize = 400;

  for (let i = 0; i < payload.products.length; i += batchSize) {
    const batch = db.batch();
    let writes = 0;

    for (const item of payload.products.slice(i, i + batchSize)) {
      try {
        const { id, product } = validateProduct(item);

        batch.set(db.collection("products").doc(id), product, {
          merge: true,
        });

        imported++;
        writes++;
      } catch (error) {
        errors.push({
          id: item?.id ?? null,
          message: error.message,
        });
      }
    }

    if (writes > 0) {
      await batch.commit();
    }
  }

  return {
    received: payload.products.length,
    imported,
    rejected: errors.length,
    errors,
  };
}

async function main() {
  try {
    const result = await importProducts();

    console.log("DealEnds import completed:");
    console.log(JSON.stringify(result, null, 2));

    if (result.rejected > 0) {
      process.exitCode = 1;
    }
  } catch (error) {
    console.error("DealEnds import failed:", error.message);
    process.exitCode = 1;
  }
}

if (require.main === module) {
  main();
}

module.exports = { importProducts, validateProduct };
