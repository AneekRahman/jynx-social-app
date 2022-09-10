import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:social_app/models/ChatRow.dart';
import 'package:social_app/models/MsgRow.dart';
import 'package:social_app/models/UserFirestore.dart';
import 'package:social_app/modules/constants.dart';
import 'package:social_app/pages/VideoCallPage.dart';
import 'package:social_app/services/firestore_service.dart';
import 'package:social_app/services/rtd_service.dart';
import 'package:provider/provider.dart';

import '../modules/ChatBottomBar.dart';
import '../modules/MessageBubble.dart';
import 'OthersProfilePage.dart';

GlobalKey<_ChatRequestActionsState> _chatRequestActionsGlobalKey = GlobalKey<_ChatRequestActionsState>();

Center _buildLoadingAnim() {
  return Center(
    child: SizedBox(child: CircularProgressIndicator(), height: 25, width: 25),
  );
}

class ChatTopBar extends StatelessWidget {
  ChatRow? chatRow;
  UserFirestore otherUser;
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
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_outlined,
              size: 18,
            ),
          ),
          _buildOtherUserNamesRow(context),
          _buildUserPicActionsRow(context, chatRow),
        ],
      ),
    );
  }

  Row _buildUserPicActionsRow(BuildContext context, ChatRow? chatRow) {
    return Row(
      children: [
        chatRow != null
            ? IconButton(
                onPressed: () {
                  if (chatRow.requestedByThisUser != null && !chatRow.requestedByThisUser! && !chatRow.blockedByThisUser!) {
                    Navigator.push(context, CupertinoPageRoute(builder: (context) => VideoCallPage()));
                  } else {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text("The other user must accept your request before you can start a call!")));
                  }
                },
                icon: Image.asset("assets/icons/Call-icon.png", height: 24, width: 24),
              )
            : SizedBox(),
        PopupMenuButton(
          icon: Container(
            height: 45,
            width: 45,
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
          padding: EdgeInsets.all(0),
          onSelected: ((value) {
            if (value == 1) _showOtherUsersProfileModal(context);
            if (value == 2) Clipboard.setData(ClipboardData(text: otherUser.userName));
            if (value == 3 && _chatRequestActionsGlobalKey.currentState != null)
              _chatRequestActionsGlobalKey.currentState!.blockUnblockUser();
          }),
          itemBuilder: (ctx) => chatRow != null
              ? [
                  _buildPopupMenuItem(context, 'View profile', Icons.person_outline, 1),
                  _buildPopupMenuItem(context, 'Copy username', Icons.copy, 2),
                  _buildPopupMenuItem(context, chatRow.blockedByThisUser! ? 'Unblock user' : "Block user", Icons.person_off, 3),
                ]
              : [],
        ),
      ],
    );
  }

  PopupMenuItem _buildPopupMenuItem(BuildContext context, String title, IconData iconData, int value) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            iconData,
            color: Colors.black,
          ),
          SizedBox(width: 10),
          Text(title),
        ],
      ),
    );
  }

  void _showOtherUsersProfileModal(BuildContext context) {
    showMaterialModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) => Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: OthersProfilePage(
          otherUsersProfileObject: otherUser,
          showMessageButton: false,
        ),
      ),
    );
  }

  Expanded _buildOtherUserNamesRow(BuildContext context) {
    return Expanded(
      child: TextButton(
        style: ButtonStyle(
          alignment: Alignment.centerLeft,
          padding: MaterialStatePropertyAll(EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
        ),
        onPressed: () {
          _showOtherUsersProfileModal(context);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              otherUser.displayName!,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: HelveticaFont.Medium, fontSize: 14, color: Colors.black),
            ),
            Text(
              "@" + otherUser.userName!,
              // "Last message " + convertToTimeAgo(new DateTime.fromMillisecondsSinceEpoch(int.parse(chatRow!.lastMsgSentTime!))) + " ago",
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: HelveticaFont.Roman, fontSize: 12, color: Colors.black38),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatRoomPage extends StatefulWidget {
  ChatRow? chatRow;
  UserFirestore otherUser;
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
    // if (widget.chatRow == null) {
    //   // Search for an already made private chatroom for these 2 users
    //   ChatRow? chatRow = await context.read<FirestoreService>().findPrivateChatWithUser(_currentUser.uid, widget.otherUser.userUid);
    //   print(chatRow);
    //   if (chatRow != null) {
    //     setState(() {
    //       widget.chatRow = chatRow;
    //     });
    //   }
    // }

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
      child: Theme(
        data: ThemeData.light(),
        child: Scaffold(
          body: StreamBuilder(
              stream: widget.chatRow != null ? context.watch<FirestoreService>().getChatRoomStream(widget.chatRow!.chatRoomUid) : null,
              builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                if (snapshot.hasData) {
                  widget.chatRow = makeChatRowFromUserChats(snapshot.data, _currentUser.uid, false)!;
                }

                return Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    ChatTopBar(
                      chatRow: widget.chatRow,
                      otherUser: widget.chatRow != null ? widget.chatRow!.otherUser : widget.otherUser,
                    ),
                    !_initializingChatRoom
                        ? widget.chatRow != null
                            ? _buildMessagesStreamBuilder(context)
                            : Center(child: Text("You haven't messaged yet!"))
                        : _buildLoadingAnim(),
                    widget.chatRow != null
                        ? ChatRequestActions(
                            key: _chatRequestActionsGlobalKey,
                            chatRow: widget.chatRow!,
                            currentUser: _currentUser,
                          )
                        : Container(),
                    ChatBottomBar(
                      rootContext: context,
                      chatRow: widget.chatRow,
                      currentUser: _currentUser,
                      otherUser: widget.otherUser,
                      setNewChatRoomUid: (String chatRoomUid) {
                        setState(() {
                          widget.chatRow = ChatRow(
                            chatRoomUid: chatRoomUid,
                            otherUser: widget.otherUser,
                            requestedByOtherUser: false,
                            blockedByThisUser: false,
                          );
                        });
                      },
                    ),
                  ],
                );
              }),
        ),
      ),
    );
  }

  Expanded _buildMessagesStreamBuilder(BuildContext context) {
    return Expanded(
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
                      // REMEBER!! _msgRows is a REVERSED array!!!

                      // Check if previous message was also from the same user
                      bool nextMsgSameUser = true;
                      if (index == 0 || _msgRows.elementAt(index - 1).userUid != msgRow.userUid) {
                        nextMsgSameUser = false;
                      }
                      // Check if next post message is also from the same user
                      bool prevMsgSameUser = true;
                      if (_msgRows.length - 1 == index || _msgRows.elementAt(index + 1).userUid != msgRow.userUid) {
                        prevMsgSameUser = false;
                      }

                      return MessageBubble(
                        msgRow: msgRow,
                        isUsersMsg: msgRow.userUid == _currentUser.uid,
                        prevMsgSameUser: prevMsgSameUser,
                        nextMsgSameUser: nextMsgSameUser,
                      );
                    },
                    childCount: _msgRows.length,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _msgRows.length == 0 && !widget.chatRow!.blockedByThisUser! && !widget.chatRow!.requestedByOtherUser!
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
    );
  }
}

