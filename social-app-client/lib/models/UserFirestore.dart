import 'package:social_app/models/ChatRoomsInfos.dart';

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
    this.userUid = uid;
    this.displayName = map['displayName'];
    this.userName = map['userName'];
    this.userNameLowerCase = map['userNameLowerCase'];
    this.photoURL = map['photoURL'];
    this.userBio = map['userBio'];
    this.location = map['location'];
    this.website = map['website'];
  }

  UserFirestore.fromChatRoomsInfosMem(ChatRoomsInfosMem chatRoomsInfosMem) {
    this.userUid = chatRoomsInfosMem.userUid;
    this.displayName = chatRoomsInfosMem.name;
    this.userName = chatRoomsInfosMem.uName;
    this.photoURL = chatRoomsInfosMem.url;
  }
}
