import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_app/models/ChatRow.dart';
import 'package:social_app/models/MsgRow.dart';
import 'package:social_app/models/MyUserObject.dart';
import 'package:social_app/modules/constants.dart';
import 'package:social_app/services/firestore_service.dart';
import 'package:social_app/services/rtd_service.dart';
import 'package:provider/provider.dart';

const kMessageTextFieldDecoration = InputDecoration(
  contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
  hintText: 'Type your message here...',
  hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 14),
  border: InputBorder.none,
);

Center _buildLoadingAnim() {
  return Center(
    child: SizedBox(child: CircularProgressIndicator(), height: 25, width: 25),
  );
}

class ChatTopBar extends StatelessWidget {
  ChatRow chatRow;
  MyUserObject otherUser;
  ChatTopBar({this.chatRow, this.otherUser});

  final double _padding = 20;

  @override
  Widget build(BuildContext context) {
    String name = "";
    String userName = "";
    if (chatRow != null) name = chatRow.otherUsersName;
    if (otherUser != null) name = otherUser.displayName;
    if (chatRow != null) userName = chatRow.otherUsersUserName;
    if (otherUser != null) userName = otherUser.userName;

    return Padding(
      padding: EdgeInsets.fromLTRB(_padding,
          _padding + MediaQuery.of(context).padding.top, _padding, _padding),
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                Icons.arrow_back_ios,
                size: 18,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name,
                  style: TextStyle(
                      fontFamily: HelveticaFont.Bold,
                      fontSize: 14,
                      color: Colors.black),
                ),
                Text("@" + userName,
                    style: TextStyle(
                        fontFamily: HelveticaFont.Bold,
                        fontSize: 10,
                        color: Colors.black38))
              ],
            ),
          ),
          GestureDetector(
            child: Icon(Icons.more_vert),
          ),
        ],
      ),
    );
  }
}

class ChatRoomPage extends StatefulWidget {
  ChatRow chatRow;
  MyUserObject otherUser;
  ChatRoomPage({this.chatRow, this.otherUser});
  @override
  _ChatRoomPageState createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  User _currentUser;
  List<MsgRow> _msgRows = [];
  bool _initializingChatRoom = true;

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

