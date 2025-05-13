/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import moment from "moment-timezone";

admin.initializeApp();

exports.sendMedicationReminder = functions.pubsub
  .schedule("every 1 minutes")
  .timeZone("Africa/Casablanca")
  .onRun(async () => {
    console.log("🔔 Vérification des rappels de médicaments...");

    const medicationsSnapshot = await admin.firestore().collection("medications").get();
    const now = moment().tz("Africa/Casablanca");

    medicationsSnapshot.forEach(async (doc) => {
      const medication = doc.data();
      if (!medication || !medication.time || !medication.userId) return;

      let medicationMoment: moment.Moment;

      if (medication.time instanceof admin.firestore.Timestamp) {
        medicationMoment = moment(medication.time.toDate()).tz("Africa/Casablanca");
      } else {
        medicationMoment = moment(medication.time, "D MMMM YYYY à HH:mm:ss [UTC]Z").tz("Africa/Casablanca");
      }

      const nowFormatted = now.format("HH:mm");
      const medTimeFormatted = medicationMoment.format("HH:mm");

      const isSameDay = now.format("YYYY-MM-DD") === medicationMoment.format("YYYY-MM-DD");
      const isDaily = medication.interval === "Chaque jour";

      // 🔁 Notification si "Chaque jour" et l'heure correspond
      // ✅ Notification aussi le jour exact si pas récurrent
      if ((isDaily && medTimeFormatted === nowFormatted) || (!isDaily && isSameDay && medTimeFormatted === nowFormatted)) {
        console.log(`📩 Envoi de la notification pour ${medication.name}`);

        const userDoc = await admin.firestore().collection("users").doc(medication.userId).get();
        const userToken = userDoc.data()?.fcmToken;

        if (userToken) {
          await admin.messaging().send({
            token: userToken,
            notification: {
              title: "💊 Rappel de Médicament",
              body: `Il est temps de prendre ${medication.name} - ${medication.dosage}mg`,
            },
          });
          console.log(`✅ Notification envoyée à ${userToken}`);
        } else {
          console.log("⚠️ Aucun token FCM trouvé pour l'utilisateur");
        }
      }
    });

    return null;
  });


// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// export const helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
