import 'package:flutter/material.dart';

import '../models/MsgRow.dart';
import 'constants.dart';
import 'package:timeago/timeago.dart' as timeago;

class MessageBubble extends StatelessWidget {
  final MsgRow msgRow;
  final bool firstMsgOfUser;
  final bool isUser;
  MessageBubble({required this.msgRow, required this.firstMsgOfUser, required this.isUser});

  @override
  Widget build(BuildContext context) {
    DateTime sentTime = new DateTime.fromMillisecondsSinceEpoch(msgRow.sentTime!);
    String sentTimeFormattedString = timeago.format(sentTime, locale: 'en_short', allowFromNow: true);

    return Column(
      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          textDirection: !isUser ? TextDirection.ltr : TextDirection.rtl,
          children: [
            Flexible(
              child: Container(
                margin: EdgeInsets.only(
                  top: 7,
                  right: isUser ? 14 : 0,
                  left: !isUser ? 14 : 0,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  color: isUser ? Color.fromARGB(238, 206, 253, 255) : Color(0xFFF1F1F1F1),
                  // border: Border(
                  //   right: isUser ? BorderSide(color: Colors.purpleAccent, width: 4) : BorderSide(style: BorderStyle.none),
                  //   left: isUser ? BorderSide(style: BorderStyle.none) : BorderSide(color: Colors.orange, width: 4),
                  // ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: Text(
                  msgRow.msg!,
                  style: TextStyle(
                    fontFamily: HelveticaFont.Roman,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(bottom: 8, left: !isUser ? 6 : 60, right: isUser ? 6 : 60),
              child: Text(
                sentTimeFormattedString + " ago",
                style: TextStyle(fontFamily: HelveticaFont.Roman, fontSize: 11, color: Colors.black26),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
