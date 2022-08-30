const express = require("express");
const api = express();
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { body } = require("express-validator");
const cors = require("cors");
const { validationResult } = require("express-validator");

/* ------------- API SETUP ------------- */
// Setup middlewares
api.use(express.json({ limit: "1200kb" }));
api.use(
  express.urlencoded({
    extended: true,
  })
);
api.use(cors());
/* ------------- API SETUP (END) ------------- */

/* ------------- EXPRESS API APP ------------- */

api.get("/", (req, res) => {
  // admin
  //   .auth()
  //   .updateUser("Agkq18lB7vb6LV9rENxCy0V9EzA3", { emailVerified: true });
  // admin
  //   .auth()
  //   .generateEmailVerificationLink("hadouken6@gmail.com")
  //   .then((verificationLink) => {
  //     return res.send(verificationLink);
  //   })
  //   .catch((e) => {});
  // admin.auth().setCustomUserClaims("fSJA0ll4mCRMbzBON4f6jfrtipJ3", {
  //   userName: "baalish",
  // });
  // admin.auth().updateUser("VdAAKH1oYeUncT01yO6wn3gkEbF2", {
  //   emailVerified: true,
  // });
  return res.send("Good day to you! from baalish.com");
});

// FROM HERE ALL REQUESTS REQUIRE HAVING A FIREBASE JWT IDTOKEN

api.use((req, res, next) => {
  if (!req.headers.authorization) {
    return res.status(403).json({ message: "Missing authorization header" });
  }

  let jwt = req.headers.authorization.trim();
  return (
    admin
      .auth()
      .verifyIdToken(jwt)
      .then((claims) => {
        req.user = claims; // Sets the user object to use in app.post
        next();
        return true;
      })
      // eslint-disable-next-line handle-callback-err
      .catch((err) => {
        res.status(400).json({
          message: "Invalid JWT",
        });
        throw err;
      })
  );
});

api.post(
  "/signup",
  [
    body("userName")
      .not()
      .isEmpty()
      .isString()
      .trim()
      .isLength({ min: 6, max: 32 })
      .withMessage("Username must be between 6 - 32 characters")
      .custom(
        (field) =>
          field !== "signup" &&
          field !== "login" &&
          field !== "404" &&
          field !== "create-post" &&
          field !== "edit-profile" &&
          field !== "forgot-password"
      )
      .withMessage("Username is invalid")
      .matches(/^[a-zA-Z0-9_.]+$/)
      .withMessage(
        "Username invalid. Username must be Alpha-Numeric, underscores and dots"
      ),
    body("displayName")
      .not()
      .isEmpty()
      .isString()
      .trim()
      .isLength({ min: 3, max: 32 })
      .withMessage("Full name must be between 3 - 32 characters")
      .matches(/^[a-zA-Z ]+$/)
      .withMessage("Full name invalid. Must be alhabets only"),
  ],
  async (req, res) => {
    const user = req.user;
    const userName = req.body.userName.trim();
    const displayName = req.body.displayName;

    // Express validator
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      // Delete user as encountered an error
      await deleteTheUser(user.uid);
      return res.status(400).json({ code: 400, message: errors[0] });
    }

    // Update the displayName of the user
    await admin.auth().updateUser(user.uid, {
      displayName: displayName,
    });

    await admin
      .firestore()
      .runTransaction((transaction) => {
        return (
          // Search for userName if it already exists or not
          transaction
            .get(
              admin
                .firestore()
                .collection("takenUserNames")
                .doc(userName.toLowerCase())
            )
            .then((document) => {
              // Check if username already exits
              if (document.exists) {
                // eslint-disable-next-line prefer-promise-reject-errors
                return Promise.reject({
                  code: 400,
                  message: "Username already exists!",
                });
              }
              // If the document doesn't exist, proceed
              return Promise.resolve();
            })
            // Set the userName into custom claims
            .then(() =>
              admin.auth().setCustomUserClaims(user.uid, { userName: userName })
            )
            // Create a takenUserNames record to avoid double userNames
            .then(() =>
              transaction.set(
                admin
                  .firestore()
                  .collection("takenUserNames")
                  .doc(userName.toLowerCase()),
                {
                  userUid: user.uid,
                  userName: userName,
                }
              )
            )
            // Finally create the user in the firestore
            .then(() =>
              transaction.set(
                admin.firestore().collection("users").doc(user.uid),
                {
                  userName: userName,
                  userNameLowerCase: userName.toLowerCase(),
                  displayName: displayName,
                  photoURL: "",
                  userBio: "",
                  meta: {
                    seenWelcomeMessage: false,
                    // Time is stored in seconds.
                    userNameLastUpdated: Math.floor(Date.now() / 1000),
                    profilePictureLastUpdated: Math.floor(Date.now() / 1000),
                    displayNameLastUpdated: Math.floor(Date.now() / 1000),
                    contactsCount: 0,
                  },
                }
              )
            )
        );
      })
      .then(() => {
        return res.status(200).json({
          code: 200,
          message: "Successfully created user!",
        });
      })
      .catch(async (error) => {
        console.error(error);
        return res.status(error.code || 500).json(error);
      });
    return Promise.resolve();
  }
);

// Use Express middleware to intercept all requests
exports.api = functions.https.onRequest(api);
