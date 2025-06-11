const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

// Initialize Firebase Admin SDK
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Cloud Function to send push notifications when push notification triggers are created
 */
exports.sendPushNotification = onDocumentCreated(
  "pushNotificationTriggers/{triggerId}",
  async (event) => {
    const snap = event.data;
    const triggerData = snap.data();
    const { storeId, type, title, body, data } = triggerData;
    try {
      console.log(`Processing notification trigger for store ID: ${storeId}`);

      // Get all FCM tokens for the store owner
      const userQuery = await db
        .collection("users")
        .where("storeId", "==", storeId)
        .limit(1)
        .get();

      console.log(`Found ${userQuery.size} users for store ID: ${storeId}`);

      if (userQuery.empty) {
        console.log(`No user found for store ID: ${storeId}`);
        return;
      }
      const userDoc = userQuery.docs[0];
      const userData = userDoc.data();

      console.log(`User document ID: ${userDoc.id}`);

      // Extract FCM tokens from fcmTokens object
      const fcmTokens = userData.fcmTokens || {};
      const tokens = [];

      console.log(`FCM tokens object:`, fcmTokens);
      console.log(`FCM tokens keys:`, Object.keys(fcmTokens));

      // Extract all valid tokens
      Object.entries(fcmTokens).forEach(([deviceId, tokenInfo]) => {
        if (tokenInfo && tokenInfo.token) {
          tokens.push(tokenInfo.token);
          console.log(
            `Added token from ${deviceId}: ${tokenInfo.token.substring(
              0,
              20
            )}...`
          );
        }
      });

      console.log(`Total valid tokens extracted: ${tokens.length}`);

      if (tokens.length === 0) {
        console.log(`No valid FCM tokens found for store ID: ${storeId}`);
        return;
      } // Create the notification payload
      const payload = {
        notification: {
          title: title,
          body: body,
        },
        data: {
          ...data,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        tokens: tokens,
      }; // Send notification to all tokens
      const response = await messaging.sendEachForMulticast(payload);

      console.log("Push notification sent successfully:");
      console.log(`Success count: ${response.successCount}`);
      console.log(`Failure count: ${response.failureCount}`);

      // Log each response
      response.responses.forEach((result, index) => {
        if (result.success) {
          console.log(`✅ Token ${index + 1}: Success`);
        } else {
          console.log(
            `❌ Token ${index + 1}: Error - ${result.error?.code}: ${
              result.error?.message
            }`
          );
        }
      });

      // Clean up invalid tokens
      const invalidTokens = [];
      response.responses.forEach((result, index) => {
        if (result.error) {
          console.error(
            `Error sending to token ${tokens[index]}:`,
            result.error
          );
          if (
            result.error.code === "messaging/invalid-registration-token" ||
            result.error.code === "messaging/registration-token-not-registered"
          ) {
            invalidTokens.push(tokens[index]);
          }
        }
      }); // Remove invalid tokens from user document
      if (invalidTokens.length > 0) {
        const updates = {};
        Object.entries(fcmTokens).forEach(([deviceId, tokenInfo]) => {
          if (invalidTokens.includes(tokenInfo.token)) {
            updates[`fcmTokens.${deviceId}`] =
              admin.firestore.FieldValue.delete();
          }
        });

        if (Object.keys(updates).length > 0) {
          await userDoc.ref.update(updates);
          console.log(`Removed ${invalidTokens.length} invalid tokens`);
        }
      }

      // Delete the trigger document after processing
      await snap.ref.delete();
    } catch (error) {
      console.error("Error sending push notification:", error);
      throw error;
    }
  }
);

/**
 * Cloud Function to handle order status updates and send notifications
 */
exports.onOrderStatusUpdate = onDocumentUpdated(
  "orders/{orderId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    const orderId = event.params.orderId;

    // Check if status has changed
    if (before.status === after.status) {
      return;
    }

    const newStatus = after.status;
    const sellerRef = after.sellerRef;
    try {
      // Get seller information
      const sellerDoc = await sellerRef.get();
      if (!sellerDoc.exists) {
        console.log(`Seller not found for order: ${orderId}`);
        return;
      }

      const sellerData = sellerDoc.data();
      const storeId = sellerData.storeId;

      if (!storeId) {
        console.log(`Store ID not found for seller: ${sellerRef.id}`);
        return;
      }

      // Create notification trigger for the seller
      await db.collection("pushNotificationTriggers").add({
        storeId: storeId,
        type: "order_status_update",
        title: "Order Status Updated",
        body: `Order #${orderId
          .substring(0, 8)
          .toUpperCase()} is now ${newStatus}`,
        data: {
          type: "order_status_update",
          orderId: orderId,
          newStatus: newStatus,
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(
        `Order status update notification triggered for order: ${orderId}`
      );
    } catch (error) {
      console.error("Error handling order status update:", error);
    }
  }
);

/**
 * Cloud Function to send welcome notifications to new store owners
 */
exports.onNewStoreCreation = onDocumentCreated(
  "stores/{storeId}",
  async (event) => {
    const snap = event.data;
    const storeData = snap.data();
    const storeId = event.params.storeId;
    const ownerRef = storeData.ownerRef;
    try {
      // Get owner information
      const ownerDoc = await ownerRef.get();
      if (!ownerDoc.exists) {
        console.log(`Owner not found for store: ${storeId}`);
        return;
      }

      const ownerData = ownerDoc.data();
      const ownerName = ownerData.fullName || "Store Owner";

      // Create welcome notification trigger
      await db.collection("pushNotificationTriggers").add({
        storeId: storeId,
        type: "welcome",
        title: "Welcome to Pertukekem!",
        body: `Hello ${ownerName}! Your store is now ready to receive orders.`,
        data: {
          type: "welcome",
          storeId: storeId,
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Welcome notification sent to new store: ${storeId}`);
    } catch (error) {
      console.error("Error sending welcome notification:", error);
    }
  }
);
