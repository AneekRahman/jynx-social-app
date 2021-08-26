import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomClaims {
  String userName;

  CustomClaims({
    this.userName,
  });

  CustomClaims.fromJson(Map json) {
    this.userName = json["userName"];
    // final Map userMeta = json["userMeta"];
    // if (userMeta != null) {
    //   this.bio = userMeta["bio"];
    // }
  }

  static Future<CustomClaims> getClaims(forceRefresh) async {
    // If refresh is set to true, a refresh of the id token is forced.
    final idTokenResult =
        await FirebaseAuth.instance.currentUser.getIdTokenResult(forceRefresh);
    final Map claims = idTokenResult.claims;

    return CustomClaims.fromJson(claims);
  }
}
