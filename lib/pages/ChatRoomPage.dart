import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:social_app/models/ChatRow.dart';
import 'package:social_app/models/MsgRow.dart';
import 'package:social_app/models/MyUserObject.dart';
import 'package:social_app/services/rtd_service.dart';

const kMessageTextFieldDecoration = InputDecoration(
  contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
  hintText: 'Type your message here...',
  hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 14),
  border: InputBorder.none,
);

AppBar chatTopBar = AppBar(
  leading: Icon(Icons.arrow_back_ios),
  iconTheme: IconThemeData(color: Colors.black),
  elevation: 0,
  backgroundColor: Colors.white10,
  title: Row(
    children: <Widget>[
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Naim Shahriyer',
            style: TextStyle(
                fontFamily: 'Poppins', fontSize: 14, color: Colors.black),
          ),
          Text('Active',
              style: TextStyle(
                  fontFamily: 'Poppins', fontSize: 10, color: Colors.black))
        ],
      ),
    ],
  ),
  actions: <Widget>[
    GestureDetector(
      child: Icon(Icons.more_vert),
    )
  ],
);

class ChatRoomPage extends StatefulWidget {
  final ChatRow chatRow;
  final MyUserObject otherUser;
  ChatRoomPage({@required this.chatRow, this.otherUser});
  @override
  _ChatRoomPageState createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  User _currentUser;
  List<MsgRow> _msgRows = [];
  String _chatRoomUid;

  void _removeIfAlreadyAdded(MsgRow msgRow) {
    for (int i = 0; i < _msgRows.length; i++) {
      MsgRow element = _msgRows.elementAt(i);
      if (element != null && msgRow.msgUid == element.msgUid) {
        final index = _msgRows.indexOf(element);
        _msgRows.removeAt(index);
      }
    }
  }

  void _setMsgRowsFromStream(dynamic chatRoomMsgsObject) {
    chatRoomMsgsObject.forEach((key, value) {
      MsgRow msgRow =
          MsgRow.fromJson({...chatRoomMsgsObject[key], 'msgUid': key});
      _removeIfAlreadyAdded(msgRow);
      _msgRows.add(msgRow);
    });

    // Sort the first 10 results on the client side as well
    _msgRows.sort((a, b) => b.sentTime.compareTo(a.sentTime));
  }

  @override
  void initState() {
    _chatRoomUid = widget.chatRow.chatRoomUid;
    _currentUser = context.read<User>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark),
      child: Scaffold(
        appBar: chatTopBar,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: StreamBuilder(
                stream: context
                    .watch<RealtimeDatabaseService>()
                    .getChatRoomStream(_chatRoomUid),
                builder: (context, AsyncSnapshot<Event> snapshot) {
                  if (snapshot.hasData && !snapshot.hasError) {
                    _setMsgRowsFromStream(snapshot.data.snapshot.value);

                    return CustomScrollView(
                      reverse: true,
                      physics: BouncingScrollPhysics(),
                      slivers: [
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              MsgRow msgRow = _msgRows.elementAt(index);
                              // Check if previous post was also from the same user
                              bool firstMsgOfUser = true;
                              if (index == 0 ||
                                  _msgRows.elementAt(index - 1).msgUid ==
                                      _currentUser.uid) {
                                firstMsgOfUser = false;
                              }

                              print("CURRENT USER ID: " + _currentUser.uid);

                              return MessageBubble(
                                msgRow: msgRow,
                                isUser: msgRow.userUid == _currentUser.uid,
                                firstMsgOfUser: firstMsgOfUser,
                              );
                            },
                            childCount: _msgRows.length,
                          ),
                        )
                      ],
                    );
                  } else {
                    return Center(
                      child: SizedBox(
                          child: CircularProgressIndicator(),
                          height: 25,
                          width: 25),
                    );
                  }
                },
              ),
            ),
            ChatBottomBar(
                chatRoomUid: _chatRoomUid,
                currentUser: _currentUser,
                otherUser: widget.otherUser,
                setChatRoomUid: (String chatRoomUid) {
                  setState(() {
                    _chatRoomUid = chatRoomUid;
                  });
                }),
          ],
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final MsgRow msgRow;
  final bool firstMsgOfUser;
  final bool isUser;
  MessageBubble({this.msgRow, this.firstMsgOfUser, this.isUser});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          margin: EdgeInsets.only(top: 4, right: 10, left: 10),
          decoration: BoxDecoration(
            color: Color(0xFFF1F1F1F1),
            border: Border(
              right: isUser
                  ? BorderSide(color: Colors.blueAccent, width: 4)
                  : BorderSide(style: BorderStyle.none),
              left: isUser
                  ? BorderSide(style: BorderStyle.none)
                  : BorderSide(color: Colors.orangeAccent, width: 4),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          child: Text(
            msgRow.msg,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}

class ChatBottomBar extends StatelessWidget {
  String _chatRoomUid;
  User _currentUser;
  MyUserObject _otherUser;
  Function _setChatRoomUid;
  ChatBottomBar(
      {Key key,
      String chatRoomUid,
      User currentUser,
      MyUserObject otherUser,
      Function setChatRoomUid})
      : _chatRoomUid = chatRoomUid,
        _currentUser = currentUser,
        _otherUser = otherUser,
        _setChatRoomUid = setChatRoomUid,
        super(key: key);

  final chatMsgTextController = TextEditingController();
  String _textInputValue = "";
  bool _alreadySending = false;

  Future _createRequestAndSendMsg(context) async {
    print("Need to create a new requestedUserChats doc and send message");

    final Map<String, String> response = await context
        .read<RealtimeDatabaseService>()
        .createRequestedUserChats(
            currentUsersUid: _currentUser.uid,
            otherUsersUid: _otherUser.userUid,
            currentUsersName: _currentUser.displayName,
            currentUsersPic: _currentUser.photoURL);

    if (response['status'] == "success" && response["chatRoomUid"] != null) {
      // Successfully created new requestedUserChat
      print(
          "Successfully created requestedUserChats document and sent message");
      // Set the newly created chatRoomUid
      _chatRoomUid = response["chatRoomUid"];
      _setChatRoomUid(response["chatRoomUid"]);
      _sendMessageToChatRoom(context);
    } else {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text("Error: " + response["errorMsg"]),
      ));
    }
  }

  void _sendMessageToChatRoom(context) {
    print("Sending message to the user");
    context.read<RealtimeDatabaseService>().sendMessageInRoom(
      _chatRoomUid,
      {
        "msg": _textInputValue,
        "sentTime": new DateTime.now().millisecondsSinceEpoch,
        "userUid": _currentUser.uid
      },
    );
  }

  void _onSendHandler(context) async {
    _alreadySending = true;

    if (_chatRoomUid == null) {
      // TODO Test this out
      await _createRequestAndSendMsg(context);
    } else {
      // Send a message to the chatRoomUid
      _sendMessageToChatRoom(context);
    }

    // In the end, Reset the text input field
    chatMsgTextController.clear();
    _alreadySending = false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      child: Material(
        borderRadius: BorderRadius.circular(4),
        color: Color(0xFFF1F1F1F1),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (String value) {
                  _textInputValue = value;
                },
                controller: chatMsgTextController,
                decoration: kMessageTextFieldDecoration,
              ),
            ),
            GestureDetector(
              onTap: () async {
                // Don't send any message if _alreadySending or if message is empty
                if (_textInputValue.isEmpty || _alreadySending) return;
                _onSendHandler(context);
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12.0, horizontal: 14),
                child: Icon(
                  Icons.fast_forward,
                  color: Colors.black38,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
