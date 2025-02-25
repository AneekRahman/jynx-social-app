import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:social_app/models/ChatRoomsInfos.dart';
import 'package:social_app/models/UserFirestore.dart';
import 'package:social_app/services/firestore_service.dart';
import 'package:social_app/services/rtd_service.dart';

import '../../models/MsgRow.dart';
import '../../modules/LoadingBar.dart';
import '../../modules/ChatMessageRoom/MessageBubble.dart';
import '../../modules/constants.dart';
import '../ProfilePage/OthersProfilePage.dart';
import 'VideoCallPage.dart';

class ChatMessageRoom extends StatefulWidget {
  /// If [chatRoomsInfos] is null, then either [otherUser] or [chatRoomsInfosUid] must be present
  /// If [otherUser] is null, then [chatRoomsInfos] must be present
  ChatRoomsInfos? chatRoomsInfos;
  String? chatRoomsUid;
  UserFirestore? otherUser;
  final bool fromRequestList;

  ChatMessageRoom({
    super.key,
    required this.fromRequestList,
    this.chatRoomsInfos,
    this.chatRoomsUid,
    this.otherUser,
  });

  @override
  State<ChatMessageRoom> createState() => _ChatMessageRoomState();
}

class _ChatMessageRoomState extends State<ChatMessageRoom> {
  bool noChatRoomFound = false;
  bool isGroupChat = false;
  bool otherUserBlockedInPrivateChat = false;
  StreamSubscription<DatabaseEvent>? _chatRoomsMembersListener;
  late final User currentUser;

  /// In order to make sure there is always an other user, when [isGroupChat] is false, this [otherPrivateChatRoomUser] is
  /// initialized inside [initState] once if [widget.chatRoomsInfos] is not null. If [widget.chatRoomsInfos] is null then
  /// [otherPrivateChatRoomUser] is initialized after [findPrivateChatRoomsInFirestore] finds a private chatRoom
  ChatRoomsInfosMem? otherPrivateChatRoomUser;

  /// Listen to /chatRooms/[chatRoomUid]/members/ if [isGroupChat] is Private to see if otherUser was blocked by currentUser
  void _initChatRoomsMembersListener() {
    _chatRoomsMembersListener =
        context.read<RealtimeDatabaseService>().getChatRoomsMembersStream(widget.chatRoomsInfos!.chatRoomUid).listen((DatabaseEvent event) {
      if (event.snapshot.exists) {
        setState(() {
          bool? membersOtherUserValue = (event.snapshot.value as Map)[otherPrivateChatRoomUser!.userUid];
          otherUserBlockedInPrivateChat = membersOtherUserValue == false;
        });
      }
    });
  }

  /// This is called after [chatRoomsInfos] is not null. If [chatRoomsInfos] is available it will run right
  /// after the initState. If [chatRoomsInfos] is null, it will run after [getChatRoomInfos] finds a chatRoomsInfos.
  Future _initChatRoomWithInfos() async {
    // Check if this chatRooms is a Group chat or Private
    if (!widget.chatRoomsInfos!.grp) {
      // This means that this is a private chat, so save the other user as a state
      widget.chatRoomsInfos!.mems.forEach((element) {
        if (currentUser.uid != element.userUid) {
          otherPrivateChatRoomUser = element;
        }
      });

      // Since this is a private group, check if otherUser is blocked by listening to /members/ stream
      _initChatRoomsMembersListener();
    } else {
      // This means that this is a group chat
      // TODO Finish the group chat initilization
      isGroupChat = true;
    }

    // Check if the chat was not seen (0 == NOT SEEN) yet by this [currentUser]. If not seen then set it as seen
    if (widget.chatRoomsInfos!.seenByThisUser == 0) {
      await context.read<RealtimeDatabaseService>().setMessageAsSeen(
            chatRoomUid: widget.chatRoomsInfos!.chatRoomUid,
            userUid: currentUser.uid,
            fromRequestList: widget.fromRequestList,
          );
    }
  }

  /// When a [chatRoomUid] is found from either [findPrivateChatRoomsInFirestore] or the [setNewChatRoomUid] callback after creating a
  /// new request, use this method to fetch the new [ChatRoomsInfos] and set it in [ChatMessageRoom]
  Future getAndSetChatRoomsInfos(String chatRoomUid) async {
    final rtdSnapshot = await context.read<RealtimeDatabaseService>().getChatRoomsInfo(chatRoomUid: chatRoomUid);

    if (rtdSnapshot.exists) {
      widget.chatRoomsInfos = ChatRoomsInfos.fromMap(
        rtdSnapshot.value as Map,
        chatRoomUid: rtdSnapshot.key!,
      );
      // Finally initialize the chatRoom using the chatRoomsInfos
      _initChatRoomWithInfos();
      // Update the UI since [_initChatRoomWithInfos] doesn't update it
      if (mounted) setState(() {});
    }
  }

