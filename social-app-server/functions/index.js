const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Use service account for development
const serviceAccount = require("./serviceAccountKey.json");
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://jynx-chat-default-rtdb.firebaseio.com",
});

// Exporting ---------------

exports.api = require("./modules/api").api;
exports.onUserUpdated = require("./modules/triggers").onUserUpdated;
exports.UserChatsInfoUpdateCron =
  require("./modules/triggers").UserChatsInfoUpdateCron;
exports.onChatRoomsInfosCreated =
  require("./modules/triggers").onChatRoomsInfosCreated;
exports.onMessageAdded = require("./modules/triggers").onMessageAdded;
exports.onCallIncoming = require("./modules/triggers").onCallIncoming;
