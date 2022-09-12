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
  bool _loading = true;

  void initUsersChatRoomsStreamListener() {
    _streamSubscription = widget.stream.listen((DatabaseEvent event) {
      if (event.snapshot.exists) {
        final usersChatRoomsList = UsersChatRooms.fromMap(event.snapshot.value as Map);
        getChatRoomsInfosFromUidsInStream(usersChatRoomsList);
      } else {
        // There were no chatRooms found for this user
        setState(() {
          if (_loading) _loading = false;
        });
      }
    });
  }

  void listPreAddDuplicateRemoval(String chatRoomUid) {
    for (var i = 0; i < _chatRoomsInfosList.length; i++) {
      if (_chatRoomsInfosList[i].chatRoomUid == chatRoomUid) {
        _chatRoomsInfosList.removeAt(i);
        print("GOT: removed: " + chatRoomUid);
      }
    }
  }

  Future getChatRoomsInfosFromUidsInStream(UsersChatRooms usersChatRoomList) async {
    List<Future<DataSnapshot>> chatRoomsInfosPromises = [];

    usersChatRoomList.usersChatRooms.forEach((UsersChatRoom usersChatRoom) {
      chatRoomsInfosPromises.add(context.read<RealtimeDatabaseService>().getChatRoomsInfoPromise(chatRoomUid: usersChatRoom.chatRoomUid));
    });

    /// The order of entries in [newChatRoomsInfosList] matches the order of entries in [usersChatRoomList] which were given
    /// So, looping through will have both lists index match each other!
    List<DataSnapshot> newChatRoomsInfosList = await Future.wait(chatRoomsInfosPromises);

    /// Delete the newest few entries from [_chatRoomsInfosList] sinces [usersChatRoomList] returned the newest 10 entries
    if (_chatRoomsInfosList.isNotEmpty) {
      if (_chatRoomsInfosList.length < 10) {
        /// [_chatRoomsInfosList] has less than 10 entries
        _chatRoomsInfosList.removeRange(0, _chatRoomsInfosList.length);
      } else {
        /// [_chatRoomsInfosList] has 10 or more entries
        _chatRoomsInfosList.removeRange(0, newChatRoomsInfosList.length);
      }
    } else {
      _chatRoomsInfosList = [];
    }

    /// Add the newest version of the entry and Also map [seenByThisUser]
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

    /// Lastly, sort the new [_chatRoomsInfosList] from newest to the oldest
    _chatRoomsInfosList.sort((a, b) => b.lTime.compareTo(a.lTime));

    /// Use [setState] to update the UI
    setState(() {
      if (_loading) _loading = false;
    });
  }

  @override
  void initState() {
    initUsersChatRoomsStreamListener();

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
            loading: _loading,
          ),
          Expanded(
            child: _chatRoomsInfosList.length == 0 && !_loading
                ? _buildNoChatsFoundMsg()
                : CustomScrollView(
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
