import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_app/models/ChatRow.dart';
import 'package:social_app/models/MsgRow.dart';
import 'package:social_app/models/UserProfileObject.dart';
import 'package:social_app/modules/constants.dart';
import 'package:social_app/services/firestore_service.dart';
import 'package:social_app/services/rtd_service.dart';
import 'package:provider/provider.dart';

import '../modules/ChatBottomBar.dart';
import '../modules/MessageBubble.dart';

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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withOpacity(.02),
            width: 1.0,
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(10, 20 + MediaQuery.of(context).padding.top, 20, 10),
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Icon(
                Icons.arrow_back_ios_new_outlined,
                size: 18,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: <Widget>[
                Container(
                  height: 45,
                  width: 45,
                  margin: EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(10000),
                    border: Border.all(color: Colors.yellow, width: 2),
                  ),
                  child: otherUser.photoURL!.isNotEmpty
                      ? ClipRRect(
                          child: Image.network(
                            otherUser.photoURL!,
                            height: 45,
                            width: 45,
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(100)),
                        )
                      : Container(
                          height: 45,
                          width: 45,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(.07),
                            borderRadius: BorderRadius.circular(10000),
                          ),
                        ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherUser.displayName!,
                      style: TextStyle(fontFamily: HelveticaFont.Medium, fontSize: 16, color: Colors.black),
                    ),
                    Text("@" + otherUser.userName!, style: TextStyle(fontFamily: HelveticaFont.Roman, fontSize: 14, color: Colors.black38))
                  ],
                ),
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
                          stream: context.watch<RealtimeDatabaseService>().getChatRoomMessagesStream(widget.chatRow!.chatRoomUid),
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
                                  ),
                                  SliverToBoxAdapter(
                                    child: _msgRows.length == 0 &&
                                            !widget.chatRow!.blockedByThisUser! &&
                                            !widget.chatRow!.requestedByOtherUser!
                                        ? Center(
                                            child: Padding(
                                              padding: const EdgeInsets.all(20.0),
                                              child: Text(
                                                "This contact has been accepted, you can now start messaging",
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          )
                                        : SizedBox(),
                                  ),
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
              setChatRoomUid: (
                String chatRoomUid,
              ) {
                setState(() {
                  widget.chatRow = ChatRow(chatRoomUid: chatRoomUid, otherUser: widget.otherUser);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
