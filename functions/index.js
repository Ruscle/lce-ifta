const {onCall, HttpsError} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

function usernameToEmail(username) {
  return `${username.trim().toLowerCase()}@iftatracker.local`;
}

async function requireAdmin(request) {
  logger.info("auth payload", {auth: request.auth});

  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "You must be signed in.",
    );
  }

  const callerUid = request.auth.uid;
  const callerDoc = await admin.firestore().collection("users").doc(callerUid).get();

  if (!callerDoc.exists) {
    throw new HttpsError(
      "permission-denied",
      "Admin profile not found.",
    );
  }

  const callerData = callerDoc.data() || {};

  if (callerData.role !== "admin") {
    throw new HttpsError(
      "permission-denied",
      "Only admins can perform this action.",
    );
  }

  return callerUid;
}

exports.createManagedUser = onCall({region: "us-central1"}, async (request) => {
  await requireAdmin(request);

  const username = (request.data.username || "").trim().toLowerCase();
  const password = request.data.password || "";
  const role = (request.data.role || "user").trim().toLowerCase();

  if (!username || !password) {
    throw new HttpsError(
      "invalid-argument",
      "Username and password are required.",
    );
  }

  if (password.length < 6) {
    throw new HttpsError(
      "invalid-argument",
      "Password must be at least 6 characters.",
    );
  }

  const email = usernameToEmail(username);

  const userRecord = await admin.auth().createUser({
    email,
    password,
  });

  await admin.firestore().collection("users").doc(userRecord.uid).set({
    username,
    role: role === "admin" ? "admin" : "user",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {
    uid: userRecord.uid,
    username,
    role: role === "admin" ? "admin" : "user",
  };
});

exports.resetManagedUserPassword = onCall({region: "us-central1"}, async (request) => {
  await requireAdmin(request);

  const uid = request.data.uid || "";
  const newPassword = request.data.newPassword || "";

  if (!uid || !newPassword) {
    throw new HttpsError(
      "invalid-argument",
      "User id and new password are required.",
    );
  }

  if (newPassword.length < 6) {
    throw new HttpsError(
      "invalid-argument",
      "Password must be at least 6 characters.",
    );
  }

  await admin.auth().updateUser(uid, {
    password: newPassword,
  });

  return {success: true};
});

exports.deleteManagedUser = onCall({region: "us-central1"}, async (request) => {
  await requireAdmin(request);

  const uid = request.data.uid || "";

  if (!uid) {
    throw new HttpsError(
      "invalid-argument",
      "User id is required.",
    );
  }

  await admin.auth().deleteUser(uid);
  await admin.firestore().collection("users").doc(uid).delete();

  return {success: true};
});
