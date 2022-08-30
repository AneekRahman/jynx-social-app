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
                  location: "",
                  website: "",
                  searchKeywords: [
                    ...createKeywords(userName.toLowerCase()),
                    ...createKeywords(displayName)
                  ],
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


api.post(
  "/update-username",
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
          field !== "sign-up" &&
          field !== "login" &&
          field !== "404" &&
          field !== "create-post" &&
          field !== "edit" &&
          field !== "forgot-password"
      )
      .withMessage("Username is invalid")
      .matches(/^[a-zA-Z0-9_.]+$/)
      .withMessage(
        "Username invalid. Username must be Alpha-Numeric, underscores and dots"
      ),
  ],
  async (req, res) => {
    const user = req.user;
    const newUserName = req.body.userName.trim();

    // Express validator
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ code: 400, message: errors[0] });
    }

    // Get users oldUserName
    const userRecord = await admin
      .auth()
      .getUser(user.uid)
      .catch((err) => {
        throw err;
      });
    const oldUserName = userRecord.customClaims.userName;
    const newCustomClaims = userRecord.customClaims;
    // Add the newUserName to the newCustomClaims
    newCustomClaims.userName = newUserName;

    // Check if both userNames are the same
    if (newUserName === oldUserName)
      return res.send(400).json({
        code: 400,
        message: "The new username is the same!",
      });

    // Run a transaction
    await admin
      .firestore()
      .runTransaction((transaction) => {
        return (
          transaction
            .get(admin.firestore().collection("users").doc(user.uid))
            .then((document) => {
              // Check if userName is being updated too often (less than 24 * 60 * 60 seconds or 1 day)
              if (
                Date.now() / 1000 - document.data().meta.userNameLastUpdated <
                24 * 60 * 60
              ) {
                // eslint-disable-next-line prefer-promise-reject-errors
                return Promise.reject({
                  code: 400,
                  message: "Username can only be updated once per day!",
                });
              }
              // If the userName being updated too fast, successfully proceed
              return Promise.resolve();
            })
            .then(() =>
              transaction.get(
                admin
                  .firestore()
                  .collection("takenUserNames")
                  .doc(newUserName.toLowerCase())
              )
            )
            .then((document) => {
              // Check if newUserName already taken by someone else
              if (document.exists) {
                // eslint-disable-next-line prefer-promise-reject-errors
                return Promise.reject({
                  code: 400,
                  message: "Username already exists!",
                });
              }

              // If the document doesn't exist, successfully proceed
              return Promise.resolve();
            })
            // Update the customClaims with the newUserName
            .then(() =>
              admin.auth().setCustomUserClaims(user.uid, newCustomClaims)
            )
            // Create a new takenUserNames record to avoid double userNames
            .then(() =>
              transaction.set(
                admin
                  .firestore()
                  .collection("takenUserNames")
                  .doc(newUserName.toLowerCase()),
                {
                  userUid: user.uid,
                  userName: newUserName,
                }
              )
            )
            // Delete the old takenUserNames record
            .then(() =>
              transaction.delete(
                admin
                  .firestore()
                  .collection("takenUserNames")
                  .doc(oldUserName.toLowerCase())
              )
            )
            // Finally update the newUserName in the firestore
            .then(() =>
              transaction.set(
                admin.firestore().collection("users").doc(user.uid),
                {
                  userName: newUserName,
                  userNameLowerCase: newUserName.toLowerCase(),
                  meta: {
                    userNameLastUpdated: Math.floor(Date.now() / 1000),
                  },
                },
                { merge: true }
              )
            )
        );
      })
      .then(() => {
        return res.status(200).json({
          code: 200,
          message: "Successfully updated username!",
        });
      })
      .catch(async (error) => {
        return res.status(error.code || 500).json(error);
      });
  }
);



// My Non API Functions -----------------------

const createKeywords = (text) => {
    let keywordsList = [];
    // Split the text into words if there are spaces
    text.split(" ").forEach((word) => {
      let tempWord = "";
      word.split("").forEach((letter) => {
        tempWord += letter;
        if (!keywordsList.includes(tempWord)) keywordsList.push(tempWord);
      });
    });
    return keywordsList;
  };

// Use Express middleware to intercept all requests
exports.api = functions.https.onRequest(api);