  void _initializeChatRoom() async {
    if (widget.chatRow == null) {
      // Search for an already made private chatroom for these 2 users
      ChatRow chatRow = await context
          .read<FirestoreService>()
          .findPrivateChatWithUser(_currentUser.uid, widget.otherUser.userUid);
      if (chatRow != null) widget.chatRow = chatRow;
    }

    // If chatRoom found, then make sure to update the seen of lastMsg if already not seen
    if (widget.chatRow != null &&
        widget.chatRow.chatRoomUid != null &&
        !widget.chatRow.seen) {
      context.read<FirestoreService>().setSeenUserChatsDocument(
          widget.chatRow.userChatsDocUid, _currentUser.uid);
      widget.chatRow.seen = true;
    }
    // Let the user now start chatting
    setState(() {
      _initializingChatRoom = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _currentUser = context.read<User>();
    _initializeChatRoom();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark),
      child: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ChatTopBar(
              chatRow: widget.chatRow,
              otherUser: widget.otherUser,
            ),
            widget.chatRow != null
                ? Expanded(
                    child: StreamBuilder(
                      stream: context
                          .watch<RealtimeDatabaseService>()
                          .getChatRoomStream(widget.chatRow.chatRoomUid),
                      builder: (context, AsyncSnapshot<Event> snapshot) {
                        if (snapshot.hasData &&
                            !snapshot.hasError &&
                            !_initializingChatRoom) {
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

                                    return MessageBubble(
                                      msgRow: msgRow,
                                      isUser:
                                          msgRow.userUid == _currentUser.uid,
                                      firstMsgOfUser: firstMsgOfUser,
                                    );
                                  },
                                  childCount: _msgRows.length,
                                ),
                              )
                            ],
                          );
                        } else {
                          return _buildLoadingAnim();
                        }
                      },
                    ),
                  )
                : _buildLoadingAnim(),
            ChatRequestActions(
              chatRow: widget.chatRow,
              currentUser: _currentUser,
            ),
            ChatBottomBar(
                rootContext: context,
                chatRow: widget.chatRow,
                currentUser: _currentUser,
                otherUser: widget.otherUser,
                setChatRoomUid: (String chatRoomUid) {
                  setState(() {
                    widget.chatRow.chatRoomUid = chatRoomUid;
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
                  : BorderSide(color: Colors.redAccent, width: 4),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          child: Text(
            msgRow.msg,
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

class ChatBottomBar extends StatelessWidget {
  BuildContext rootContext;
  ChatRow chatRow;
  User currentUser;
  MyUserObject otherUser;
  Function setChatRoomUid;
  ChatBottomBar(
      {Key key,
      this.chatRow,
      this.currentUser,
      this.otherUser,
      this.setChatRoomUid,
      this.rootContext})
      : super(key: key);

  final chatMsgTextController = TextEditingController();
  String _textInputValue = "";
  bool _alreadySending = false;

  Future _createRequestAndSendMsg(context) async {
    try {
      final Map<String, String> response = await rootContext
          .read<FirestoreService>()
          .createRequestedUserChats(
              otherUserObject: otherUser, currentUser: currentUser);

      if (response['status'] == "success" && response["chatRoomUid"] != null) {
        // Successfully created new requestedUserChat
        chatRow.chatRoomUid = response["chatRoomUid"];
        // Set the newly created chatRoomUid
        setChatRoomUid(response["chatRoomUid"]);
        // Lastly send the message
        await _sendMessageToChatRoom(context);
      } else {
        Scaffold.of(context).showSnackBar(SnackBar(
          content: Text("There was a network issue while sending a message"),
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
    try {
      int lastMsgSentTime = new DateTime.now().millisecondsSinceEpoch;
      // Send a message in the RealtimeDatabase chatRoom
      rootContext.read<RealtimeDatabaseService>().sendMessageInRoom(
        chatRow.chatRoomUid,
        {
          "msg": _textInputValue,
          "sentTime": lastMsgSentTime,
          "userUid": currentUser.uid
        },
      );
      // Update the userChats document and reset the lastMsgSeen array and sentTime
      rootContext.read<FirestoreService>().setNewMsgUserChatsSeenReset(
            chatRow.chatRoomUid,
            currentUser.uid,
            lastMsgSentTime.toString(),
          );
    } catch (e) {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text("There was a network issue while sending the message"),
      ));
    }
  }

  void _onSendHandler(context) async {
    if (_alreadySending) return;
    _alreadySending = true;

    if (chatRow.chatRoomUid == null) {
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
                style: TextStyle(fontFamily: HelveticaFont.Roman),
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

class ChatRequestActions extends StatefulWidget {
  ChatRequestActions({this.currentUser, this.chatRow});
  User currentUser;
  ChatRow chatRow;

  @override
  _ChatRequestActionsState createState() => _ChatRequestActionsState();
}

class _ChatRequestActionsState extends State<ChatRequestActions> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    if (widget.chatRow == null || !widget.chatRow.requested) return Container();

    if (widget.chatRow.requested)
      return Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 10),
            height: 1,
            width: MediaQuery.of(context).size.width,
            color: Color(0xFFF1F1F1F1),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: !_loading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          if (_loading || widget.chatRow.chatRoomUid == null)
                            return;
                          setState(() => _loading = true);
                          try {
                            // Accept the request
                            await context
                                .read<FirestoreService>()
                                .acceptChatUserRequest(
                                    widget.chatRow.userChatsDocUid,
                                    widget.currentUser.uid);
                            // Update the UI
                            setState(() => widget.chatRow.requested = false);
                          } catch (e) {}
                          // Update the UI
                          setState(() => _loading = false);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black12, width: 1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 24),
                          child: Text(
                            "Accept Request",
                            style: TextStyle(fontFamily: HelveticaFont.Bold),
                          ),
                        ),
                      ),
                      GestureDetector(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black12, width: 1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 24),
                          child: Text(
                            "Block messages",
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
  }
}
