import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_app/models/ChatRow.dart';
import 'package:social_app/models/UserProfileObject.dart';

class MyServer {
  static const String SERVER_API = "https://us-central1-jynx-chat.cloudfunctions.net/api";
  // static const String SERVER_API = "http://192.168.0.100:5000/jynx-chat/us-central1/api";
  static const String SIGNUP = "/signup";
  static const String UPDATE_USERNAME = "/update-username";
  static Map<String, String> JSON_HEADER = {
    "content-type": "application/json",
    "accept": "application/json",
  };
}

class Constants {
  static const int CHAT_LIST_READ_LIMIT = 10;
  static const int CHAT_ROOM_MESSAGES_READ_LIMIT = 10;
}

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
    borderSide: BorderSide(color: focused ? Colors.blueAccent : Color(0xFF757575)),
  );
}

ChatRow? makeChatRowFromUserChats(snapshot, String currentUserUid, bool isFromQuery) {
  UserChatsObject userChatsSnapshot;
  if (isFromQuery) {
    userChatsSnapshot = UserChatsObject.fromQuerySnapshot(snapshot);
  } else {
    userChatsSnapshot = UserChatsObject.fromDocumentSnapshot(snapshot);
  }

  // For private chats only!!!!!
  if (userChatsSnapshot.type == ChatType.PRIVATE) {
    ChatRow? chatRow;
    // Check if available in the members list
    userChatsSnapshot.memberInfo!.forEach((key, value) {
      if (key != currentUserUid) {
        UserProfileObject otherUser = UserProfileObject.fromJson(userChatsSnapshot.memberInfo![key], key);
        chatRow = ChatRow(
            chatRoomUid: snapshot.id,
            otherUser: otherUser,
            lastMsgSentTime: userChatsSnapshot.lastMsgSentTime,
            lastMsg: userChatsSnapshot.lastMsg,
            seen: userChatsSnapshot.lastMsgSeenBy!.contains(currentUserUid),
            requestedByOtherUser: userChatsSnapshot.requestedMembers!.contains(currentUserUid),
            requestedByThisUser: userChatsSnapshot.requestedMembers!.contains(otherUser.userUid),
            blockedByThisUser: userChatsSnapshot.blockedMembers!.contains(key));
      }
    });

    return chatRow;
  }
}

String convertToTimeAgo(DateTime dateTime) {
  Duration diff = DateTime.now().difference(dateTime);

  if (diff.inDays >= 7) {
    return '${(diff.inDays / 7).floor()}w';
  } else if (diff.inDays >= 1) {
    return '${diff.inDays}d';
  } else if (diff.inHours >= 1) {
    return '${diff.inHours}h';
  } else if (diff.inMinutes >= 1) {
    return '${diff.inMinutes}m';
  } else if (diff.inSeconds >= 1) {
    return '${diff.inSeconds}s';
  } else {
    return '0s';
  }
}

Widget buildYellowButton({required Widget child, required Function() onTap, required bool loading, required BuildContext context}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.all(14),
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Colors.yellow,
        borderRadius: BorderRadius.circular(1000),
      ),
      child: !loading
          ? child
          : Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 3,
                ),
              ),
            ),
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
