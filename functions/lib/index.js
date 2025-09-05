"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.onDogLocationUpdate = void 0;
const functions = __importStar(require("firebase-functions/v1"));
const admin = __importStar(require("firebase-admin"));
admin.initializeApp();
const db = admin.firestore();
function haversine(lat1, lon1, lat2, lon2) {
    const R = 6371000; // meters
    const toRad = (d) => (d * Math.PI) / 180;
    const dLat = toRad(lat2 - lat1);
    const dLon = toRad(lon2 - lon1);
    const a = Math.sin(dLat / 2) ** 2 +
        Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
    return 2 * R * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}
// Trigger on dog location updates
exports.onDogLocationUpdate = functions.firestore
    .document('dogs/{dogId}')
    .onUpdate(async (change, context) => {
    const dogId = context.params.dogId;
    const before = change.before.data();
    const after = change.after.data();
    if (!after)
        return;
    const afterLoc = after.lastKnownLocation;
    const beforeLoc = before?.lastKnownLocation;
    if (!afterLoc?.latitude || !afterLoc?.longitude)
        return;
    // Skip if location didn't change
    if (beforeLoc &&
        afterLoc.latitude === beforeLoc.latitude &&
        afterLoc.longitude === beforeLoc.longitude) {
        return;
    }
    // Load geofence for this dog: geofences/{dogId}
    const gfSnap = await db.collection('geofences').doc(dogId).get();
    if (!gfSnap.exists)
        return;
    const gf = gfSnap.data();
    if (gf?.isActive === false)
        return;
    const distance = haversine(gf.latitude, gf.longitude, afterLoc.latitude, afterLoc.longitude);
    const breached = distance > gf.radius;
    if (!breached)
        return;
    // Cooldown: 5 minutes between alerts
    const now = admin.firestore.Timestamp.now();
    const last = gf.lastAlertAt;
    if (last && now.toMillis() - last.toMillis() < 5 * 60 * 1000) {
        return;
    }
    const handlerId = after.handlerId;
    if (!handlerId)
        return;
    const userSnap = await db.collection('users').doc(handlerId).get();
    const token = userSnap.get('fcmToken');
    if (!token)
        return;
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
    // Update cooldown timestamp
    await gfSnap.ref.update({ lastAlertAt: now });
});
