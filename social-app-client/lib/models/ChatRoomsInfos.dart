class ChatRoomsInfos {
  late String chatRoomUid, lMsg;
  String? groupChatImageURL;
  late bool grp;
  late int lTime, seenByThisUser;
  late List<ChatRoomsInfosMem> mems = [];

  ChatRoomsInfos({
    required this.chatRoomUid,
    required this.lMsg,
    this.groupChatImageURL,
    required this.lTime,
    required this.grp,
    required this.seenByThisUser,
    required this.mems,
  });

  ChatRoomsInfos.fromMap(Map map, {required this.chatRoomUid, required this.seenByThisUser}) {
    this.lMsg = map["lMsg"];
    this.groupChatImageURL = map["groupChatImageURL"];
    this.lTime = map["lTime"];
    this.grp = map["grp"];

    Map memsMap = map["mems"];
    memsMap.forEach((userUid, memsUserInfo) {
      this.mems.add(ChatRoomsInfosMem(
            userUid: userUid,
            name: memsUserInfo["name"],
            uName: memsUserInfo["uName"],
            url: memsUserInfo["url"],
          ));
    });
  }
}

class ChatRoomsInfosMem {
  late String userUid, name, uName, url;
  ChatRoomsInfosMem({required this.userUid, required this.name, required this.uName, required this.url});
}
