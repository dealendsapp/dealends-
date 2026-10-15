const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {initializeApp} = require("firebase-admin/app");

initializeApp();

setGlobalOptions({
  maxInstances: 10,
});

const db = getFirestore();

exports.syncProduct = onRequest(
    {
      cors: true,
    },
    async (req, res) => {
      if (req.method !== "POST") {
        return res.status(405).json({
          success: false,
          error: "POST request required",
        });
      }

      try {
        const product = req.body;

        if (!product || !product.productId || !product.name) {
          return res.status(400).json({
            success: false,
            error: "productId and name are required",
          });
        }

        const productData = {
          productId: String(product.productId),
          name: String(product.name),
          brand: product.brand ? String(product.brand) : "",
          description: product.description ?
            String(product.description) : "",
          store: product.store ? String(product.store) : "Unknown",
          category: product.category ?
            String(product.category) : "Other",
          imageUrl: product.imageUrl ?
            String(product.imageUrl) : "",
          productUrl: product.productUrl ?
            String(product.productUrl) : "",
          affiliateUrl: product.affiliateUrl ?
            String(product.affiliateUrl) : "",
          price: Number(product.price || 0),
          originalPrice: Number(product.originalPrice || 0),
          discountPercent: Number(product.discountPercent || 0),
          rating: Number(product.rating || 0),
          reviewCount: Number(product.reviewCount || 0),
          inStock: product.inStock !== false,
          isDeal: product.isDeal !== false,
          dealScore: Number(product.dealScore || 0),
          updatedAt: FieldValue.serverTimestamp(),
        };

        await db
            .collection("products")
            .doc(productData.productId)
            .set(productData, {merge: true});

        return res.status(200).json({
          success: true,
          productId: productData.productId,
          message: "Product synced successfully",
        });
      } catch (error) {
        console.error("Product sync failed:", error);

        return res.status(500).json({
          success: false,
          error: "Product sync failed",
        });
      }
    },
);

const { onCall, HttpsError } = require("firebase-functions/https");
const { getMessaging } = require("firebase-admin/messaging");

exports.sendMyTestNotification = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Please sign in to DealEnds first."
    );
  }

  const uid = request.auth.uid;
  const userDoc = await db.collection("users").doc(uid).get();
  const token = userDoc.data()?.fcmToken;

  if (!token) {
    throw new HttpsError(
      "failed-precondition",
      "No FCM token found. Sign in again and allow notifications."
    );
  }

  try {
    const messageId = await getMessaging().send({
      token,
      notification: {
        title: "DealEnds",
        body: "Your test notification is working!"
      },
      data: { type: "test" }
    });

    return { success: true, messageId };
  } catch (error) {
    console.error("Push notification failed:", error);
    throw new HttpsError(
      "internal",
      "Could not send the test notification."
    );
  }
});
