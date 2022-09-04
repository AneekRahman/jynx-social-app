import 'package:flutter/material.dart';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:social_app/models/ChatRow.dart';
import 'package:social_app/modules/LoadingBar.dart';
import 'package:social_app/modules/constants.dart';
import 'package:social_app/pages/ChatRoomPage.dart';

import '../services/firestore_service.dart';
import 'ChatListRow.dart';

class ChatsList extends StatefulWidget {
  ChatsList({
    Key? key,
    required this.currentUser,
    required this.stream,
    this.emptyChatListMsg,
  }) : super(key: key);
  final Widget? emptyChatListMsg;
  final User currentUser;
  final Stream<QuerySnapshot> stream;

  @override
  State<ChatsList> createState() => _ChatsListState();
}

class _ChatsListState extends State<ChatsList> {
  List<ChatRow> chatRows = [];
  bool loadingChats = true;
  bool _reachedEndOfResults = false;
  ScrollController? _controller;
  QueryDocumentSnapshot? _lastDocument;

  void _removeIfAlreadyAdded(ChatRow chatRow) {
    for (int i = 0; i < chatRows.length; i++) {
      ChatRow element = chatRows.elementAt(i);
      if (element != null && chatRow.chatRoomUid == element.chatRoomUid) {
        final index = chatRows.indexOf(element);
        chatRows.removeAt(index);
      }
    }
  }

  void _buildChatRows(List<QueryDocumentSnapshot> snapshots) {
    print(" GOT: _buildChatRows " + snapshots.length.toString());

    snapshots.forEach((snapshot) {
      print("GOT: ${snapshot.id}");
      ChatRow chatRow = makeChatRowFromUserChats(snapshot, widget.currentUser.uid, true)!;
      _removeIfAlreadyAdded(chatRow);
      chatRows.add(chatRow);
    });

    // Sort the first _chatFetchLimit (10) results on the client side as well
    chatRows.sort((a, b) => b.lastMsgSentTime!.compareTo(a.lastMsgSentTime!));

    // If this is the first time and the rows are pulled from the stream
    if (_lastDocument == null && snapshots.length > 0) {
      _lastDocument = snapshots[snapshots.length - 1];
      //  TODO DO this better
      if (snapshots.length < Constants.CHAT_LIST_READ_LIMIT) {
        Future.delayed(const Duration(milliseconds: 500), () {
          // This is the first time, so try to load again and remove the loading icon
          _loadMoreChats();
        });
      }
    }
    // Update the loading Animation
    loadingChats = false;
  }

  void _loadMoreChats() async {
    if (loadingChats || _reachedEndOfResults) return;

    setState(() {
      loadingChats = true;
    });

    QuerySnapshot snapshot =
        await context.read<FirestoreService>().getNewChatListChats(currentUserUid: widget.currentUser.uid, lastDocument: _lastDocument);

    if (snapshot.docs.isNotEmpty) {
      print(" GOT: _loadMoreChats CHAT LOADED AGAIN AFTER THE STREAM " + snapshot.docs.length.toString());
      _buildChatRows(snapshot.docs);
      // Save the lastDocument
      _lastDocument = snapshot.docs[snapshot.docs.length - 1];
    } else {
      _reachedEndOfResults = true;
    }

    setState(() {
      loadingChats = false;
    });
  }

  @override
  void initState() {
    _controller = ScrollController();
    _controller!.addListener(() {
      if (_controller!.offset >= _controller!.position.maxScrollExtent && !_controller!.position.outOfRange) {
        // Reached bottom
        _loadMoreChats();
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: widget.stream,
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasData) {
          _buildChatRows(snapshot.data!.docs);
        } else {
          _reachedEndOfResults = true;
        }

        return Expanded(
          child: Column(
            children: [
              LoadingBar(
                loading: loadingChats,
              ),
              // Show the end of result widget here
              widget.emptyChatListMsg != null && snapshot.hasData && snapshot.data!.docs.length == 0
                  ? widget.emptyChatListMsg!
                  : Container(),
              // Show the ChatList scroll view here
              snapshot.hasData
                  ? Expanded(
                      child: CustomScrollView(
                        controller: _controller,
                        physics: BouncingScrollPhysics(),
                        slivers: [
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                ChatRow chatRow = chatRows.elementAt(index);
                                return TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        CupertinoPageRoute(
                                            builder: (context) => ChatRoomPage(
                                                  chatRow: chatRow,
                                                  otherUser: chatRow.otherUser,
                                                )),
                                      );
                                    },
                                    child: ChatsListRow(chatRow: chatRow));
                              },
                              childCount: chatRows.length,
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Center(
                              child: !_reachedEndOfResults
                                  ? Container(
                                      margin: EdgeInsets.only(bottom: 30),
                                      height: 30,
                                      width: 30,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.yellow,
                                      ))
                                  : Container(
                                      margin: EdgeInsets.only(bottom: 30),
                                      child: Text(
                                        "no more chats found",
                                        style: TextStyle(color: Colors.white24),
                                      ),
                                    ),
                            ),
                          ),
                          // SliverToBoxAdapter(
                          //   child: SizedBox(
                          //     height: MediaQuery.of(context).size.height,
                          //   ),
                          // ),
                        ],
                      ),
                    )
                  : SizedBox(),
            ],
          ),
        );
      },
    );
  }
}
