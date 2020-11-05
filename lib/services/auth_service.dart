import 'package:firebase_auth/firebase_auth.dart';

class AuthenticationService {
  final FirebaseAuth _firebaseAuth;
  String _verificationId;

  AuthenticationService(this._firebaseAuth);

  /// Changed to idTokenChanges as it updates depending on more cases.
  Stream<User> get authStateChanges => _firebaseAuth.idTokenChanges();

  /// This won't pop routes so you could do something like
  /// Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
  /// after you called this method if you want to pop all routes.
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<String> phoneSignIn({String smsCode}) async {
    if (this._verificationId == null)
      return "Error with state, please go back \nand start again";
    print("_verificationId is: " + _verificationId + " and code:" + smsCode);

    // Create a PhoneAuthCredential with the code
    PhoneAuthCredential phoneAuthCredential = PhoneAuthProvider.credential(
        verificationId: _verificationId, smsCode: smsCode);

    try {
      // Sign the user in (or link) with the credential
      await _firebaseAuth.signInWithCredential(phoneAuthCredential);
      return "success";
    } on FirebaseAuthException catch (e) {
      if (e.code == "invalid-verification-code")
        return "The code you entered was incorrect";
      return e.message;
    } catch (e) {
      print(e);
      return "We encountered an error while logging in";
    }
  }

  Future<void> sendPhoneVerificationCode(
      {String phoneNo, Function(String) callback}) async {
    print("Send the veri code");
    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNo,
        codeSent: (String verificationId, int resendToken) async {
          this._verificationId = verificationId;
          callback("success");
        },
        verificationFailed: (FirebaseAuthException e) {
          print("Error called: " + e.message);
          if (e.code == 'invalid-phone-number') {
            return callback('The provided phone number is not valid.');
          }
          callback(e.message);
        },
        verificationCompleted: (PhoneAuthCredential phoneAuthCredential) {},
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      print(e);
      callback("We encountered an error while \nsending a verification code");
    }
  }

  static Future<Map<dynamic, dynamic>> currentUserClaims(forceRefresh) async {
    // If refresh is set to true, a refresh of the id token is forced.
    final idTokenResult =
        await FirebaseAuth.instance.currentUser.getIdTokenResult(forceRefresh);

    return idTokenResult.claims;
  }

  Future<void> emailSignIn({String email, String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      return "success";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        return 'Wrong password provided for that user.';
      }
      return e.message;
    } catch (e) {
      print(e);
    }
  }

  Future<void> emailSignUp({String email, String password}) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);
      return "Signed up";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        return 'The account already exists for that email.';
      }
      return e.message;
    } catch (e) {
      print(e);
    }
  }
}
