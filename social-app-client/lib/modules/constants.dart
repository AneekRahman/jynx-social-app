import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_app/models/ChatRow.dart';
import 'package:social_app/models/MyUserObject.dart';
import 'package:social_app/models/UserChatsSnapshot.dart';

final normalTextStyle = TextStyle(
  fontFamily: HelveticaFont.Roman,
);

class HelveticaFont {
  static const String UltraLight = "helvetica_ultra_light";
  static const String Thin = "helvetica_thin";
  static const String Light = "helvetica_light";
  static const String Roman = "helvetica_roman";
  static const String Medium = "helvetica_medium";
  static const String Bold = "helvetica_bold";
  static const String Heavy = "helvetica_heavy";
  static const String Black = "helvetica_black";
}

final headingStyle = TextStyle(
  fontSize: 28,
  fontFamily: HelveticaFont.Heavy,
  color: Colors.black,
  height: 1.5,
);

final otpInputDecoration = InputDecoration(
  counterText: "",
  contentPadding: EdgeInsets.symmetric(vertical: 15),
  border: outlineInputBorder(false),
  focusedBorder: outlineInputBorder(true),
  enabledBorder: outlineInputBorder(false),
);

OutlineInputBorder outlineInputBorder(bool focused) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(15),
    borderSide:
        BorderSide(color: focused ? Colors.blueAccent : Color(0xFF757575)),
  );
}

ChatRow getChatRowFromDocSnapshot(
    QueryDocumentSnapshot snapshot, String currentUserUid) {
  UserChatsSnapshot userChatsSnapshot =
      UserChatsSnapshot.fromSnapshot(snapshot);

  // For private chats
  if (userChatsSnapshot.type == "PRIVATE") {
    ChatRow chatRow;
    // Check if available in the members list
    userChatsSnapshot.memberInfo.forEach((key, value) {
      if (key != currentUserUid) {
        MyUserObject userObject = MyUserObject.fromJson(
            {...userChatsSnapshot.memberInfo[key], "userUid": key});
        chatRow = ChatRow(
            userChatsDocUid: snapshot.id,
            chatRoomUid: userChatsSnapshot.chatRoomUid,
            otherUsersName: userObject.displayName,
            otherUsersUserName: userObject.userName,
            otherUsersUid: userObject.userUid,
            otherUsersPic: userObject.profilePic,
            lastMsgSentTime: userChatsSnapshot.lastMsgSentTime,
            seen: userChatsSnapshot.lastMsgSeenBy.contains(currentUserUid),
            requested:
                userChatsSnapshot.requestedMembers.contains(currentUserUid));
      }
    });

    return chatRow;
  }
}

Widget buildYellowButton(
    {Widget child, Function onTap, bool loading, BuildContext context}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.all(14),
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Colors.yellow,
        borderRadius: BorderRadius.circular(1000),
      ),
      child: child,
    ),
  );
}

List<String> createKeywords(text) {
  List<String> keywordsList = [];
  // Split the text into words if there are spaces
  text.split(" ").forEach((word) {
    String tempWord = "";
    word.split("").forEach((letter) {
      tempWord += letter;
      if (!keywordsList.contains(tempWord)) keywordsList.add(tempWord);
    });
  });
  return keywordsList;
}
