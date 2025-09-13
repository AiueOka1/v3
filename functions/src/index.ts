import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();

function haversine(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371000; // meters
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  return 2 * R * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

// Trigger on dog location updates
export const onDogLocationUpdate = functions.firestore
  .document('dogs/{dogId}')
  .onUpdate(async (change, context) => {
    const dogId = context.params.dogId as string;
    const before = change.before.data();
    const after = change.after.data();
    if (!after) return;

    const afterLoc = after.lastKnownLocation;
    const beforeLoc = before?.lastKnownLocation;
    if (!afterLoc?.latitude || !afterLoc?.longitude) return;

    // Skip if location didn't change
    if (
      beforeLoc &&
      afterLoc.latitude === beforeLoc.latitude &&
      afterLoc.longitude === beforeLoc.longitude
    ) {
      return;
    }

    // Load geofence for this dog: geofences/{dogId}
    const gfSnap = await db.collection('geofences').doc(dogId).get();
    if (!gfSnap.exists) return;
    const gf = gfSnap.data() as {
      latitude: number;
      longitude: number;
      radius: number; // meters
      isActive?: boolean;
      name?: string;
      lastAlertAt?: admin.firestore.Timestamp;
    };

    if (gf?.isActive === false) return;

    const distance = haversine(
      gf.latitude,
      gf.longitude,
      afterLoc.latitude,
      afterLoc.longitude
    );

    const breached = distance > gf.radius;
    if (!breached) return;

    // Cooldown: 5 minutes between alerts
    const now = admin.firestore.Timestamp.now();
    const last = gf.lastAlertAt;
    if (last && now.toMillis() - last.toMillis() < 5 * 60 * 1000) {
      return;
    }

    const handlerId = after.handlerId as string | undefined;
    if (!handlerId) return;

    const userSnap = await db.collection('users').doc(handlerId).get();
    const token = userSnap.get('fcmToken') as string | undefined;
    if (!token) return;

    const dogName = after.name || 'Dog';
    const geofenceName = gf.name || 'Safe Area';

    await admin.messaging().send({
      token,
      notification: {
        title: 'Geofence Breach',
        body: `${dogName} left ${geofenceName}.`,
      },
      data: {
        type: 'geofence_breach',
        dogId,
      },
      android: {
        priority: 'high',
        notification: { channelId: 'fcm_channel' }
      }
    });

    // Store alert in Firestore for persistence with handlerId
    const alertId = `geofence_${dogId}_${Date.now()}`;
    await db.collection('alerts').doc(alertId).set({
      id: alertId,
      dogId: dogId,
      dogName: dogName,
      type: 'geofence_breach',
      message: `${dogName} has left the ${geofenceName} safe zone!`,
      location: {
        latitude: afterLoc.latitude,
        longitude: afterLoc.longitude,
        timestamp: now.toDate().toISOString(),
      },
      timestamp: now.toDate().toISOString(),
      isRead: false,
      handlerId: handlerId, // Associate alert with the handler
    });

    // Update cooldown timestamp
    await gfSnap.ref.update({ lastAlertAt: now });
  });