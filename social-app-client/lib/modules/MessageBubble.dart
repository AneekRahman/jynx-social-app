import 'package:flutter/material.dart';

import '../models/MsgRow.dart';
import 'constants.dart';

class MessageBubble extends StatelessWidget {
  final MsgRow msgRow;
  final bool firstMsgOfUser;
  final bool isUser;
  MessageBubble({required this.msgRow, required this.firstMsgOfUser, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          margin: EdgeInsets.only(top: 4, right: 10, left: 10),
          decoration: BoxDecoration(
            color: Color(0xFFF1F1F1F1),
            border: Border(
              right: isUser ? BorderSide(color: Colors.purpleAccent, width: 4) : BorderSide(style: BorderStyle.none),
              left: isUser ? BorderSide(style: BorderStyle.none) : BorderSide(color: Colors.orange, width: 4),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          child: Text(
            msgRow.msg!,
            style: TextStyle(
              fontFamily: HelveticaFont.Roman,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}