  /// When the [chatRoomsInfos] is null, use [otherPrivateChatRoomUser] to find the Private chatRoomsInfos from Firestore
  /// If none is found, set [noChatRoomFound] to true since both [widget.chatRoomsInfos] and [otherPrivateChatRoomUser] is null
  Future findPrivateChatRoomsInFirestore() async {
    final firestoreChatRecord = await context.read<FirestoreService>().findPrivateChatWithUser(
          currentUser.uid,
          otherPrivateChatRoomUser!.userUid,
        );

    if (firestoreChatRecord.docs.isNotEmpty) {
      await getAndSetChatRoomsInfos(firestoreChatRecord.docs[0].id);
    } else {
      if (mounted)
        setState(() {
          noChatRoomFound = true;
        });
    }
  }

  Future getChatRoomsInfosWithUid(String chatRoomsUid) async {
    final DataSnapshot chatRoomsInfosSnapshot = await context.read<RealtimeDatabaseService>().getChatRoomsInfo(chatRoomUid: chatRoomsUid);

    if (chatRoomsInfosSnapshot.exists) {
      widget.chatRoomsInfos = ChatRoomsInfos.fromMap(chatRoomsInfosSnapshot.value as Map, chatRoomUid: chatRoomsInfosSnapshot.key!);
      widget.chatRoomsInfos!.seenByThisUser = 0;
      // Finally initialize the chatRoom
      _initChatRoomWithInfos();
    }
  }

  /// Depending on [widget.chatRoomsInfos] being null or not. If [widget.chatRoomsInfos] is not null, the chatRoom can be
  /// either a group of not. [_initChatRoomWithInfos] is called to designate this [ChatMessageRoom] as [isGroupChat] or not
  /// [widget.chatRoomsInfos] is null. Then check to see if this chatRoom was searched and there is already a Private
  /// chatRoom for the [widget.otherUser]
  @override
  void initState() {
    currentUser = context.read<User>();
    if (widget.chatRoomsInfos == null) {
      // If [chatRoomsInfos] is null but [chatRoomsUid] is available
      if (widget.chatRoomsUid != null) {
        getChatRoomsInfosWithUid(widget.chatRoomsUid!);
      } else {
        // If neither [chatRoomsInfos] nor [chatRoomsUid] is available
        otherPrivateChatRoomUser = ChatRoomsInfosMem.fromUserFirestore(widget.otherUser!);
        findPrivateChatRoomsInFirestore();
      }
    } else {
      // If [chatRoomsInfos] available
      _initChatRoomWithInfos();
    }

    super.initState();
  }

  @override
  void dispose() {
    if (_chatRoomsMembersListener != null) _chatRoomsMembersListener!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          otherPrivateChatRoomUser != null
              ? ChatTopBar(
                  chatRoomsInfos: widget.chatRoomsInfos,
                  otherPrivateChatRoomUser: otherPrivateChatRoomUser!,
                  otherUserBlockedInPrivateChat: otherUserBlockedInPrivateChat,
                  rootContext: context,
                )
              : SizedBox(),
          // The mesasges list
          Expanded(
            child: widget.chatRoomsInfos != null
                ? MessagesStreamBuilder(
                    chatRoomUid: widget.chatRoomsInfos!.chatRoomUid,
                    currentUser: currentUser,
                    otherPrivateChatRoomUser: otherPrivateChatRoomUser!,
                  )
                : noChatRoomFound
                    ? Center(
                        child: Text("You haven't sent a message yet!"),
                      )
                    : Center(
                        child: Text("preparing..."),
                      ),
          ),
          otherPrivateChatRoomUser != null
              ? ChatBottomBar(
                  currentUser: currentUser,
                  fromRequestList: widget.fromRequestList,
                  chatRoomsInfos: widget.chatRoomsInfos,
                  otherUser: otherPrivateChatRoomUser!,
                  setNewChatRoomUid: (newChatRoomUid) {
                    getAndSetChatRoomsInfos(newChatRoomUid);
                  },
                )
              : SizedBox(),
        ],
      ),
    );
  }
}

class ChatTopBar extends StatelessWidget {
  /// [chatRoomsInfos] Might be null, but [otherPrivateChatRoomUser] will always be available. [otherPrivateChatRoomUser] is either
  /// passed directly from the previous page or derived from [chatRoomsInfos] if [otherPrivateChatRoomUser] is null to begin with.
  final ChatRoomsInfos? chatRoomsInfos;
  final ChatRoomsInfosMem otherPrivateChatRoomUser;
  final bool otherUserBlockedInPrivateChat;
  final BuildContext rootContext;

