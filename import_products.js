const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const serviceAccount = require('./serviceAccountKey.json');

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

const rawProductsFeed = [
  {
    name: "Example Product 1",
    category: "Electronics",
    price: 999.0,
    originalPrice: 1999.0,
    store: "Amazon",
    rating: 4.5,
    reviewCount: 120,
    imageUrl: "https://example.com/image1.jpg",
    productUrl: "https://www.amazon.in/dp/EXAMPLE1",
    brand: "BrandA",
    description: "Sample real description."
  }
];

async function importProducts() {
  const collectionRef = db.collection('products');

  for (const item of rawProductsFeed) {
    if (!item.name || !item.price || item.price <= 0) {
      console.log(`Skipping invalid product: ${item.name}`);
      continue;
    }

    let finalUrl = item.productUrl || '';
    if (finalUrl.includes('amazon.in') || finalUrl.includes('amazon.com')) {
      if (!finalUrl.includes('tag=')) {
        const separator = finalUrl.includes('?') ? '&' : '?';
        finalUrl = `${finalUrl}${separator}tag=dealendsapp-21`;
      }
    }

    const productPayload = {
      name: item.name,
      category: item.category,
      price: item.price,
      originalPrice: item.originalPrice || item.price,
      store: item.store,
      rating: item.rating || 0.0,
      reviewCount: item.reviewCount || 0,
      imageUrl: item.imageUrl || '',
      affiliateUrl: finalUrl,
      brand: item.brand || '',
      description: item.description || '',
      updatedAt: FieldValue.serverTimestamp()
    };

    await collectionRef.add(productPayload);
    console.log(`Successfully imported: ${item.name}`);
  }

  console.log("All products imported and verified successfully!");
}

importProducts().catch(console.error);