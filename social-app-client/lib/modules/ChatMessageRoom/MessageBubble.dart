import 'package:flutter/material.dart';
import 'package:social_app/models/ChatRoomsInfos.dart';

import '../../models/MsgRow.dart';
import '../constants.dart';

class MessageBubble extends StatelessWidget {
  final MsgRow msgRow;
  final bool wasSentInTheSameDay;
  final bool prevMsgSameUser;
  final bool nextMsgSameUser;
  final bool isUsersMsg;
  final ChatRoomsInfosMem otherUser;
  MessageBubble(
      {required this.msgRow,
      required this.wasSentInTheSameDay,
      required this.prevMsgSameUser,
      required this.isUsersMsg,
      required this.nextMsgSameUser,
      required this.otherUser});

  @override
  Widget build(BuildContext context) {
    DateTime sentTime = new DateTime.fromMillisecondsSinceEpoch(msgRow.sentTime!);
    String sentTimeFormattedString = Constants.convertToTimeAgo(sentTime);

    // If this is a info msg from server
    if (msgRow.type != 0) {
      // 1 = Received call info msg
      if (msgRow.type == 1)
        return Center(
          child: Container(
            padding: EdgeInsets.fromLTRB(14, 6, 14, 6),
            margin: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(.02),
              border: Border.all(color: Colors.black.withOpacity(.1), width: 1),
              borderRadius: BorderRadius.all(Radius.circular(100)),
            ),
            child: Text(
              isUsersMsg ? "You called ${otherUser.name}." : "${otherUser.name} called you.",
              style: TextStyle(fontFamily: HelveticaFont.Roman, fontSize: 13),
            ),
          ),
        );
    }

    return Column(
      crossAxisAlignment: isUsersMsg ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          textDirection: !isUsersMsg ? TextDirection.ltr : TextDirection.rtl,
          children: [
            Flexible(
              child: Container(
                margin: EdgeInsets.only(
                  top: !prevMsgSameUser ? 20 : 4,
                  right: isUsersMsg ? 14 : 90,
                  left: !isUsersMsg ? 14 : 90,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: !isUsersMsg && prevMsgSameUser ? Radius.circular(30) : Radius.circular(100),
                    bottomLeft: !isUsersMsg && nextMsgSameUser ? Radius.circular(30) : Radius.circular(100),
                    bottomRight: isUsersMsg && nextMsgSameUser ? Radius.circular(30) : Radius.circular(100),
                    topRight: isUsersMsg && prevMsgSameUser ? Radius.circular(30) : Radius.circular(100),
                  ),
                  gradient: LinearGradient(
                    colors: isUsersMsg
                        ? [
                            const Color(0xFF3EC2F9),
                            const Color(0xFF3BDDFA),
                          ]
                        : [
                            const Color(0xFF9B72FD),
                            const Color(0xFFBB9BFE),
                          ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  // border: Border(
                  //   right: isUser ? BorderSide(color: Colors.purpleAccent, width: 4) : BorderSide(style: BorderStyle.none),
                  //   left: isUser ? BorderSide(style: BorderStyle.none) : BorderSide(color: Colors.orange, width: 4),
                  // ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                child: Text(
                  msgRow.msg!,
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: HelveticaFont.Medium,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
        Container(
          margin: EdgeInsets.only(
            top: 2,
            right: !isUsersMsg ? 0 : 30,
            left: isUsersMsg ? 0 : 30,
          ),
          child: !nextMsgSameUser && !wasSentInTheSameDay
              ? Text(
                  sentTimeFormattedString + " ago",
                  style: TextStyle(fontFamily: HelveticaFont.Roman, fontSize: 11, color: Colors.white54),
                )
              : SizedBox(),
        ),
      ],
    );
  }
}
