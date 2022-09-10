import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:social_app/models/ChatRoomsInfos.dart';
import 'package:social_app/models/UserFirestore.dart';
import 'package:social_app/services/firestore_service.dart';
import 'package:social_app/services/rtd_service.dart';

import '../models/MsgRow.dart';
import '../modules/MessageBubble.dart';
import '../modules/constants.dart';
import 'OthersProfilePage.dart';

class ChatMessageRoom extends StatefulWidget {
  /// If [chatRoomsInfos] is null, then [otherPrivateChatRoomUser] must be present
  /// If [otherPrivateChatRoomUser] is null, then [chatRoomsInfos] must be present
  ChatRoomsInfos? chatRoomsInfos;
  ChatRoomsInfosMem? otherPrivateChatRoomUser;
  final User currentUser;

  ChatMessageRoom({
    super.key,
    this.chatRoomsInfos,
    required this.currentUser,
    this.otherPrivateChatRoomUser,
  });

  @override
  State<ChatMessageRoom> createState() => _ChatMessageRoomState();
}

class _ChatMessageRoomState extends State<ChatMessageRoom> {
  bool noChatRoomFound = false;
  bool isGroupChat = false;

  /// This is called after [chatRoomsInfos] is prepared. If [chatRoomsInfos] is available it will run right
  /// after the initState. If [chatRoomsInfos] is null, it will run after [getChatRoomInfos] finds a chatRoomsInfos.
  void _initChatRoomWithInfos() {
    if (!widget.chatRoomsInfos!.grp) {
      // This means that this is a private chat, so save the other user as a state
      widget.chatRoomsInfos!.mems.forEach((element) {
        if (widget.currentUser.uid != element.userUid) {
          widget.otherPrivateChatRoomUser = element;
        }
      });
    } else {
      // This means that this is a group chat
      isGroupChat = true;
    }
  }

  /// When a [chatRoomUid] is found from either [findChatRoomsInFirestore] or the [setNewChatRoomUid] callback after creating a
  /// new request, use this method to fetch the new [ChatRoomsInfos] and set it in [ChatMessageRoom]
  Future getAndSetChatRoomsInfos(String chatRoomUid) async {
    final rtdSnapshot = await context.read<RealtimeDatabaseService>().getChatRoomsInfoPromise(chatRoomUid: chatRoomUid);

    if (rtdSnapshot.exists) {
      widget.chatRoomsInfos = ChatRoomsInfos.fromMap(
        rtdSnapshot.value as Map,
        chatRoomUid: rtdSnapshot.key!,
      );
      // Finally initialize the chatRoom using the chatRoomsInfos
      _initChatRoomWithInfos();
      if (mounted) setState(() {});
    }
  }

  /// When the [chatRoomsInfos] is null, use [otherPrivateChatRoomUser] to find the chatRoomsInfos
  /// from Firestore. If none is found, set [noChatRoomFound] to true
  Future findChatRoomsInFirestore() async {
    final firestoreChatRecord = await context.read<FirestoreService>().findPrivateChatWithUser(
          widget.currentUser.uid,
          widget.otherPrivateChatRoomUser!.userUid,
        );

    if (firestoreChatRecord.docs.isNotEmpty) {
      print("GOT: findChatRoomsInFirestore: " + firestoreChatRecord.docs[0].id);
      await getAndSetChatRoomsInfos(firestoreChatRecord.docs[0].id);
    } else {
      if (mounted)
        setState(() {
          noChatRoomFound = true;
        });
    }
  }