class ChatRequestActions extends StatefulWidget {
  User currentUser;
  ChatRow chatRow;
  ChatRequestActions({Key? key, required this.currentUser, required this.chatRow}) : super(key: key);

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
      await context.read<FirestoreService>().acceptChatUserRequest(
          context.read<RealtimeDatabaseService>(), widget.chatRow.chatRoomUid, widget.currentUser.uid, widget.chatRow.otherUser.userUid);
    } catch (e) {
      throw e;
    }
    // Update the UI
    if (mounted) setState(() => _loading = false);
  }

  Future blockUnblockUser() async {
    if (_loading || widget.chatRow.chatRoomUid == null) return;
    setState(() => _loading = true);
    try {
      if (!widget.chatRow.blockedByThisUser!) {
        // Block in Firestore
        await context
            .read<FirestoreService>()
            .blockUser(userChatsDocumentUid: widget.chatRow.chatRoomUid, blockedUserUid: widget.chatRow.otherUser.userUid);
        // In Database
        await context.read<RealtimeDatabaseService>().blockInRTDatabase(widget.chatRow.chatRoomUid, widget.chatRow.otherUser.userUid);
      } else {
        // Unblock in Firestore
        await context
            .read<FirestoreService>()
            .unblockUser(userChatsDocumentUid: widget.chatRow.chatRoomUid, blockedUserUid: widget.chatRow.otherUser.userUid);
        // In Database
        await context.read<RealtimeDatabaseService>().unBlockInRTDatabase(widget.chatRow.chatRoomUid, widget.chatRow.otherUser.userUid);
      }
    } catch (e) {
      throw e;
    }
    // Update the UI
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
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
                            color: const Color(0xFF3EC2F9),
                            border: Border.all(color: Colors.black12, width: 1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                          child: Text(
                            "Accept Request",
                            style: TextStyle(
                              fontFamily: HelveticaFont.Bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          blockUnblockUser();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            border: Border.all(color: Colors.black12, width: 1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                          child: Text(
                            widget.chatRow.blockedByThisUser! ? "Unblock User" : "Block User",
                            style: TextStyle(
                              fontFamily: HelveticaFont.Bold,
                              color: Colors.white,
                            ),
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
      return SizedBox();
    }
  }
}
