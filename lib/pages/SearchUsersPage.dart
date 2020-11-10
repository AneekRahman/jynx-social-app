import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_app/modules/LoadingBar.dart';
import 'package:social_app/models/MyUserObject.dart';
import 'package:social_app/modules/constants.dart';
import 'package:social_app/pages/ChatRoomPage.dart';
import 'package:provider/provider.dart';

class SearchUsersPage extends StatefulWidget {
  @override
  _SearchUsersPageState createState() => _SearchUsersPageState();
}

class _SearchUsersPageState extends State<SearchUsersPage> {
  final String _initialMsg = "Search for names, usernames";
  String _msg = "Search for names, usernames";
  List<MyUserObject> _searchUsersList = [];
  bool _loading = false;
  User _currentUser;

  void _searchUsers(String input) async {
    if (_loading) return;
    // Update the UI
    setState(() {
      _loading = true;
    });
    List<MyUserObject> users = [];
    // code to convert the first character to uppercase
    List searchKeys = input.split(" ");
    if (searchKeys.length > 10) searchKeys = searchKeys.sublist(0, 9);
    QuerySnapshot result = await FirebaseFirestore.instance
        .collection("users")
        .orderBy("displayName")
        .where("searchKeywords", arrayContainsAny: searchKeys)
        .limit(10)
        .get();

    // Map the results
    for (QueryDocumentSnapshot user in result.docs) {
      Map data = user.data();
      if (user.id != _currentUser.uid)
        users.add(MyUserObject(
          displayName: data["displayName"],
          userName: data["userName"],
          profilePic: data["profilePic"],
          userUid: user.id,
        ));
    }
    // Update the UI
    setState(() {
      if (result.docs.length == 0)
        _msg = "No results";
      else
        _msg = _initialMsg;
      _loading = false;
      _searchUsersList = users;
    });
  }

  // Callback passed down to the search input
  void _setSearchInput(input) {
    _searchUsers(input);
  }

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
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarIconBrightness: Brightness.dark),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              SearchAppBar(
                setSearchInput: _setSearchInput,
              ),
              LoadingBar(
                loading: _loading,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CustomScrollView(
                      slivers: [
                        SliverList(
                          delegate:
                              SliverChildBuilderDelegate((context, index) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (context) => ChatRoomPage(
                                      otherUser: _searchUsersList[index],
                                    ),
                                  ),
                                );
                              },
                              child: SearchUserRow(
                                userObject: _searchUsersList[index],
                              ),
                            );
                          }, childCount: _searchUsersList.length),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(top: 15, bottom: 30),
                            child: Text(
                              _msg,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white30,
                                fontFamily: HelveticaFont.Roman,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class SearchAppBar extends StatelessWidget {
  final Function(String) _setSearchInput;
  const SearchAppBar({Function setSearchInput, key})
      : _setSearchInput = setSearchInput,
        super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          18, 20 + MediaQuery.of(context).padding.top, 10, 20),
      width: MediaQuery.of(context).size.width,
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            child: Padding(
              child: Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
              ),
              padding: EdgeInsets.all(4),
            ),
          ),
          SearchBox(
            setSearchInput: _setSearchInput,
          ),
        ],
      ),
    );
  }
}

class SearchBox extends StatelessWidget {
  final Function(String) _setSearchInput;

  const SearchBox({
    Function setSearchInput,
    Key key,
  })  : _setSearchInput = setSearchInput,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 15),
        padding: EdgeInsets.symmetric(horizontal: 8),
        height: 40,
        decoration: BoxDecoration(
            color: Colors.white12, borderRadius: BorderRadius.circular(100)),
        child: TextField(
          onChanged: (input) {
            _setSearchInput(input);
          },
          autofocus: true,
          style: TextStyle(fontSize: 14, color: Colors.white, height: 1.3),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.search,
              color: Colors.white,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 0),
          ),
        ),
      ),
    );
  }
}

class SearchUserRow extends StatelessWidget {
  final MyUserObject _userObject;
  const SearchUserRow({Key key, userObject})
      : _userObject = userObject,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: Container(
              color: Colors.white12,
              child: Image.network(
                _userObject.profilePic ?? "",
                height: 40,
                width: 40,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userObject.displayName,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: HelveticaFont.Roman,
                    ),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Text(
                    "@" + _userObject.userName,
                    style: TextStyle(
                      color: Colors.white60,
                      fontFamily: HelveticaFont.Roman,
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
