import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_app/models/ChatRow.dart';
import 'package:social_app/models/MsgRow.dart';
import 'package:social_app/models/UserProfileObject.dart';
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
  ChatRow? chatRow;
  UserProfileObject otherUser;
  ChatTopBar({this.chatRow, required this.otherUser});

  final double _padding = 20;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(_padding, _padding + MediaQuery.of(context).padding.top, _padding, _padding),
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
                  otherUser.displayName!,
                  style: TextStyle(fontFamily: HelveticaFont.Bold, fontSize: 14, color: Colors.black),
                ),
                Text("@" + otherUser.userName!, style: TextStyle(fontFamily: HelveticaFont.Bold, fontSize: 10, color: Colors.black38))
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
  ChatRow? chatRow;
  UserProfileObject otherUser;
  ChatRoomPage({this.chatRow, required this.otherUser});
  @override
  _ChatRoomPageState createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  late User _currentUser;
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
        print("GOT: ${key}");
        MsgRow msgRow = MsgRow.fromJson({...chatRoomMsgsObject[key], 'msgUid': key});
        _removeIfAlreadyAdded(msgRow);
        _msgRows.add(msgRow);
      });

    // Sort the first 10 results on the client side as well
    _msgRows.sort((a, b) => b.sentTime!.compareTo(a.sentTime!));
  }

  void _initializeChatRoom() async {
    if (widget.chatRow == null) {
      // Search for an already made private chatroom for these 2 users
      ChatRow? chatRow = await context.read<FirestoreService>().findPrivateChatWithUser(_currentUser.uid, widget.otherUser.userUid);
      print(chatRow);
      if (chatRow != null) {
        setState(() {
          widget.chatRow = chatRow;
        });
      }
    }

    // If chatRoom found, then make sure to update the seen of lastMsg if already not seen
    if (widget.chatRow != null && widget.chatRow!.chatRoomUid != null && !widget.chatRow!.seen!) {
      context.read<FirestoreService>().setSeenUserChatsDocument(widget.chatRow!.chatRoomUid, _currentUser.uid);
      widget.chatRow!.seen = true;
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
      value: const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark),
      child: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ChatTopBar(
              chatRow: widget.chatRow,
              otherUser: widget.otherUser,
            ),
            !_initializingChatRoom
                ? widget.chatRow != null
                    ? Expanded(
                        child: StreamBuilder(
                          stream: context.watch<RealtimeDatabaseService>().getChatRoomStream(widget.chatRow!.chatRoomUid),
                          builder: (context, AsyncSnapshot snapshot) {
                            if (snapshot.hasData && !snapshot.hasError) {
                              _setMsgRowsFromStream(snapshot.data!.snapshot.value);

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
                                        if (index == 0 || _msgRows.elementAt(index - 1).msgUid == _currentUser.uid) {
                                          firstMsgOfUser = false;
                                        }

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
                            } else if (snapshot.hasError) {
                              return Center(child: Text("Error! Go back and reload the page!"));
                            } else {
                              return _buildLoadingAnim();
                            }
                          },
                        ),
                      )
                    : Center(child: Text("You haven't messaged yet!"))
                : _buildLoadingAnim(),
            ChatBottomBar(
                rootContext: context,
                chatRow: widget.chatRow,
                currentUser: _currentUser,
                otherUser: widget.otherUser,
                setChatRoomUid: (String chatRoomUid) {
                  setState(() {
                    widget.chatRow = ChatRow(chatRoomUid: chatRoomUid, otherUser: widget.otherUser);
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

class ChatBottomBar extends StatefulWidget {
  BuildContext rootContext;
  ChatRow? chatRow;
  User currentUser;
  UserProfileObject otherUser;
  Function setChatRoomUid;
  ChatBottomBar(
      {Key? key, this.chatRow, required this.currentUser, required this.otherUser, required this.setChatRoomUid, required this.rootContext})
      : super(key: key);

  @override
  State<ChatBottomBar> createState() => _ChatBottomBarState();
}

class _ChatBottomBarState extends State<ChatBottomBar> {
  final chatMsgTextController = TextEditingController();
  String _textInputValue = "";
  bool _alreadySending = false;

  Future _createRequestAndSendMsg(context) async {
    try {
      final String chatRoomUid = await widget.rootContext
          .read<FirestoreService>()
          .createRequestedUserChats(otherUserObject: widget.otherUser, currentUser: widget.currentUser);

      // Successfully created new requestedUserChat
      widget.chatRow = ChatRow(chatRoomUid: chatRoomUid, otherUser: widget.otherUser);
      // Set the newly created chatRoomUid
      widget.setChatRoomUid(chatRoomUid);
      // Lastly send the message
      await _sendMessageToChatRoom(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Unable to send the message to the user currently"),
      ));
      throw e;
    }
  }

  Future _sendMessageToChatRoom(context) async {
    try {
      int lastMsgSentTime = new DateTime.now().millisecondsSinceEpoch;
      // Send a message in the RealtimeDatabase chatRoom
      widget.rootContext.read<RealtimeDatabaseService>().sendMessageInRoom(
        widget.chatRow!.chatRoomUid,
        {"msg": _textInputValue, "sentTime": lastMsgSentTime, "userUid": widget.currentUser.uid},
      );
      // Update the userChats document and reset the lastMsgSeen array and sentTime
      widget.rootContext.read<FirestoreService>().setNewMsgUserChatsSeenReset(
            widget.chatRow!.chatRoomUid,
            widget.currentUser.uid,
            lastMsgSentTime.toString(),
          );
      // If the chat is still in a requested one
      if (widget.chatRow!.requestedByOtherUser != null && widget.chatRow!.requestedByOtherUser!) {
        // Accept the request
        await widget.rootContext
            .read<FirestoreService>()
            .acceptChatUserRequest(widget.chatRow!.chatRoomUid, widget.currentUser.uid, widget.chatRow!.otherUser.userUid);
        // Update the UI
        setState(() => widget.chatRow!.requestedByOtherUser = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("There was a network issue while sending the message"),
      ));
      throw e;
    }
  }

  void _onSendHandler(context) async {
    if (_alreadySending) return;
    _alreadySending = true;

    if (widget.chatRow != null) {
      await _sendMessageToChatRoom(context);
    } else {
      // Send a message to the chatRoomUid
      await _createRequestAndSendMsg(context);
    }
    _alreadySending = false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        widget.chatRow != null
            ? ChatRequestActions(
                chatRow: widget.chatRow!,
                currentUser: widget.currentUser,
              )
            : Container(),
        Container(
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
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 14),
                    child: Icon(
                      Icons.fast_forward,
                      color: Colors.black38,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ChatRequestActions extends StatefulWidget {
  ChatRequestActions({required this.currentUser, required this.chatRow});
  User currentUser;
  ChatRow chatRow;

  @override
  _ChatRequestActionsState createState() => _ChatRequestActionsState();
}

class _ChatRequestActionsState extends State<ChatRequestActions> {
  bool _loading = false;

  Future _acceptRequest() async {
    if (_loading || widget.chatRow.chatRoomUid == null) return;
    setState(() => _loading = true);
    try {
      // Accept the request
      await context
          .read<FirestoreService>()
          .acceptChatUserRequest(widget.chatRow.chatRoomUid, widget.currentUser.uid, widget.chatRow.otherUser.userUid);
      // Update the UI
      setState(() => widget.chatRow.requestedByOtherUser = false);
    } catch (e) {
      throw e;
    }
    // Update the UI
    setState(() => _loading = false);
  }

  Future _blockUnblockUser() async {
    if (_loading || widget.chatRow.chatRoomUid == null) return;
    setState(() => _loading = true);
    try {
      // Accept the request
      if (!widget.chatRow.blockedByThisUser!) {
        await context
            .read<FirestoreService>()
            .blockUser(userChatsDocumentUid: widget.chatRow.chatRoomUid, blockedUserUid: widget.chatRow.otherUser.userUid);
      } else {
        await context
            .read<FirestoreService>()
            .unblockUser(userChatsDocumentUid: widget.chatRow.chatRoomUid, blockedUserUid: widget.chatRow.otherUser.userUid);
      }
      // Update the UI
      setState(() {
        widget.chatRow.blockedByThisUser = !widget.chatRow.blockedByThisUser!;
      });
    } catch (e) {
      throw e;
    }
    // Update the UI
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.chatRow.requestedByOtherUser == null || !widget.chatRow.requestedByOtherUser!) return Container();

    if (widget.chatRow.requestedByOtherUser! || widget.chatRow.blockedByThisUser!) {
      return Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 10),
            height: 1,
            width: MediaQuery.of(context).size.width,
            color: Color(0xFFF1F1F1F1),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text(
              widget.chatRow.blockedByThisUser!
                  ? "You have blocked this user and they will not be able to message you."
                  : "This message will be moved to your chat list when you accept it or reply here.",
              style: TextStyle(fontFamily: HelveticaFont.Light),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: !_loading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () {
                          _acceptRequest();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black12, width: 1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                          child: Text(
                            "Accept Request",
                            style: TextStyle(fontFamily: HelveticaFont.Bold),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _blockUnblockUser();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black12, width: 1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                          child: Text(
                            widget.chatRow.blockedByThisUser! ? "Unblock User" : "Block User",
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
    } else {
      return Container();
    }
  }
}
