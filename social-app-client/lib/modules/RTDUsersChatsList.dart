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
  StreamSubscription<DatabaseEvent>? _streamSubscription;
  List<ChatRoomsInfos> _chatRoomsInfosList = [];
  bool _loadingStream = true;
  bool _loadingMoreChats = false;
  bool _reachedEndOfResults = false;
  ScrollController? _scrollController = ScrollController();
  int? _lastUsersChatRoomsLTime = 0;

  void listPreAddDuplicateRemoval(String chatRoomUid) {
    for (var i = 0; i < _chatRoomsInfosList.length; i++) {
      if (_chatRoomsInfosList[i].chatRoomUid == chatRoomUid) {
        _chatRoomsInfosList.removeAt(i);
        print("GOT: removed duplicate: " + chatRoomUid);
      }
    }
  }

  Future addNewChangedChatRoomsInfos(String chatRoomUid) async {
    ChatRoomsInfos? prevChatRoomsInfos;
    _chatRoomsInfosList.forEach((element) {
      if (element.chatRoomUid == chatRoomUid) prevChatRoomsInfos = element;
    });

    final DataSnapshot chatRoomsInfosSnapshot = await context.read<RealtimeDatabaseService>().getChatRoomsInfo(chatRoomUid: chatRoomUid);

    if (prevChatRoomsInfos != null && chatRoomsInfosSnapshot.exists) {
      ChatRoomsInfos newChatRoomsInfos = ChatRoomsInfos.fromMap(
        chatRoomsInfosSnapshot.value as Map,
        chatRoomUid: chatRoomUid,
        seenByThisUser: prevChatRoomsInfos!.seenByThisUser,
      );
      listPreAddDuplicateRemoval(chatRoomUid);
      _chatRoomsInfosList.add(newChatRoomsInfos);
      _chatRoomsInfosList.sort((a, b) => b.lTime.compareTo(a.lTime));
    }
  }

  void _handleStreamListener(DatabaseEvent event) async {
    // _loadingMoreChats is evaltuated inside of [stream.addListener]
    _loadingMoreChats = true;

    if (event.snapshot.exists) {
      final DataSnapshot newUsersChatRoomsSnapshot = event.snapshot;
      print("!! Stream GOT (length) called: " + newUsersChatRoomsSnapshot.children.length.toString());
      print("!! Stream GOT (first children value) called: " + newUsersChatRoomsSnapshot.children.first.value.toString());
      print("!! Stream GOT (value) called: " + newUsersChatRoomsSnapshot.value.toString());

      // Get this to verify if the childrens child has either [lTime] and [seen] or both
      final DataSnapshot firstChildrenSnapshot = newUsersChatRoomsSnapshot.children.first;

      if (firstChildrenSnapshot.hasChild("lTime") && firstChildrenSnapshot.hasChild("seen")) {
        // Both lTime and seen are present in the [newUsersChatRoomsSnapshot]
        print("!! Stream GOT INSIDE 1");

        final usersChatRoomsList = UsersChatRooms.fromMap(newUsersChatRoomsSnapshot.value as Map);
        await appendInfosFromUsersChatRoomsUids(usersChatRoomsList);
      } else if (firstChildrenSnapshot.hasChild("lTime") && !firstChildrenSnapshot.hasChild("seen")) {
        // Only lTime is present. So, retrive only the /chatRoomsInfos/ using [addNewChangedChatRoomsInfos]
        print("!! Stream GOT INSIDE 2");

        await addNewChangedChatRoomsInfos(firstChildrenSnapshot.key!);
      } else if (firstChildrenSnapshot.hasChild("seen") && !firstChildrenSnapshot.hasChild("lTime")) {
        // Only seen is present. So, update only the seen in for the specific [_chatRoomsInfosList] element
        print("!! Stream GOT INSIDE 3");

        newUsersChatRoomsSnapshot.children.forEach((usersChatRoomsSnapshot) {
          _chatRoomsInfosList.forEach((element) {
            if (element.chatRoomUid == usersChatRoomsSnapshot.key) {
              element.seenByThisUser = (usersChatRoomsSnapshot.value as Map)["seen"];
            }
          });
        });
      }
    } else {
      // This will only when [_reachedEndOfResults] has been set to false after the very first run
      if (!_loadingStream)
        setState(() {
          _reachedEndOfResults = true;
        });
    }
    //
    setState(() {
      _loadingStream = false;
      _loadingMoreChats = false;
    });
  }

  Future appendInfosFromUsersChatRoomsUids(UsersChatRooms usersChatRoomList) async {
    List<Future<DataSnapshot>> chatRoomsInfosPromises = [];

    usersChatRoomList.usersChatRooms.forEach((UsersChatRoom usersChatRoom) {
      chatRoomsInfosPromises.add(context.read<RealtimeDatabaseService>().getChatRoomsInfo(chatRoomUid: usersChatRoom.chatRoomUid));
    });

    /// The order of entries in [newChatRoomsInfosList] matches the order of entries in [usersChatRoomList] which were given
    /// So, looping through will have both lists index match each other!
    List<DataSnapshot> newChatRoomsInfosSnapshots = await Future.wait(chatRoomsInfosPromises);

    /// Add the newest version of the entry and Also map [seenByThisUser]
    /// If [fromStream] is false this will append the new entries to the old ones in [_chatRoomsInfosList]
    for (var i = 0; i < newChatRoomsInfosSnapshots.length; i++) {
      final element = newChatRoomsInfosSnapshots[i];
      if (element.exists) {
        listPreAddDuplicateRemoval(element.key!);
        _chatRoomsInfosList.add(ChatRoomsInfos.fromMap(
          element.value as Map,
          chatRoomUid: element.key!,
          seenByThisUser: usersChatRoomList.usersChatRooms[i].seen,
        ));
      }
    }

    /// Sort the new [newChatRoomsInfosList] from newest to the oldest
    _chatRoomsInfosList.sort((a, b) => b.lTime.compareTo(a.lTime));

    _lastUsersChatRoomsLTime = _chatRoomsInfosList.last.lTime;

    setState(() {});
  }

  Future _loadUsersChatRooms() async {
    print("GOT: Loading more after: lTime: " + _lastUsersChatRoomsLTime!.toString());
    context.read<RealtimeDatabaseService>().getMoreUsersChatsOnScroll(
          userUid: widget.currentUser.uid,
          lastChatRoomLTime: _lastUsersChatRoomsLTime!,
        );
  }

  @override
  void initState() {
    _streamSubscription = widget.stream.listen(_handleStreamListener);

    // Listen to the scroll to load more UsersChatRooms node when scroll reaches the end
    _scrollController!.addListener(() {
      if (_scrollController!.offset > _scrollController!.position.maxScrollExtent - 30 && !_scrollController!.position.outOfRange) {
        // Reached bottom
        if (!_reachedEndOfResults && !_loadingMoreChats) _loadUsersChatRooms();
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    if (_streamSubscription != null) _streamSubscription!.cancel();
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
                          padding: const EdgeInsets.only(top: 5, bottom: 30.0),
                          child: Center(
                              child: !_reachedEndOfResults
                                  ? CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.yellow,
                                    )
                                  : Text("reached the end")),
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
