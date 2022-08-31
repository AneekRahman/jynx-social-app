import 'package:flutter/material.dart';
import 'dart:async';

import 'package:social_app/models/ChatRow.dart';
import 'package:social_app/modules/constants.dart';

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
    Timer.periodic(new Duration(seconds: 1), (timer) {
      DateTime sentTime = new DateTime.fromMillisecondsSinceEpoch(int.parse(widget._chatRow.lastMsgSentTime!));
      if (this.mounted)
        setState(() {
          sentTimeFormattedString = convertToTimeAgo(sentTime);
        });
    });
  }

  @override
  void initState() {
    super.initState();
    _recalculateTimePassed();
  }

  @override
  Widget build(BuildContext context) {
    final fontFamily = !widget._chatRow.seen! ? HelveticaFont.Heavy : HelveticaFont.Medium;
    bool hasImg = widget._chatRow.otherUser.photoURL != null && widget._chatRow.otherUser.photoURL!.isNotEmpty;

    DateTime sentTime = new DateTime.fromMillisecondsSinceEpoch(int.parse(widget._chatRow.lastMsgSentTime!));
    sentTimeFormattedString = convertToTimeAgo(sentTime);

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 16,
        // vertical: 160,
        horizontal: 20,
      ),
      child: Row(
        children: [
          Container(
            height: 45,
            width: 45,
            decoration: hasImg
                ? BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(10000),
                    border: Border.all(color: Colors.yellow, width: 2),
                  )
                : null,
            child: hasImg
                ? ClipRRect(
                    child: Image.network(
                      widget._chatRow.otherUser.photoURL!,
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
          SizedBox(
            width: 16,
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
                    color: !widget._chatRow.seen! ? Colors.yellow : Colors.white,
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  Text(
                    // !widget._chatRow.seen! ? "New message" : "Opened",
                    widget._chatRow.lastMsg!.isEmpty
                        ? !widget._chatRow.seen!
                            ? "New message"
                            : "Opened"
                        : !widget._chatRow.seen!
                            ? "New: " + widget._chatRow.lastMsg!
                            : "Read: " + widget._chatRow.lastMsg!,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 12,
                      color: !widget._chatRow.seen! ? Colors.yellow : Colors.white,
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
              color: Colors.yellow,
            ),
          )
        ],
      ),
    );
  }
}