  ChatTopBar({
    super.key,
    this.chatRoomsInfos,
    required this.otherPrivateChatRoomUser,
    required this.otherUserBlockedInPrivateChat,
    required this.rootContext,
  });

  Future blockUnblockUser() async {
    if (otherUserBlockedInPrivateChat) {
      await rootContext.read<RealtimeDatabaseService>().unBlockInRTDatabase(
            chatRoomsInfos!.chatRoomUid,
            otherPrivateChatRoomUser.userUid,
          );
    } else {
      await rootContext.read<RealtimeDatabaseService>().blockInRTDatabase(
            chatRoomsInfos!.chatRoomUid,
            otherPrivateChatRoomUser.userUid,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(.14),
            width: 1.0,
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(10, 10 + MediaQuery.of(context).padding.top, 20, 10),
      child: Row(
        children: <Widget>[
          CupertinoButton(
            onPressed: () => Navigator.pop(context),
            child: Icon(
              CupertinoIcons.left_chevron,
              size: 18,
              color: Colors.yellow,
            ),
          ),
          _buildOtherUserNamesRow(context),
          _buildUserPicActionsRow(context, chatRoomsInfos),
        ],
      ),
    );
  }

  Row _buildUserPicActionsRow(BuildContext context, ChatRoomsInfos? chatRoomsInfos) {
    return Row(
      children: [
        // TODO Fix Video calling on custom TURN servers using COTURN (service)
        // chatRoomsInfos != null ? _buildCallButton(context, chatRoomsInfos) : SizedBox(),
        _buildPicDropMenu(context, chatRoomsInfos),
      ],
    );
  }

  IconButton _buildCallButton(BuildContext context, ChatRoomsInfos chatRoomsInfos) {
    return IconButton(
      onPressed: () {
        if (otherPrivateChatRoomUser.acc == 1) {
          Navigator.push(
              context,
              CupertinoPageRoute(
                  builder: (context) => VideoCallPage(
                        chatRoomsInfos: chatRoomsInfos,
                        shouldCreateOffer: true,
                      )));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(otherPrivateChatRoomUser.name + " hasn't accepted your request. Please try again later.")));
        }
      },
      icon: Image.asset("assets/icons/Call-icon.png", height: 24, width: 24),
    );
  }

  PopupMenuButton<Object?> _buildPicDropMenu(BuildContext context, ChatRoomsInfos? chatRoomsInfos) {
    return PopupMenuButton(
      icon: _buildOtherUsersProfilePic(),
      padding: EdgeInsets.all(0),
      onSelected: ((value) {
        if (value == 1) _showOtherUsersProfileModal(context);
        if (value == 2) blockUnblockUser();
      }),
      itemBuilder: (ctx) => chatRoomsInfos != null
          ? [
              _buildPopupMenuItem(context, 'Open Profile', CupertinoIcons.person, 1),
              _buildPopupMenuItem(context, otherUserBlockedInPrivateChat ? "Unblock user" : "Block user", null, 2),
            ]
          : [],
    );
  }

  Container _buildOtherUsersProfilePic() {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(10000),
        border: Border.all(color: Colors.yellow, width: 2),
      ),
      child: otherPrivateChatRoomUser.url.isNotEmpty
          ? ClipRRect(
              child: Image.network(
                otherPrivateChatRoomUser.url,
                height: 40,
                width: 40,
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.all(Radius.circular(100)),
            )
          : Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(.07),
                borderRadius: BorderRadius.circular(10000),
              ),
            ),
    );
  }

  PopupMenuItem _buildPopupMenuItem(BuildContext context, String title, IconData? iconData, int value) {
    return PopupMenuItem(
      value: value,
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          iconData == null ? SizedBox() : Icon(iconData),
          SizedBox(width: 10),
          Text(title),
          Divider(
            height: 1,
            color: Colors.white12,
          ),
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
          otherUsersProfileObject: UserFirestore.fromChatRoomsInfosMem(otherPrivateChatRoomUser),
          showMessageButton: false,
        ),
      ),
    );
  }

  Expanded _buildOtherUserNamesRow(BuildContext context) {
    return Expanded(
      child: CupertinoButton(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        alignment: Alignment.centerLeft,
        onPressed: () {
          _showOtherUsersProfileModal(context);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              otherPrivateChatRoomUser.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: HelveticaFont.Medium, fontSize: 14, color: Colors.white),
            ),
            Text(
              "@" + otherPrivateChatRoomUser.uName,
              // "Last message " + convertToTimeAgo(new DateTime.fromMillisecondsSinceEpoch(int.parse(chatRow!.lastMsgSentTime!))) + " ago",
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: HelveticaFont.Roman, fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class MessagesStreamBuilder extends StatefulWidget {
  /// [chatRoomUid] will not be null.
  final String chatRoomUid;
  final User currentUser;
  final ChatRoomsInfosMem otherPrivateChatRoomUser;
  const MessagesStreamBuilder({super.key, required this.chatRoomUid, required this.currentUser, required this.otherPrivateChatRoomUser});

  @override
  State<MessagesStreamBuilder> createState() => _MessagesStreamBuilderState();
}

class _MessagesStreamBuilderState extends State<MessagesStreamBuilder> {
  List<MsgRow> _msgRows = [];

  /// This is called right after the [StreamBuilder] gets some data.
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

  /// This is caled before [_setMsgRowsFromStream] adds new rows to the [_msgRows] in order to remove duplicate rows
  /// based on the [msgUid]
  void _removeIfAlreadyAdded(MsgRow msgRow) {
    for (int i = 0; i < _msgRows.length; i++) {
      MsgRow element = _msgRows.elementAt(i);
      if (element != null && msgRow.msgUid == element.msgUid) {
        final index = _msgRows.indexOf(element);
        _msgRows.removeAt(index);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: context.watch<RealtimeDatabaseService>().getChatRoomMessagesStream(widget.chatRoomUid),
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
                    if (index == 0 || _msgRows.elementAt(index - 1).userUid != msgRow.userUid || _msgRows.elementAt(index - 1).type != 0) {
                      nextMsgSameUser = false;
                    }
                    // Check if next post message is also from the same user
                    bool prevMsgSameUser = true;
                    if (_msgRows.length - 1 == index ||
                        _msgRows.elementAt(index + 1).userUid != msgRow.userUid ||
                        _msgRows.elementAt(index + 1).type != 0) {
                      prevMsgSameUser = false;
                    }

                    bool wasSentInTheSameDay = false;
                    if (0 == index) {
                    } else if (msgRow.sentTime! + 86400 > _msgRows.elementAt(index - 1).sentTime!) {
                      wasSentInTheSameDay = true;
                    }

                    return MessageBubble(
                      msgRow: msgRow,
                      wasSentInTheSameDay: wasSentInTheSameDay,
                      isUsersMsg: msgRow.userUid == widget.currentUser.uid,
                      prevMsgSameUser: prevMsgSameUser,
                      nextMsgSameUser: nextMsgSameUser,
                      otherUser: widget.otherPrivateChatRoomUser,
                    );
                  },
                  childCount: _msgRows.length,
                ),
              ),
            ],
          );
        } else if (snapshot.hasError) {
          /// When an error occurs.
          return Center(child: Text("Error! Go back and reload the page!"));
        } else {
          /// This is when the stream is still loading and hasn't fetched the data back
          return Center(
            child: SizedBox(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.yellow,
                ),
                height: 25,
                width: 25),
          );
        }
      },
    );
  }
}

