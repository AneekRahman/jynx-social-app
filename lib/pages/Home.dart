import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_app/models/ChatRow.dart';
import 'package:social_app/models/LoadingBar.dart';
import 'package:social_app/modules/constants.dart';
import 'package:social_app/pages/SearchUsersPage.dart';
import 'package:social_app/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:social_app/services/rtd_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'ChatRoomPage.dart';

class HomePage extends StatefulWidget {
  static final String routeName = "/HomePage";
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<ChatRow> _chatRows = [];
  User _currentUser;

  @override
  void initState() {
    _currentUser = context.read<User>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            HomeAppBar(),
            ChatsList(
              chatRows: _chatRows,
              currentUser: _currentUser,
            ),
            RaisedButton(
              onPressed: () {
                context.read<AuthenticationService>().signOut();
              },
              child: Text("Sign out"),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeAppBar extends StatelessWidget {
  final double _padding = 20;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(_padding,
          _padding + MediaQuery.of(context).padding.top, _padding, _padding),
      width: MediaQuery.of(context).size.width,
      child: Row(
        children: [
          Container(
            child: Icon(
              Icons.person,
              color: Colors.black38,
            ),
            decoration: BoxDecoration(
                border: Border.all(
                  color: Color(0xFFF2F2F2F2),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(100)),
            padding: EdgeInsets.all(4),
          ),
          SearchBox(),
          Icon(Icons.person_add),
        ],
      ),
    );
  }
}

class SearchBox extends StatelessWidget {
  const SearchBox({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, anim1, anim2) => SearchUsersPage(),
                transitionDuration: Duration(milliseconds: 0),
              ));
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 15),
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
              color: Color(0xFFF2F2F2F2),
              borderRadius: BorderRadius.circular(100)),
          child: Row(
            children: [
              Icon(Icons.search),
              SizedBox(
                width: 6,
              ),
              Text(
                "Search for friends",
                style: TextStyle(fontFamily: HelveticaFont.Roman, fontSize: 12),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ChatsList extends StatelessWidget {
  ChatsList({
    Key key,
    @required User currentUser,
    @required List<ChatRow> chatRows,
  })  : _chatRows = chatRows,
        _currentUser = currentUser,
        super(key: key);
  User _currentUser;
  final List<ChatRow> _chatRows;
  bool _loadingChats = true;

  void _removeIfAlreadyAdded(ChatRow chatRow) {
    for (int i = 0; i < _chatRows.length; i++) {
      ChatRow element = _chatRows.elementAt(i);
      if (element != null && chatRow.chatRoomUid == element.chatRoomUid) {
        final index = _chatRows.indexOf(element);
        _chatRows.removeAt(index);
      }
    }
  }

  void _setChatRowsFromStream(dynamic usersChatsObject) {
    usersChatsObject.forEach((key, value) {
      ChatRow chatRow =
          ChatRow.fromJson({...usersChatsObject[key], 'chatRoomUid': key});
      _removeIfAlreadyAdded(chatRow);
      _chatRows.add(chatRow);
    });

    // Sort the first 10 results on the client side as well
    _chatRows.sort((a, b) => b.lastMsgSentTime.compareTo(a.lastMsgSentTime));
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: StreamBuilder(
        stream: context
            .watch<RealtimeDatabaseService>()
            .getAllChatHisoryStream(_currentUser.uid),
        builder: (context, AsyncSnapshot<Event> snapshot) {
          if (snapshot.hasData && !snapshot.hasError) {
            print("UPDATE FROM STREAM");

            if (_chatRows.length <= 10) {
              // Remove all if list less than or equal to 10
              _chatRows.clear();
            } else {
              // Remove the first 10 (Range of stream) if list longer than 10
              _chatRows.removeRange(0, 9);
            }

            // Set the _chatRows list
            _setChatRowsFromStream(snapshot.data.snapshot.value);
            // Update the loading Animation
            _loadingChats = false;

            return Column(
              children: [
                LoadingBar(
                  loading: _loadingChats,
                  valueColor: Colors.blue[100],
                ),
                Expanded(
                  child: CustomScrollView(
                    physics: BouncingScrollPhysics(),
                    slivers: [
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            ChatRow chatRow = _chatRows.elementAt(index);
                            return FlatButton(
                                padding: EdgeInsets.all(0),
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => ChatRoomPage(
                                                chatRow: chatRow,
                                              )));
                                },
                                child: ChatsListRow(chatRow: chatRow));
                          },
                          childCount: _chatRows.length,
                        ),
                      )
                    ],
                  ),
                ),
              ],
            );
          } else {
            return Center(
              child: SizedBox(
                  child: CircularProgressIndicator(), height: 25, width: 25),
            );
          }
        },
      ),
    );
  }
}

class ChatsListRow extends StatelessWidget {
  const ChatsListRow({
    Key key,
    @required ChatRow chatRow,
  })  : _chatRow = chatRow,
        super(key: key);

  final ChatRow _chatRow;

  @override
  Widget build(BuildContext context) {
    final DateTime sentTime =
        new DateTime.fromMillisecondsSinceEpoch(_chatRow.lastMsgSentTime);
    final String sentTimeFormattedString =
        timeago.format(sentTime, locale: 'en_short', allowFromNow: true);
    final fontFamily =
        _chatRow.status == 0 ? HelveticaFont.Heavy : HelveticaFont.Medium;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: Container(
              color: Colors.black12,
              child: Image.network(
                _chatRow.otherUsersPic ?? "",
                height: 40,
                width: 40,
              ),
            ),
          ),
          SizedBox(
            width: 10,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _chatRow.otherUsersName,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 12,
                ),
              ),
              SizedBox(
                height: 2,
              ),
              Row(
                children: [
                  Icon(
                    _chatRow.status == 0
                        ? Icons.chat_bubble
                        : Icons.chat_bubble_outline,
                    size: 14,
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  Text(
                    _chatRow.status == 0 ? "New message" : "Opened",
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Expanded(
            child: Container(),
          ),
          Text(
            sentTimeFormattedString,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 12,
            ),
          )
        ],
      ),
    );
  }
}
