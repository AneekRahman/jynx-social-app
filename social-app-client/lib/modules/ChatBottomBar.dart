import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'constants.dart';
import '../pages/ChatRoomPage.dart';
import '../services/firestore_service.dart';
import '../services/rtd_service.dart';
import '../models/ChatRow.dart';
import '../models/UserFirestore.dart';

class ChatBottomBar extends StatefulWidget {
  BuildContext rootContext;
  ChatRow? chatRow;
  User currentUser;
  UserFirestore otherUser;
  Function setNewChatRoomUid;
  ChatBottomBar({
    Key? key,
    this.chatRow,
    required this.currentUser,
    required this.otherUser,
    required this.setNewChatRoomUid,
    required this.rootContext,
  }) : super(key: key);

  @override
  State<ChatBottomBar> createState() => _ChatBottomBarState();
}

class _ChatBottomBarState extends State<ChatBottomBar> {
  final chatMsgTextController = TextEditingController();
  String _textInputValue = "";
  bool _alreadySending = false;

  Future _createRequestAndSendMsg(context, firstMessage) async {
    // try {
    //   final String chatRoomUid = await widget.rootContext
    //       .read<RealtimeDatabaseService>()
    //       .createNewRequest(currentUser: widget.currentUser, otherUser: widget.otherUser, msg: _textInputValue);

    //   // Successfully created new requestedUserChat
    //   widget.chatRow = ChatRow(chatRoomUid: chatRoomUid, otherUser: widget.otherUser);
    //   // Set the newly created chatRoomUid
    //   widget.setNewChatRoomUid(chatRoomUid);
    //   // Lastly send the message
    //   await _sendMessageToChatRoom(context, firstMessage);
    // } catch (e) {
    //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    //     content: Text("Unable to send the message to the user currently"),
    //   ));
    //   throw e;
    // }
  }

  Future _sendMessageToChatRoom(context, bool firstMessage) async {
    // try {
    //   int lastMsgSentTime = new DateTime.now().millisecondsSinceEpoch;
    //   // Send a message in the RealtimeDatabase chatRoom
    //   await widget.rootContext.read<RealtimeDatabaseService>().sendMessageInRoom(
    //     widget.chatRow!.chatRoomUid,
    //     {"msg": _textInputValue, "sentTime": lastMsgSentTime, "userUid": widget.currentUser.uid},
    //   );

    //   // Update the userChats document and reset the lastMsgSeen array and sentTime
    //   widget.rootContext.read<FirestoreService>().setNewMsgUserChatsSeenReset(
    //         widget.chatRow!.chatRoomUid,
    //         widget.currentUser.uid,
    //         lastMsgSentTime.toString(),
    //         _textInputValue,
    //       );

    //   // If the chat is still in a requested one
    //   if (widget.chatRow!.requestedByOtherUser != null && widget.chatRow!.requestedByOtherUser!) {
    //     // Accept the request
    //     await widget.rootContext.read<FirestoreService>().acceptChatUserRequest(widget.rootContext.read<RealtimeDatabaseService>(),
    //         widget.chatRow!.chatRoomUid, widget.currentUser.uid, widget.chatRow!.otherUser.userUid);
    //   }
    // } catch (e) {
    //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("There was a network issue while sending the message")));
    //   throw e;
    // }
  }

  void _onSendHandler(context) async {
    if (_alreadySending) return;
    _alreadySending = true;

    if (widget.chatRow != null) {
      await _sendMessageToChatRoom(context, false);
    } else {
      // Send a message to the chatRoomUid
      await _createRequestAndSendMsg(context, true);
    }
    _alreadySending = false;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(width: 10),
        Container(
          margin: EdgeInsets.only(bottom: 14),
          child: IconButton(
            onPressed: () {},
            icon: Image.asset("assets/icons/Camera-icon.png", height: 30, width: 30),
          ),
        ),
        Container(
          width: MediaQuery.of(context).size.width - 60,
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Material(
            borderRadius: BorderRadius.circular(26),
            color: Color(0xFFF1F1F1F1),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Container(
                    margin: EdgeInsets.only(bottom: 2),
                    child: TextField(
                      maxLines: 5,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(fontFamily: HelveticaFont.Roman),
                      maxLength: 200,
                      controller: chatMsgTextController,
                      decoration: InputDecoration(
                        counterText: "",
                        contentPadding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),
                        hintText: 'Type your message here...',
                        hintStyle: TextStyle(fontFamily: HelveticaFont.Roman, fontSize: 14),
                        border: InputBorder.none,
                      ),
                      onChanged: ((value) {
                        setState(() {
                          _textInputValue = value;
                        });
                      }),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    // Save the input value
                    _textInputValue = chatMsgTextController.text;
                    // Reset the text input field
                    chatMsgTextController.clear();
                    // Don't send any message if _alreadySending or if message is empty
                    if (_textInputValue.isEmpty || _alreadySending) return;
                    _onSendHandler(context);
                  },
                  icon: Image.asset("assets/icons/Send-icon.png", height: 30, width: 30),
                ),
                SizedBox(width: 10),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
