import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

const db = admin.firestore();

// 1. Chat Message Trigger
// Updates lastMessageAt in the chat document and sends push notification
export const onChatMessageCreate = functions.firestore
    .document("chats/{chatId}/messages/{messageId}")
    .onCreate(async (snap, context) => {
        const chatId = context.params.chatId;
        const messageData = snap.data();
        const senderId = messageData.senderId;
        const text = messageData.text;

        // A. Update Chat Metadata
        const chatRef = db.collection("chats").doc(chatId);
        await chatRef.update({
            lastMessage: text,
            lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // B. Send Notification
        const chatDoc = await chatRef.get();
        if (!chatDoc.exists) return; // Should not happen

        const participants: string[] = chatDoc.data()?.participants || [];
        const recipientId = participants.find((uid) => uid !== senderId);

        if (!recipientId) return;

        // Get recipient FCM token (assuming stored in /users/{uid}/tokens or similar)
        // For MVP we assume we might send to a topic or verify user doc has fcmToken
        const recipientDoc = await db.collection("users").doc(recipientId).get();
        const fcmToken = recipientDoc.data()?.fcmToken;

        if (fcmToken) {
            const payload: admin.messaging.MessagingPayload = {
                notification: {
                    title: "New Message",
                    body: text.length > 50 ? text.substring(0, 50) + "..." : text,
                    clickAction: "FLUTTER_NOTIFICATION_CLICK",
                },
                data: {
                    chatId: chatId,
                    type: "chat_message",
                },
            };
            await admin.messaging().sendToDevice(fcmToken, payload);
        }
    });

// 2. Rate Limit Helper (Callable)
// Example: Check if user can send message. 
// Ideally enforced via Firestore Rules or on write trigger, but here is a Callable for check
export const checkRateLimit = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be logged in");
    }

    const uid = context.auth.uid;
    // Simple leaky bucket or counter in "rateLimits/{uid}"
    const limitRef = db.collection("rateLimits").doc(uid);
    const now = admin.firestore.Timestamp.now();

    // Transaction to update count
    await db.runTransaction(async (t) => {
        const doc = await t.get(limitRef);
        if (!doc.exists) {
            t.set(limitRef, { count: 1, lastReset: now });
            return;
        }

        const d = doc.data()!;
        const lastReset = d.lastReset.toDate();
        const diffSeconds = (now.toDate().getTime() - lastReset.getTime()) / 1000;

        if (diffSeconds > 60) {
            // Reset window
            t.update(limitRef, { count: 1, lastReset: now });
        } else {
            if (d.count >= 20) { // Max 20 msg/min
                throw new functions.https.HttpsError("resource-exhausted", "Rate limit exceeded");
            }
            t.update(limitRef, { count: d.count + 1 });
        }
    });

    return { allowed: true };
});

// 3. Trending Events (Scheduled)
// Recalculates trending score based on recent RSVPs
export const recomputeTrendingEvents = functions.pubsub
    .schedule("every 60 minutes")
    .onRun(async (context) => {
        const eventsSnapshot = await db.collection("events").get();

        const batch = db.batch();

        for (const doc of eventsSnapshot.docs) {
            // Simple heuristic: count recent RSVPs or total RSVPs
            // In prod: use aggregation queries or subcollection count
            const rsvps = await doc.ref.collection("rsvps").where("status", "==", "going").count().get();
            const count = rsvps.data().count;

            // Score = count * 10 + recency_factor (omitted for brevity)
            batch.update(doc.ref, { trendingScore: count });
        }

        await batch.commit();
        console.log("Trending scores updated");
    });
