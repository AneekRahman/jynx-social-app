import 'package:firebase_database/firebase_database.dart';

class UsersChatRooms {
  List<UsersChatRoom> usersChatRooms = [];

  UsersChatRooms({required this.usersChatRooms});

  UsersChatRooms.fromMap(Map value) {
    value.forEach((chatRoomUid, usersChatRoomInfo) {
      usersChatRooms.add(UsersChatRoom.fromMap(usersChatRoomInfo, chatRoomUid: chatRoomUid));
    });
  }
  UsersChatRooms.fromList(this.usersChatRooms);
}

class UsersChatRoom {
  late String chatRoomUid;
  late int lTime;
  late int seen;

  UsersChatRoom({
    required this.chatRoomUid,
    required this.lTime,
    required this.seen,
  });

  UsersChatRoom.fromMap(Map value, {required this.chatRoomUid}) {
    this.lTime = value["lTime"];
    this.seen = value["seen"];
  }
}
