import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'constants.dart';
import '../pages/ChatRoomPage.dart';
import '../services/firestore_service.dart';
import '../services/rtd_service.dart';
import '../models/ChatRow.dart';
import '../models/UserProfileObject.dart';

class ChatBottomBar extends StatefulWidget {
  BuildContext rootContext;
  ChatRow? chatRow;
  User currentUser;
  UserProfileObject otherUser;
  Function setNewChatRoomUid;
  ChatBottomBar(
      {Key? key,
      this.chatRow,
      required this.currentUser,
      required this.otherUser,
      required this.setNewChatRoomUid,
      required this.rootContext})
      : super(key: key);

  @override
  State<ChatBottomBar> createState() => _ChatBottomBarState();
}

class _ChatBottomBarState extends State<ChatBottomBar> {
  final chatMsgTextController = TextEditingController();
  String _textInputValue = "";
  bool _alreadySending = false;

  Future _createRequestAndSendMsg(context, firstMessage) async {
    try {
      final String chatRoomUid = await widget.rootContext
          .read<FirestoreService>()
          .createRequestedUserChats(otherUserObject: widget.otherUser, currentUser: widget.currentUser, lastMsg: _textInputValue);

      // Successfully created new requestedUserChat
      widget.chatRow = ChatRow(chatRoomUid: chatRoomUid, otherUser: widget.otherUser);
      // Set the newly created chatRoomUid
      widget.setNewChatRoomUid(chatRoomUid);
      // Lastly send the message
      await _sendMessageToChatRoom(context, firstMessage);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Unable to send the message to the user currently"),
      ));
      throw e;
    }
  }

  Future _sendMessageToChatRoom(context, bool firstMessage) async {
    try {
      int lastMsgSentTime = new DateTime.now().millisecondsSinceEpoch;
      // Send a message in the RealtimeDatabase chatRoom
      await widget.rootContext.read<RealtimeDatabaseService>().sendMessageInRoom(
          widget.chatRow!.chatRoomUid,
          {"msg": _textInputValue, "sentTime": lastMsgSentTime, "userUid": widget.currentUser.uid},
          firstMessage,
          {widget.chatRow!.otherUser.userUid: true, widget.currentUser.uid: true});

      // Update the userChats document and reset the lastMsgSeen array and sentTime
      widget.rootContext.read<FirestoreService>().setNewMsgUserChatsSeenReset(
            widget.chatRow!.chatRoomUid,
            widget.currentUser.uid,
            lastMsgSentTime.toString(),
            _textInputValue,
          );

      // If the chat is still in a requested one
      if (widget.chatRow!.requestedByOtherUser != null && widget.chatRow!.requestedByOtherUser!) {
        // Accept the request
        await widget.rootContext.read<FirestoreService>().acceptChatUserRequest(widget.rootContext.read<RealtimeDatabaseService>(),
            widget.chatRow!.chatRoomUid, widget.currentUser.uid, widget.chatRow!.otherUser.userUid);
        // Update the UI
        setState(() => widget.chatRow!.requestedByOtherUser = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("There was a network issue while sending the message"),
      ));
      throw e;
    }
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
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Material(
            borderRadius: BorderRadius.circular(4),
            color: Color(0xFFF1F1F1F1),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    maxLines: 5,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(fontFamily: HelveticaFont.Roman),
                    controller: chatMsgTextController,
                    decoration: kMessageTextFieldDecoration,
                    onChanged: ((value) {
                      setState(() {
                        _textInputValue = value;
                      });
                    }),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    // Save the input value
                    _textInputValue = chatMsgTextController.text;
                    // Reset the text input field
                    chatMsgTextController.clear();
                    // Don't send any message if _alreadySending or if message is empty
                    if (_textInputValue.isEmpty || _alreadySending) return;
                    _onSendHandler(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 14),
                    child: Icon(
                      Icons.send,
                      size: 30,
                      color: _textInputValue.isEmpty ? Colors.black38 : Colors.purpleAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
