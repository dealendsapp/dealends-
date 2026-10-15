
/**
 * DealEnds Flipkart Affiliate API Adapter
 * Preview mode by default. Firestore writes require --write.
 * Requires Node.js 18+
 *
 * Environment variables:
 * FLIPKART_AFFILIATE_ID
 * FLIPKART_AFFILIATE_TOKEN
 * FLIPKART_TRACKING_ID
 * GOOGLE_APPLICATION_CREDENTIALS (only for --write)
 */

'use strict';

const fs = require('node:fs');
const path = require('node:path');

const ID = process.env.FLIPKART_AFFILIATE_ID;
const TOKEN = process.env.FLIPKART_AFFILIATE_TOKEN;
const TRACKING_ID = process.env.FLIPKART_TRACKING_ID || ID;
const WRITE = process.argv.includes('--write');
const CATEGORY = process.env.FLIPKART_CATEGORY || 'all';
const OUT = path.resolve(
  process.env.FLIPKART_OUTPUT || 'flipkart-preview.json'
);

function needCredentials() {
  if (!ID || !TOKEN || !TRACKING_ID) {
    throw new Error(
      'Set FLIPKART_AFFILIATE_ID, FLIPKART_AFFILIATE_TOKEN, and FLIPKART_TRACKING_ID.'
    );
  }
}

function firstImage(value) {
  if (typeof value === 'string') return value;
  if (!Array.isArray(value)) return '';

  const best =
    value.find(x => x?.resolutionType === 'default' ||
                    x?.resolutionType === 'high') ||
    value.find(Boolean);

  return typeof best === 'string'
    ? best
    : best?.url || best?.value || '';
}

function priceNumber(value) {
  if (value == null) return null;

  if (typeof value === 'object') {
    value = value.amount ?? value.value;
  }

  const n = typeof value === 'number'
    ? value
    : Number(String(value).replace(/[^\d.]/g, ''));

  return Number.isFinite(n) && n > 0 ? n : null;
}

function extractRows(payload) {
  if (Array.isArray(payload?.productInfoList)) {
    return payload.productInfoList
      .map(x => x?.productBaseInfo || x)
      .filter(Boolean);
  }

  if (Array.isArray(payload?.products)) return payload.products;
  if (Array.isArray(payload)) return payload;

  return [];
}

function mapProduct(p) {
  const id = String(p.productId || p.id || '').trim();
  const name = String(
    p.title || p.productName || p.name || ''
  ).trim();

  const productUrl = String(
    p.productUrl || p.product_url || ''
  ).trim();

  const imageUrl = firstImage(
    p.imageUrls || p.imageUrl || p.image_url
  );

  const price = priceNumber(
    p.flipkartSpecialPrice ??
    p.flipkartSellingPrice ??
    p.sellingPrice ??
    p.price
  );

  const mrp = priceNumber(
    p.maximumRetailPrice ?? p.mrp
  );

  if (
    !id ||
    !name ||
    !/^https:\/\//i.test(productUrl) ||
    !/^https:\/\//i.test(imageUrl)
  ) {
    return null;
  }

  const discount =
    mrp && price && mrp > price
      ? Math.round(((mrp - price) / mrp) * 100)
      : null;

  const category = Array.isArray(p.categoryPaths)
    ? p.categoryPaths
        .map(c => typeof c === 'string' ? c : c?.title)
        .filter(Boolean)
        .join(' > ')
    : String(p.category || 'Other');

  return {
    id: `flipkart_${id.replace(/[^a-zA-Z0-9_-]/g, '_')}`,
    sourceProductId: id,
    name,
    store: 'Flipkart',
    category,
    productUrl,
    dealUrl: productUrl,
    imageUrl,
    price,
    originalPrice: mrp,
    discountPercent: discount,
    inStock: p.inStock !== false && p.isAvailable !== false,

    // Feed-supplied data; review the preview before importing.
    productVerified: true,
    imageVerified: true,
    priceVerified: price !== null,

    source: 'flipkart-affiliate-api',
    lastSyncedAt: new Date().toISOString()
  };
}

async function main() {
  needCredentials();

  const url =
    `https://affiliate-api.flipkart.net/affiliate/1.0/feeds/` +
    `${encodeURIComponent(TRACKING_ID)}/category/` +
    `${encodeURIComponent(CATEGORY)}.json`;

  console.log(`Fetching Flipkart category: ${CATEGORY}`);

  const response = await fetch(url, {
    headers: {
      'Fk-Affiliate-Id': ID,
      'Fk-Affiliate-Token': TOKEN,
      'Accept': 'application/json'
    }
  });

  if (!response.ok) {
    const body = (await response.text()).slice(0, 600);
    throw new Error(
      `Flipkart API HTTP ${response.status}: ${body}`
    );
  }

  const payload = await response.json();
  const raw = extractRows(payload);
  const products = raw.map(mapProduct).filter(Boolean);

  fs.writeFileSync(
    OUT,
    JSON.stringify({
      fetchedAt: new Date().toISOString(),
      source: 'Flipkart Affiliate API',
      category: CATEGORY,
      count: products.length,
      skipped: raw.length - products.length,
      products
    }, null, 2)
  );

  console.log(`Feed rows: ${raw.length}`);
  console.log(`Valid products: ${products.length}`);
  console.log(`Skipped: ${raw.length - products.length}`);
  console.log(`Preview saved to: ${OUT}`);

  // Safe default: preview only.
  if (!WRITE) {
    console.log(
      'Preview only. Review the JSON before using --write.'
    );
    return;
  }

  if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    throw new Error(
      'Set GOOGLE_APPLICATION_CREDENTIALS before --write.'
    );
  }

  const admin = require('firebase-admin');
  const serviceAccount = require(
    path.resolve(process.env.GOOGLE_APPLICATION_CREDENTIALS)
  );

  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
  }

  const db = admin.firestore();
  let batch = db.batch();
  let operations = 0;
  let written = 0;

  for (const product of products) {
    const ref = db.collection('products').doc(product.id);

    batch.set(ref, product, { merge: true });
    operations++;
    written++;

    if (operations >= 400) {
      await batch.commit();
      batch = db.batch();
      operations = 0;
    }
  }

  if (operations > 0) {
    await batch.commit();
  }

  console.log(
    `Merged ${written} products into Firestore products collection.`
  );
}

main().catch(error => {
  console.error(`Import failed: ${error.message}`);
  process.exit(1);
});
