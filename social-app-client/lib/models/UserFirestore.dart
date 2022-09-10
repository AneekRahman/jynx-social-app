import 'dart:convert';

class UserFirestore {
  late String userUid;
  String? displayName;
  String? userName;
  String? userNameLowerCase;
  String? photoURL;
  String? userBio;
  String? location;
  String? website;
  Map? meta = {};

  UserFirestore({
    required this.userUid,
    this.displayName,
    this.userName,
    this.userNameLowerCase,
    this.photoURL,
    this.userBio,
    this.location,
    this.website,
    this.meta,
  });

  UserFirestore.fromMap(Map map, String uid) {
    userUid = uid;
    displayName = map['displayName'];
    userName = map['userName'];
    userNameLowerCase = map['userNameLowerCase'];
    photoURL = map['photoURL'];
    userBio = map['userBio'];
    location = map['location'];
    website = map['website'];
  }
}
