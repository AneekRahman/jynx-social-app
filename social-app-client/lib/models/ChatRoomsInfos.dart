import 'package:social_app/models/UserFirestore.dart';

class ChatRoomsInfos {
  late String chatRoomUid, lMsg;
  String? groupChatImageURL = "";
  late bool grp;
  int? lTime;
  int? seenByThisUser = 1;
  late List<ChatRoomsInfosMem> mems = [];

  ChatRoomsInfos({
    required this.chatRoomUid,
    required this.lMsg,
    this.groupChatImageURL,
    this.lTime,
    required this.grp,
    this.seenByThisUser,
    required this.mems,
  });

  ChatRoomsInfos.fromMap(Map map, {required this.chatRoomUid, this.lTime, this.seenByThisUser}) {
    this.lMsg = map["lMsg"];
    this.groupChatImageURL = map["groupChatImageURL"];
    this.grp = map["grp"];

    Map memsMap = map["mems"];
    memsMap.forEach((userUid, memsUserInfo) {
      this.mems.add(ChatRoomsInfosMem(
            userUid: userUid,
            name: memsUserInfo["name"],
            uName: memsUserInfo["uName"],
            url: memsUserInfo["url"] ?? "",
            acc: memsUserInfo["acc"],
          ));
    });
  }
}

class ChatRoomsInfosMem {
  /// [userUid], [name], [uName], [url], [acc] will always be present
  late String userUid, name, uName, url;
  late int acc;
  ChatRoomsInfosMem({required this.userUid, required this.name, required this.uName, required this.url, required this.acc});

  ChatRoomsInfosMem.fromUserFirestore(UserFirestore userFirestore) {
    this.userUid = userFirestore.userUid;
    this.name = userFirestore.displayName!;
    this.uName = userFirestore.userName!;
    this.url = userFirestore.photoURL!;
  }
}
