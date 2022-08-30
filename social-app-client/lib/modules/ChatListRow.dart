import 'package:flutter/material.dart';
import 'dart:async';

import 'package:social_app/models/ChatRow.dart';
import 'package:social_app/modules/constants.dart';
import 'package:timeago/timeago.dart' as timeago;

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
              color: Colors.white,
            ),
          )
        ],
      ),
    );
  }
}
