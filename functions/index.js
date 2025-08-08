/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

/* const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");
const logger = require("firebase-functions/logger"); */

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.


//setGlobalOptions({ maxInstances: 10 });

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendDriverNotification = functions.firestore
    .document("driver_requests/{requestId}")
    .onCreate(async (snapshot, context) => {
        const requestData = snapshot.data();
        const driverId = requestData.to; // This is the 'to' field in your DB

        if (!driverId) {
            console.log("No driverId found in request");
            return null;
        }

        // Fetch driver document from users collection
        const driverDoc = await admin.firestore()
            .collection("users")
            .doc(driverId)
            .get();

        if (!driverDoc.exists) {
            console.log(`Driver with ID ${driverId} not found`);
            return null;
        }

        const driverData = driverDoc.data();

        // Ensure this is actually a driver
        if (driverData.role !== "Driver") {
            console.log(`User ${driverId} is not a driver`);
            return null;
        }

        // Get the FCM token (you’ll need to store it in this user document)
        const fcmToken = driverData.fcmToken;
        if (!fcmToken) {
            console.log(`No FCM token for driver ${driverId}`);
            return null;
        }

        // Notification payload
        const payload = {
            notification: {
                title: "🚚 New Transport Request",
                body: `Pickup: ${requestData.pickup} → Drop: ${requestData.drop}`,
            },
            token: fcmToken,
        };

        try {
            const response = await admin.messaging().send(payload);
            console.log("Notification sent:", response);
        } catch (error) {
            console.error("Error sending notification:", error);
        }

        return null;
    });
