import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_app/models/ChatRow.dart';
import 'package:social_app/models/MsgRow.dart';
import 'package:social_app/models/MyUserObject.dart';
import 'package:social_app/services/rtd_service.dart';
import 'package:provider/provider.dart';

const kMessageTextFieldDecoration = InputDecoration(
  contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
  hintText: 'Type your message here...',
  hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 14),
  border: InputBorder.none,
);

AppBar chatTopBar(MyUserObject otherUser) => AppBar(
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
                otherUser.displayName,
                style: TextStyle(
                    fontFamily: 'Poppins', fontSize: 14, color: Colors.black),
              ),
              Text("@" + otherUser.userName,
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: Colors.black54))
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
  ChatRoomPage({this.chatRow, this.otherUser});
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
    if (chatRoomMsgsObject != null)
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
    if (widget.chatRow != null) {
      _chatRoomUid = widget.chatRow.chatRoomUid;
    }
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
        appBar: chatTopBar(widget.otherUser),
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
                rootContext: context,
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
  BuildContext _rootContext;
  String _chatRoomUid;
  User _currentUser;
  MyUserObject _otherUser;
  Function _setChatRoomUid;
  ChatBottomBar(
      {Key key,
      String chatRoomUid,
      User currentUser,
      MyUserObject otherUser,
      Function setChatRoomUid,
      BuildContext rootContext})
      : _chatRoomUid = chatRoomUid,
        _currentUser = currentUser,
        _otherUser = otherUser,
        _setChatRoomUid = setChatRoomUid,
        _rootContext = rootContext,
        super(key: key);

  final chatMsgTextController = TextEditingController();
  String _textInputValue = "";
  bool _alreadySending = false;

  Future _createRequestAndSendMsg(context) async {
    print("Need to create a new requestedUserChats doc and send message");

    try {
      final Map<String, String> response = await _rootContext
          .read<RealtimeDatabaseService>()
          .createRequestedUserChats(
              otherUserObject: _otherUser, currentUser: _currentUser);

      if (response['status'] == "success" && response["chatRoomUid"] != null) {
        // Successfully created new requestedUserChat
        print(
            'Successfully created requestedUserChats (${response["chatRoomUid"]}) document and sent message');
        // Set the newly created chatRoomUid
        _chatRoomUid = response["chatRoomUid"];
        _setChatRoomUid(response["chatRoomUid"]);
        // Lastly send the message
        _sendMessageToChatRoom(context);
      } else {
        Scaffold.of(context).showSnackBar(SnackBar(
          content: Text("Error: " + response["errorMsg"]),
        ));
      }
    } catch (e) {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text("Unable to send the message to the user currently"),
      ));
      throw e;
    }
  }

  Future _sendMessageToChatRoom(context) async {
    print("Sending message to the user");
    await _rootContext.read<RealtimeDatabaseService>().sendMessageInRoom(
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
      await _createRequestAndSendMsg(context);
    } else {
      // Send a message to the chatRoomUid
      await _sendMessageToChatRoom(context);
    }
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
                controller: chatMsgTextController,
                decoration: kMessageTextFieldDecoration,
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
