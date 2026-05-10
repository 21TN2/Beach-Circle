const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();

//type this to run: firebase deploy --only functions

// tell all the subscribed users
async function notifySubscribedUsers(prefField, title, body) {
  const usersSnap = await db
    .collection("users")
    .where(prefField, "==", true)
    .where("notif_enabled", "==", true)
    .get();

  const tokens = usersSnap.docs
    .map((doc) => doc.data().fcmToken)
    .filter(Boolean); // remove nulls

  if (tokens.length === 0) return;

  // FCM allows max 500 tokens per multicast
  const chunks = [];
  for (let i = 0; i < tokens.length; i += 500) {
    chunks.push(tokens.slice(i, i + 500));
  }

  for (const chunk of chunks) {
    await getMessaging().sendEachForMulticast({
      tokens: chunk,
      notification: { title, body },
      android: { priority: "high" },
      apns: { payload: { aps: { sound: "default" } } },
    });
  }
}

// Food Alert trigger
exports.onNewFoodAlert = onDocumentCreated("food_alerts/{docId}", async (event) => {
  const data = event.data?.data();
  if (!data) return;

  const title = `🍕 Food Alert: ${data.title ?? "Free food nearby!"}`;
  const body = data.description ?? "Check the map for details.";

  await notifySubscribedUsers("notif_foodAlerts", title, body);
});

// // Event board trigger
// exports.onNewEventPost = onDocumentCreated("events/{docId}", async (event) => {
//   const data = event.data?.data();
//   if (!data) return;

//   const title = `📅 New Event: ${data.title ?? "Something's happening!"}`;
//   const body = data.description ?? "Tap to see the details.";

//   await notifySubscribedUsers("notif_eventReminders", title, body);
// });

// // Dorm event trigger
// exports.onNewDormEvent = onDocumentCreated("dorm_events/{docId}", async (event) => {
//   const data = event.data?.data();
//   if (!data) return;

//   const title = `🏠 Dorm Event: ${data.title ?? "Event in your dorm!"}`;
//   const body = data.description ?? "Check the events board.";

//   await notifySubscribedUsers("notif_dormEvents", title, body);
// });