import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_app/models/ChatRoomsInfos.dart';
import 'package:social_app/models/UsersChatRooms.dart';
import 'package:social_app/modules/UsersChatRoomsRow.dart';
import 'package:social_app/pages/ChatMessageRoom.dart';

import '../pages/ChatRoomPage.dart';
import '../services/rtd_service.dart';
import 'LoadingBar.dart';
import 'constants.dart';

class RTDUsersChatsList extends StatefulWidget {
  final Stream<DatabaseEvent> stream;
  final User currentUser;
  final bool fromRequestList;
  RTDUsersChatsList({required this.stream, required this.currentUser, required this.fromRequestList});
  @override
  State<RTDUsersChatsList> createState() => _RTDUsersChatsListState();
}

class _RTDUsersChatsListState extends State<RTDUsersChatsList> {
  late StreamSubscription<DatabaseEvent> _streamSubscription;
  List<ChatRoomsInfos> _chatRoomsInfosList = [];
  bool _loadingStream = true;
  bool _loadingMoreChatsOnScroll = false;
  bool _reachedEndOfResults = false;
  ScrollController? _scrollController = ScrollController();
  int? _lastUsersChatRoomsLTime;

  void _initUsersChatRoomsStreamListener() {
    _streamSubscription = widget.stream.listen((DatabaseEvent event) {
      print("!! Stream GOT called");
      if (event.snapshot.exists) {
        final usersChatRoomsList = UsersChatRooms.fromMap(event.snapshot.value as Map);
        loadChatRoomsInfosFromUids(usersChatRoomsList, true);
      } else {
        // There were no chatRooms found for this user
        setState(() {
          if (_loadingStream) _loadingStream = false;
        });
      }
    });
  }

  void listPreAddDuplicateRemoval(String chatRoomUid) {
    for (var i = 0; i < _chatRoomsInfosList.length; i++) {
      if (_chatRoomsInfosList[i].chatRoomUid == chatRoomUid) {
        _chatRoomsInfosList.removeAt(i);
        print("GOT: removed duplicate: " + chatRoomUid);
      }
    }
  }

  Future loadChatRoomsInfosFromUids(UsersChatRooms usersChatRoomList, bool fromStream) async {
    List<Future<DataSnapshot>> chatRoomsInfosPromises = [];

    usersChatRoomList.usersChatRooms.forEach((UsersChatRoom usersChatRoom) {
      chatRoomsInfosPromises.add(context.read<RealtimeDatabaseService>().getChatRoomsInfoPromise(chatRoomUid: usersChatRoom.chatRoomUid));
    });

    /// The order of entries in [newChatRoomsInfosList] matches the order of entries in [usersChatRoomList] which were given
    /// So, looping through will have both lists index match each other!
    List<DataSnapshot> newChatRoomsInfosList = await Future.wait(chatRoomsInfosPromises);

    /// Add the newest version of the entry and Also map [seenByThisUser]
    /// If [fromStream] is false this will append the new entries to the old ones in [_chatRoomsInfosList]
    for (var i = 0; i < newChatRoomsInfosList.length; i++) {
      final element = newChatRoomsInfosList[i];
      if (element.exists) {
        _chatRoomsInfosList.add(ChatRoomsInfos.fromMap(
          element.value as Map,
          chatRoomUid: element.key!,
          seenByThisUser: usersChatRoomList.usersChatRooms[i].seen,
        ));
      }
    }

    /// Sort the new [_chatRoomsInfosList] from newest to the oldest
    _chatRoomsInfosList.sort((a, b) => b.lTime.compareTo(a.lTime));

    if (fromStream)
      _chatRoomsInfosList.forEach((element) {
        print('GOT: Stream ChatRoomInfos: ${element.chatRoomUid} (lTime): ${element.lTime}');
      });

    // Save the _lastUsersChatRoomsDataSnapshot for loading more chats onScroll
    _lastUsersChatRoomsLTime = _chatRoomsInfosList.last.lTime;

    /// Use [setState] to update the UI

    setState(() {
      _loadingStream = false;
    });
  }

  Future _loadMoreUsersChatRoomsOnScroll() async {
    if (_loadingMoreChatsOnScroll || _lastUsersChatRoomsLTime == null) return;
    _loadingMoreChatsOnScroll = true;

    print("ON SCROLL GOT called");

    try {
      print("GOT: Loading more after: lTime: " + _lastUsersChatRoomsLTime!.toString());

      // Don't know why :/ But when this is called (but probably data not fetched) the value that should have returned here
      // gets returned in the stream. Meaning the endBefore value gets sent to the stream.
      context.read<RealtimeDatabaseService>().getMoreUsersChatsOnScroll(
            userUid: widget.currentUser.uid,
            lastChatRoomLTime: _lastUsersChatRoomsLTime!,
          );
    } catch (e) {}
    _loadingMoreChatsOnScroll = false;
  }

  @override
  void initState() {
    _initUsersChatRoomsStreamListener();

    // Listen to the scroll to load more UsersChatRooms node when scroll reaches the end
    _scrollController!.addListener(() {
      if (_scrollController!.offset > _scrollController!.position.maxScrollExtent - 30 && !_scrollController!.position.outOfRange) {
        // Reached bottom
        _loadMoreUsersChatRoomsOnScroll();
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          LoadingBar(
            loading: _loadingStream,
          ),
          Expanded(
            child: _chatRoomsInfosList.length == 0 && !_loadingStream
                ? _buildNoChatsFoundMsg()
                : CustomScrollView(
                    controller: _scrollController,
                    physics: BouncingScrollPhysics(),
                    slivers: [
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            ChatRoomsInfos chatRoomsInfos = _chatRoomsInfosList[index];

                            return TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                        builder: (context) => ChatMessageRoom(
                                              fromRequestList: widget.fromRequestList,
                                              chatRoomsInfos: chatRoomsInfos,
                                              currentUser: widget.currentUser,
                                            )),
                                  );
                                },
                                child: UsersChatRoomsRow(
                                  chatRoomsInfos: chatRoomsInfos,
                                  currentUser: widget.currentUser,
                                ));
                          },
                          childCount: _chatRoomsInfosList.length,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 5, bottom: 20.0),
                          child: Center(
                              child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.yellow,
                          )),
                        ),
                      )
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoChatsFoundMsg() {
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * .2),
      child: Column(
        children: [
          Icon(
            Icons.fastfood_outlined,
            color: Colors.white.withAlpha(50),
            size: 100,
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              "Looks like we need some \nfriends in this chat :D",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: HelveticaFont.Roman,
                fontSize: 20,
                color: Colors.white.withAlpha(50),
              ),
            ),
          )
        ],
      ),
    );
  }
}