  @override
  void initState() {
    if (widget.chatRoomsInfos == null) {
      findChatRoomsInFirestore();
    } else {
      _initChatRoomWithInfos();
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark),
      child: Theme(
        data: ThemeData.light(),
        child: Scaffold(
          body: Column(
            children: [
              ChatTopBar(
                chatRoomsInfos: widget.chatRoomsInfos,
                otherPrivateChatRoomUser: widget.otherPrivateChatRoomUser!,
              ),
              // The mesasges list
              Expanded(
                child: widget.chatRoomsInfos != null
                    ? MessagesStreamBuilder(
                        chatRoomUid: widget.chatRoomsInfos!.chatRoomUid,
                        currentUser: widget.currentUser,
                      )
                    : !noChatRoomFound
                        ? Center(
                            child: Text("preparing..."),
                          )
                        : Center(
                            child: Text("You haven't texted them yet!"),
                          ),
              ),
              ChatBottomBar(
                chatRoomsInfos: widget.chatRoomsInfos,
                otherUser: widget.otherPrivateChatRoomUser!,
                currentUser: widget.currentUser,
                setNewChatRoomUid: (newChatRoomUid) {
                  getAndSetChatRoomsInfos(newChatRoomUid);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatTopBar extends StatelessWidget {
  /// [chatRoomsInfos] Might be null, but [otherPrivateChatRoomUser] will always be available. [otherPrivateChatRoomUser] is either
  /// passed directly from the previous page or derived from [chatRoomsInfos] if [otherPrivateChatRoomUser] is null to begin with.
  ChatRoomsInfos? chatRoomsInfos;
  final ChatRoomsInfosMem otherPrivateChatRoomUser;

  ChatTopBar({
    super.key,
    this.chatRoomsInfos,
    required this.otherPrivateChatRoomUser,
  });

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
          _buildUserPicActionsRow(context, chatRoomsInfos),
        ],
      ),
    );
  }

  Row _buildUserPicActionsRow(BuildContext context, ChatRoomsInfos? chatRoomsInfos) {
    return Row(
      children: [
        chatRoomsInfos != null
            ? IconButton(
                onPressed: () {
                  // if (chatRow.requestedByThisUser != null && !chatRow.requestedByThisUser! && !chatRow.blockedByThisUser!) {
                  //   Navigator.push(context, CupertinoPageRoute(builder: (context) => VideoCallPage()));
                  // } else {
                  //   ScaffoldMessenger.of(context)
                  //       .showSnackBar(SnackBar(content: Text("The other user must accept your request before you can start a call!")));
                  // }
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
            child: otherPrivateChatRoomUser.url.isNotEmpty
                ? ClipRRect(
                    child: Image.network(
                      otherPrivateChatRoomUser.url,
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
            if (value == 2) Clipboard.setData(ClipboardData(text: otherPrivateChatRoomUser.uName));
            // if (value == 3 && _chatRequestActionsGlobalKey.currentState != null)
            //   _chatRequestActionsGlobalKey.currentState!.blockUnblockUser();
          }),
          itemBuilder: (ctx) => chatRoomsInfos != null
              ? [
                  _buildPopupMenuItem(context, 'View profile', Icons.person_outline, 1),
                  _buildPopupMenuItem(context, 'Copy username', Icons.copy, 2),
                  _buildPopupMenuItem(context, "Block user", Icons.person_off, 3),
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
          otherUsersProfileObject: UserFirestore.fromChatRoomsInfosMem(otherPrivateChatRoomUser),
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
              otherPrivateChatRoomUser.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: HelveticaFont.Medium, fontSize: 14, color: Colors.black),
            ),
            Text(
              "@" + otherPrivateChatRoomUser.uName,
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

class MessagesStreamBuilder extends StatefulWidget {
  /// [chatRoomUid] will not be null.
  final String chatRoomUid;
  final User currentUser;
  const MessagesStreamBuilder({super.key, required this.chatRoomUid, required this.currentUser});

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
                      isUsersMsg: msgRow.userUid == widget.currentUser.uid,
                      prevMsgSameUser: prevMsgSameUser,
                      nextMsgSameUser: nextMsgSameUser,
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
  late ChatRoomsInfosMem otherUser;
  late User currentUser;

  /// [setNewChatRoomUid] is the callback after a new Private request is created
  /// in order to send the new [chatRoomUid] to the [ChatMessageRoom] widget.
  Function setNewChatRoomUid;
  ChatBottomBar({
    required this.chatRoomsInfos,
    required this.currentUser,
    required this.otherUser,
    required this.setNewChatRoomUid,
  });

  @override
  State<ChatBottomBar> createState() => _ChatBottomBarState();
}

class _ChatBottomBarState extends State<ChatBottomBar> {
  final chatMsgTextController = TextEditingController();
  String _textInputValue = "";
  bool _alreadySending = false;

  Future createRequestAndSendMsg() async {
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
        content: Text("Unable to send the message to the user currently"),
      ));
      throw e;
    }
  }

  Future sendMessageToChatRoom() async {
    try {
      // Send a message in the RealtimeDatabase chatRoom
      await context.read<RealtimeDatabaseService>().sendMessageInRoom(
            chatRoomUid: widget.chatRoomsInfos!.chatRoomUid,
            msg: _textInputValue,
            userUid: widget.currentUser.uid,
          );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("There was a network issue while sending the message")));
      throw e;
    }
  }

  void onSendHandler() async {
    if (_alreadySending) return;
    _alreadySending = true;

    if (widget.chatRoomsInfos != null) {
      /// Send a message to the already assigned [widget.chatRoomsInfos.chatRoomUid]
      await sendMessageToChatRoom();
    } else {
      /// Create a new request and then send the message using [_sendMessageToChatRoom]
      await createRequestAndSendMsg();
    }
    _alreadySending = false;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(width: 10),
        Container(
          margin: EdgeInsets.only(bottom: 14),
          child: IconButton(
            onPressed: () {},
            icon: Image.asset("assets/icons/Camera-icon.png", height: 30, width: 30),
          ),
        ),
        Container(
          width: MediaQuery.of(context).size.width - 60,
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Material(
            borderRadius: BorderRadius.circular(26),
            color: Color(0xFFF1F1F1F1),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Container(
                    margin: EdgeInsets.only(bottom: 2),
                    child: TextField(
                      maxLines: 5,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(fontFamily: HelveticaFont.Roman),
                      maxLength: 200,
                      controller: chatMsgTextController,
                      decoration: InputDecoration(
                        counterText: "",
                        contentPadding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),
                        hintText: 'Type your message here...',
                        hintStyle: TextStyle(fontFamily: HelveticaFont.Roman, fontSize: 14),
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
                IconButton(
                  onPressed: () async {
                    // Save the input value
                    _textInputValue = chatMsgTextController.text;
                    // Reset the text input field
                    chatMsgTextController.clear();
                    // Don't send any message if _alreadySending or if message is empty
                    if (_textInputValue.isEmpty || _alreadySending) return;
                    onSendHandler();
                  },
                  icon: Image.asset("assets/icons/Send-icon.png", height: 30, width: 30),
                ),
                SizedBox(width: 10),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