class ChatBottomBar extends StatefulWidget {
  /// [chatRoomsInfos] might be null. Which means this is most probably a Private message.
  ///  In this case we have to create a request if a message is sent.
  ChatRoomsInfos? chatRoomsInfos;

  /// If this is a Private message then [otherUser] will not be null no matter what. But in the case of a Group message,
  /// [otherUser] will be null. For Group messages, only [chatRoomsInfos] will be needed.
  final ChatRoomsInfosMem otherUser;
  final User currentUser;
  bool fromRequestList;

  /// [setNewChatRoomUid] is the callback after a new Private request is created
  /// in order to send the new [chatRoomUid] to the [ChatMessageRoom] widget.
  Function setNewChatRoomUid;
  ChatBottomBar({
    required this.chatRoomsInfos,
    required this.otherUser,
    required this.currentUser,
    required this.fromRequestList,
    required this.setNewChatRoomUid,
  });

  @override
  State<ChatBottomBar> createState() => _ChatBottomBarState();
}

class _ChatBottomBarState extends State<ChatBottomBar> {
  final chatMsgTextController = TextEditingController();
  String _textInputValue = "";
  bool _alreadySending = false;
  bool _creatingNewChatRoom = false;

  Future createNewChatRoomAndSendMsg() async {
    if (_creatingNewChatRoom) return;
    setState(() {
      _creatingNewChatRoom = true;
    });
    try {
      // Create the chatRoom first in the Realtime Database and retrieve a new [chatRoomUid]
      final String chatRoomUid = await context
          .read<RealtimeDatabaseService>()
          .createNewRequest(currentUser: widget.currentUser, otherUser: widget.otherUser, msg: _textInputValue);

      // Next, create a chatRoomRecords in Firestore for searching purposes
      await context.read<FirestoreService>().createNewChatRoomRecords(
            chatRoomUid: chatRoomUid,
            isGroup: false,
            currentUserUid: widget.currentUser.uid,
            otherUserUid: widget.otherUser.userUid,
          );

      // Lastly, callback so that [ChatMessageRoom] can fetch the new ChatRoomsInfos from Realtime Database
      widget.setNewChatRoomUid(chatRoomUid);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Unable to message the user currently."),
      ));
    }
    setState(() {
      _creatingNewChatRoom = false;
    });
  }

  Future sendMessageToChatRoom() async {
    try {
      // Send a message in the RealtimeDatabase chatRoom
      await context.read<RealtimeDatabaseService>().sendMessageInRoom(
            chatRoomUid: widget.chatRoomsInfos!.chatRoomUid,
            msg: _textInputValue,
            userUid: widget.currentUser.uid,
          );

      // If this is [widget.fromRequestList] then DELETE this chatRoom entry from /requestedUsersChatRooms/
      if (widget.fromRequestList) {
        await context.read<RealtimeDatabaseService>().acceptChatRequest(
              chatRoomUid: widget.chatRoomsInfos!.chatRoomUid,
              currentUserUid: widget.currentUser.uid,
              otherUserUid: widget.otherUser.userUid,
            );
        // Update the UI and stop showing the [_buildRequestedNotice]
        setState(() {
          widget.fromRequestList = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("There was a network issue while sending the message. Try again!")));
      throw e;
    }
  }

  /// If [widget.chatRoomsInfos] is null then call [createNewChatRoomAndSendMsg] to create a new /chatRooms/, /chatRoomsInfos/, /usersChatRooms/
  /// If [widget.chatRoomsInfos] is not null, send a message in the /chatRooms/ and update lMsg and lTime in /chatRoomsInfos/, /usersChatRooms/
  void onSendHandler() async {
    if (_alreadySending) return;
    _alreadySending = true;

    if (widget.chatRoomsInfos != null) {
      /// Send a message to the already assigned [widget.chatRoomsInfos.chatRoomUid]
      await sendMessageToChatRoom();
    } else {
      /// Create a new request and then send the message using [createNewChatRoomAndSendMsg]
      await createNewChatRoomAndSendMsg();
    }
    _alreadySending = false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        widget.fromRequestList ? _buildRequestedNotice() : SizedBox(),
        LoadingBar(
          loading: _creatingNewChatRoom,
          barColor: Colors.lightBlue,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(width: 10),
            Container(
              margin: EdgeInsets.only(bottom: 20),
              child: CupertinoButton(
                padding: EdgeInsets.all(10),
                onPressed: () {},
                child: Image.asset("assets/icons/Camera-icon.png", height: 30, width: 30),
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width - 60,
              padding: EdgeInsets.symmetric(vertical: 18, horizontal: 10),
              child: Material(
                borderRadius: BorderRadius.circular(26),
                color: Colors.white10,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Container(
                        child: TextField(
                          maxLines: 5,
                          minLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                          style: TextStyle(fontFamily: HelveticaFont.Medium),
                          maxLength: 200,
                          controller: chatMsgTextController,
                          decoration: InputDecoration(
                            counterText: "",
                            contentPadding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),
                            hintText: 'Say hi...',
                            hintStyle: TextStyle(fontFamily: HelveticaFont.Medium, fontSize: 14),
                            border: InputBorder.none,
                          ),
                          onChanged: ((value) {
                            setState(() {
                              _textInputValue = value;
                            });
                          }),
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.all(10),
                      onPressed: () async {
                        // Save the input value
                        _textInputValue = chatMsgTextController.text;
                        // Reset the text input field
                        chatMsgTextController.clear();
                        // Don't send any message if _alreadySending or if message is empty
                        if (_textInputValue.isEmpty || _alreadySending) return;
                        onSendHandler();
                      },
                      child: Image.asset("assets/icons/Send-icon.png", height: 30, width: 30),
                    ),
                    SizedBox(width: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Container _buildRequestedNotice() {
    return Container(
      margin: EdgeInsets.fromLTRB(10, 10, 10, 0),
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.05),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Text(
        "This is a request message. You can reply to this message to accept it and it will be shown in your chats list.",
        style: TextStyle(
          fontFamily: HelveticaFont.Roman,
          fontSize: 12,
        ),
      ),
    );
  }
}
