import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:social_app/models/ChatRoomsInfos.dart';
import 'dart:async';

import 'package:social_app/modules/constants.dart';

class UsersChatRoomsRow extends StatefulWidget {
  final User currentUser;
  final ChatRoomsInfos chatRoomsInfos;
  UsersChatRoomsRow({required this.chatRoomsInfos, required this.currentUser});
  @override
  _UsersChatRoomsRowState createState() => _UsersChatRoomsRowState();
}

class _UsersChatRoomsRowState extends State<UsersChatRoomsRow> {
  late String sentTimeFormattedString;
  bool isGroupChat = false;
  ChatRoomsInfosMem? otherPrivateChatRoomUser;

  void _recalculateTimePassed() {
    // Every 1 minute
    Timer.periodic(new Duration(seconds: 1), (timer) {
      DateTime sentTime = new DateTime.fromMillisecondsSinceEpoch(widget.chatRoomsInfos.lTime);
      if (this.mounted)
        setState(() {
          sentTimeFormattedString = convertToTimeAgo(sentTime);
        });
    });
  }

  void initUsersChatRoomsRowInfos() {
    if (!widget.chatRoomsInfos.grp) {
      // This means that this is a private chat, so save the other user as a state
      widget.chatRoomsInfos.mems.forEach((element) {
        if (widget.currentUser.uid != element.userUid) {
          otherPrivateChatRoomUser = element;
        }
      });
    } else {
      // This means that this is a group chat
      isGroupChat = true;
    }
    setState(() {});
  }

  @override
  void initState() {
    initUsersChatRoomsRowInfos();
    _recalculateTimePassed();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final fontFamily = widget.chatRoomsInfos.seenByThisUser == 0 ? HelveticaFont.Heavy : HelveticaFont.Medium;
    String chatRoomRowImageURL = isGroupChat ? widget.chatRoomsInfos.groupChatImageURL! : otherPrivateChatRoomUser!.url;

    DateTime sentTime = new DateTime.fromMillisecondsSinceEpoch(widget.chatRoomsInfos.lTime);
    sentTimeFormattedString = convertToTimeAgo(sentTime);

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 16,
        // vertical: 160,
        horizontal: 20,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                height: 45,
                width: 45,
                margin: EdgeInsets.only(right: 16),
                decoration: chatRoomRowImageURL.isNotEmpty
                    ? BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(10000),
                        border: Border.all(color: Colors.yellow, width: 2),
                      )
                    : null,
                child: chatRoomRowImageURL.isNotEmpty
                    ? ClipRRect(
                        child: Image.network(
                          chatRoomRowImageURL,
                          height: 45,
                          width: 45,
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(100)),
                      )
                    : Image.asset(
                        "assets/user.png",
                        height: 40,
                        width: 40,
                      ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherPrivateChatRoomUser!.name,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(
                    height: 2,
                  ),
                  SizedBox(
                    height: 18,
                    width: MediaQuery.of(context).size.width - 160,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          widget.chatRoomsInfos.seenByThisUser == 0 ? Icons.chat_bubble : Icons.chat_bubble_outline,
                          size: 14,
                          color: widget.chatRoomsInfos.seenByThisUser == 0 ? Colors.yellow : Colors.white,
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        Flexible(
                          child: Text(
                            // !widget._chatRow.seen! ? "New message" : "Opened",
                            widget.chatRoomsInfos.seenByThisUser == 0
                                ? "New: " + widget.chatRoomsInfos.lMsg
                                : "Read: " + widget.chatRoomsInfos.lMsg,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 12,
                              color: widget.chatRoomsInfos.seenByThisUser == 0 ? Colors.yellow : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(
            width: 30,
            child: Text(
              sentTimeFormattedString,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 12,
                color: Colors.yellow,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
