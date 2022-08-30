import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ChatRow.dart';
import '../services/firestore_service.dart';
import 'constants.dart';

Center _buildLoadingAnim() {
  return Center(
    child: SizedBox(child: CircularProgressIndicator(), height: 25, width: 25),
  );
}

class ChatRequestActions extends StatefulWidget {
  ChatRequestActions({required this.currentUser, required this.chatRow});
  User currentUser;
  ChatRow chatRow;

  @override
  _ChatRequestActionsState createState() => _ChatRequestActionsState();
}

class _ChatRequestActionsState extends State<ChatRequestActions> {
  bool _loading = false;

  Future _acceptRequest() async {
    if (_loading || widget.chatRow.chatRoomUid == null) return;
    setState(() => _loading = true);
    try {
      // Accept the request
      await context
          .read<FirestoreService>()
          .acceptChatUserRequest(widget.chatRow.chatRoomUid, widget.currentUser.uid, widget.chatRow.otherUser.userUid);
      // Update the UI
      setState(() => widget.chatRow.requestedByOtherUser = false);
    } catch (e) {
      throw e;
    }
    // Update the UI
    setState(() => _loading = false);
  }

  Future _blockUnblockUser() async {
    if (_loading || widget.chatRow.chatRoomUid == null) return;
    setState(() => _loading = true);
    try {
      // Accept the request
      if (!widget.chatRow.blockedByThisUser!) {
        await context
            .read<FirestoreService>()
            .blockUser(userChatsDocumentUid: widget.chatRow.chatRoomUid, blockedUserUid: widget.chatRow.otherUser.userUid);
      } else {
        await context
            .read<FirestoreService>()
            .unblockUser(userChatsDocumentUid: widget.chatRow.chatRoomUid, blockedUserUid: widget.chatRow.otherUser.userUid);
      }
      // Update the UI
      setState(() {
        widget.chatRow.blockedByThisUser = !widget.chatRow.blockedByThisUser!;
      });
    } catch (e) {
      throw e;
    }
    // Update the UI
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.chatRow.requestedByOtherUser == null || !widget.chatRow.requestedByOtherUser!) return Container();

    if (widget.chatRow.requestedByOtherUser! || widget.chatRow.blockedByThisUser!) {
      return Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 10),
            height: 1,
            width: MediaQuery.of(context).size.width,
            color: Color(0xFFF1F1F1F1),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text(
              widget.chatRow.blockedByThisUser!
                  ? "You have blocked this user and they will not be able to message you."
                  : "This message will be moved to your chat list when you accept it or reply here.",
              style: TextStyle(fontFamily: HelveticaFont.Light),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: !_loading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () {
                          _acceptRequest();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black12, width: 1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                          child: Text(
                            "Accept Request",
                            style: TextStyle(fontFamily: HelveticaFont.Bold),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _blockUnblockUser();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black12, width: 1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                          child: Text(
                            widget.chatRow.blockedByThisUser! ? "Unblock User" : "Block User",
                            style: TextStyle(fontFamily: HelveticaFont.Bold),
                          ),
                        ),
                      ),
                    ],
                  )
                : _buildLoadingAnim(),
          ),
        ],
      );
    } else {
      return Container();
    }
  }
}
