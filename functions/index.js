const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

const db = getFirestore();

exports.sendNotification = onDocumentCreated(
  "users/{userId}/notifications/{notificationId}",
  async (event) => {
    const snapshot = event.data;

    if (!snapshot) {
      console.log("Notification document is missing.");
      return;
    }

    const notification = snapshot.data() || {};
    const userId = event.params.userId;

    const userSnapshot = await db.collection("users").doc(userId).get();

    if (!userSnapshot.exists) {
      console.log(`User document not found: ${userId}`);
      return;
    }

    const userData = userSnapshot.data() || {};
    const fcmToken = userData.fcmToken;

    if (typeof fcmToken !== "string" || !fcmToken.trim()) {
      console.log(`No valid FCM token found for user: ${userId}`);
      return;
    }

    const title =
      typeof notification.title === "string" && notification.title.trim()
        ? notification.title.trim()
        : "AgriAI";

    const message =
      typeof notification.message === "string" && notification.message.trim()
        ? notification.message.trim()
        : "You have a new notification.";

    const data = {
      notificationId: String(notification.id || snapshot.id),
      type: String(notification.type || ""),
      priority: String(notification.priority || "medium"),
      actionRoute: String(notification.actionRoute || ""),
      senderUid: String(notification.senderUid || ""),
      senderName: String(notification.senderName || ""),
      senderPhotoUrl: String(notification.senderPhotoUrl || ""),
      postId: String(notification.postId || ""),
      conversationId: String(notification.conversationId || ""),
      connectionRequestId: String(notification.connectionRequestId || ""),
      newsId: String(notification.newsId || ""),
      newsUrl: String(notification.newsUrl || ""),
      newsSource: String(notification.newsSource || ""),
    };

    const payload = {
      token: fcmToken.trim(),
      notification: {
        title,
        body: message,
      },
      data,
      android: {
        priority: "high",
        notification: {
          channelId: "agriai_notifications",
          sound: "default",
        },
      },
    };

    try {
      const response = await getMessaging().send(payload);
      console.log(
        `FCM notification sent successfully to ${userId}: ${response}`,
      );
    } catch (error) {
      console.error(
        `FCM notification failed for ${userId}:`,
        error,
      );
    }
  },
);
