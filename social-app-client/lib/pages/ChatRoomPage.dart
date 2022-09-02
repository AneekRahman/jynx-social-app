import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:social_app/models/ChatRow.dart';
import 'package:social_app/models/MsgRow.dart';
import 'package:social_app/models/UserProfileObject.dart';
import 'package:social_app/modules/constants.dart';
import 'package:social_app/services/firestore_service.dart';
import 'package:social_app/services/rtd_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../modules/ChatBottomBar.dart';
import '../modules/MessageBubble.dart';
import 'OthersProfilePage.dart';

GlobalKey<_ChatRequestActionsState> _chatRequestActionsGlobalKey = GlobalKey<_ChatRequestActionsState>();

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
          _buildOtherUserPicNamesRow(context),
          chatRow != null
              ? PopupMenuButton(
                  itemBuilder: (ctx) => [
                    _buildPopupMenuItem(context, 'View profile', Icons.person_outline, 1),
                    _buildPopupMenuItem(context, 'Copy username', Icons.copy, 2),
                    _buildPopupMenuItem(context, chatRow!.blockedByThisUser! ? 'Unblock user' : "Block user", Icons.person_off, 3),
                  ],
                )
              : SizedBox(),
        ],
      ),
    );
  }

  PopupMenuItem _buildPopupMenuItem(BuildContext context, String title, IconData iconData, int position) {
    return PopupMenuItem(
      onTap: () {
        if (position == 1) _showOtherUsersProfileModal(context);
        if (position == 2) Clipboard.setData(ClipboardData(text: otherUser.userName));
        if (position == 3) _chatRequestActionsGlobalKey.currentState!.blockUnblockUser();
      },
      value: position,
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
        ),
      ),
    );
  }

  Expanded _buildOtherUserPicNamesRow(BuildContext context) {
    return Expanded(
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: () {
              _showOtherUsersProfileModal(context);
            },
            child: Container(
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
          ),
          Expanded(
            child: TextButton(
              style: ButtonStyle(
                alignment: Alignment.centerLeft,
                padding: MaterialStatePropertyAll(EdgeInsets.all(0)),
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
                    style: TextStyle(fontFamily: HelveticaFont.Medium, fontSize: 16, color: Colors.black),
                  ),
                  Text(
                    "@" + otherUser.userName!,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: HelveticaFont.Roman, fontSize: 14, color: Colors.black38),
                  ),
                ],
              ),
            ),
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
  ChatRequestActions({Key? key, required this.currentUser, required this.chatRow}) : super(key: key);
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
      await context.read<FirestoreService>().acceptChatUserRequest(
          context.read<RealtimeDatabaseService>(), widget.chatRow.chatRoomUid, widget.currentUser.uid, widget.chatRow.otherUser.userUid);
      // Update the UI
      setState(() => widget.chatRow.requestedByOtherUser = false);
    } catch (e) {
      throw e;
    }
    // Update the UI
    setState(() => _loading = false);
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
                          blockUnblockUser();
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
