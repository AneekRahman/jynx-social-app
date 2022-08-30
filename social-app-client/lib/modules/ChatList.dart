import 'package:flutter/material.dart';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:social_app/models/ChatRow.dart';
import 'package:social_app/modules/LoadingBar.dart';
import 'package:social_app/modules/constants.dart';
import 'package:social_app/pages/ChatRoomPage.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatsList extends StatelessWidget {
  ChatsList({
    Key? key,
    required this.currentUser,
    required this.stream,
    this.emptyChatListMsg,
  }) : super(key: key);
  final Widget? emptyChatListMsg;
  final User currentUser;
  List<ChatRow> chatRows = [];
  bool loadingChats = true;
  final Stream<QuerySnapshot> stream;

  void _removeIfAlreadyAdded(ChatRow chatRow) {
    for (int i = 0; i < chatRows.length; i++) {
      ChatRow element = chatRows.elementAt(i);
      if (element != null && chatRow.chatRoomUid == element.chatRoomUid) {
        final index = chatRows.indexOf(element);
        chatRows.removeAt(index);
      }
    }
  }

  void _setChatRowsFromStream(List<QueryDocumentSnapshot> usersChatsDocSnapList) {
    usersChatsDocSnapList.forEach((snapshot) {
      ChatRow chatRow = getChatRowFromDocSnapshot(snapshot, currentUser.uid)!;
      _removeIfAlreadyAdded(chatRow);
      chatRows.add(chatRow);
    });

    // Sort the first 10 results on the client side as well
    chatRows.sort((a, b) => b.lastMsgSentTime!.compareTo(a.lastMsgSentTime!));
  }

  void _buildChatRows(List<QueryDocumentSnapshot> snapshots) {
    print("UPDATE FROM STREAM FOR USER " + currentUser.uid);

    if (chatRows.length <= 10) {
      // Remove all if list less than or equal to 10
      chatRows.clear();
    } else {
      // Remove the first 10 (Range of stream)
      chatRows.removeRange(0, 9);
    }
    // Set the chatRows list
    _setChatRowsFromStream(snapshots);
    // Update the loading Animation
    loadingChats = false;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: stream,
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasData) {
          _buildChatRows(snapshot.data!.docs);
        }

        return Expanded(
          child: Column(
            children: [
              LoadingBar(
                loading: loadingChats,
              ),
              // Show the end of result widget here
              emptyChatListMsg != null && snapshot.hasData && snapshot.data!.docs.length == 0 ? emptyChatListMsg! : Container(),
              // Show the ChatList scroll view here
              snapshot.hasData
                  ? Expanded(
                      child: CustomScrollView(
                        physics: BouncingScrollPhysics(),
                        slivers: [
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                ChatRow chatRow = chatRows.elementAt(index);
                                return TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        CupertinoPageRoute(
                                            builder: (context) => ChatRoomPage(
                                                  chatRow: chatRow,
                                                  otherUser: chatRow.otherUser,
                                                )),
                                      );
                                    },
                                    child: ChatsListRow(chatRow: chatRow));
                              },
                              childCount: chatRows.length,
                            ),
                          )
                        ],
                      ),
                    )
                  : Container()
            ],
          ),
        );
      },
    );
  }
}

class ChatsListRow extends StatefulWidget {
  const ChatsListRow({
    Key? key,
    required ChatRow chatRow,
  })  : _chatRow = chatRow,
        super(key: key);

  final ChatRow _chatRow;

  @override
  _ChatsListRowState createState() => _ChatsListRowState();
}

class _ChatsListRowState extends State<ChatsListRow> {
  late String sentTimeFormattedString;
  void _recalculateTimePassed() {
    // Every 1 minute
    Timer.periodic(new Duration(minutes: 1), (timer) {
      if (this.mounted)
        setState(() {
          _calculateAndSetTimeString();
        });
    });
  }

  void _calculateAndSetTimeString() {
    DateTime sentTime = new DateTime.fromMillisecondsSinceEpoch(int.parse(widget._chatRow.lastMsgSentTime!));
    sentTimeFormattedString = timeago.format(sentTime, locale: 'en_short', allowFromNow: true);
  }

  @override
  void initState() {
    super.initState();
    _calculateAndSetTimeString();
    _recalculateTimePassed();
  }

  @override
  Widget build(BuildContext context) {
    final fontFamily = !widget._chatRow.seen! ? HelveticaFont.Heavy : HelveticaFont.Medium;

    bool hasImg = widget._chatRow.otherUser.photoURL != null && widget._chatRow.otherUser.photoURL!.isNotEmpty;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: hasImg
                ? Image.network(
                    widget._chatRow.otherUser.photoURL!,
                    height: 40,
                    width: 40,
                  )
                : Image.asset(
                    "assets/user.png",
                    height: 40,
                    width: 40,
                  ),
          ),
          SizedBox(
            width: 10,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget._chatRow.otherUser.displayName!,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              SizedBox(
                height: 2,
              ),
              Row(
                children: [
                  Icon(
                    !widget._chatRow.seen! ? Icons.chat_bubble : Icons.chat_bubble_outline,
                    size: 14,
                    color: Colors.white,
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  Text(
                    !widget._chatRow.seen! ? "New message" : "Opened",
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Expanded(
            child: Container(),
          ),
          Text(
            sentTimeFormattedString,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 12,
            ),
          )
        ],
      ),
    );
  }
}
