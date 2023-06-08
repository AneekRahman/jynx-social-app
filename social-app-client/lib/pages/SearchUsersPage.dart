import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:social_app/models/UserFirestore.dart';
import 'package:social_app/modules/LoadingBar.dart';
import 'package:social_app/modules/constants.dart';
import 'package:provider/provider.dart';
import 'package:social_app/pages/ProfilePage/OthersProfilePage.dart';

class SearchUsersPage extends StatefulWidget {
  @override
  _SearchUsersPageState createState() => _SearchUsersPageState();
}

class _SearchUsersPageState extends State<SearchUsersPage> {
  final String _initialMsg = "Search for names, usernames";
  String _msg = "Search for names, usernames";
  List<UserFirestore> _searchUsersList = [];
  bool _loading = false;
  User? _currentUser;

  void _searchUsers(String input) async {
    if (_loading) return;
    // Update the UI
    setState(() {
      _loading = true;
    });
    List<UserFirestore> users = [];
    // code to convert the first character to uppercase
    List searchKeys = input.toLowerCase().split(" ");
    if (searchKeys.length > 10) searchKeys = searchKeys.sublist(0, 9);
    QuerySnapshot result =
        await FirebaseFirestore.instance.collection("users").where("searchKeywords", arrayContainsAny: searchKeys).limit(10).get();

    // Map the results
    for (QueryDocumentSnapshot user in result.docs) {
      Map<String, dynamic> data = user.data() as Map<String, dynamic>;

      if (user.id != _currentUser!.uid) users.add(UserFirestore.fromMap(data, user.id));
    }
    // Update the UI
    setState(() {
      if (result.docs.length == 0) {
        _msg = "No results";
      } else {
        _msg = _initialMsg;
      }

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
              _buildSearchScrollList()
            ],
          ),
        ),
      ),
    );
  }

  Expanded _buildSearchScrollList() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CustomScrollView(
            slivers: [
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return GestureDetector(
                    onTap: () {
                      showMaterialModalBottomSheet(
                        backgroundColor: Colors.transparent,
                        context: context,
                        builder: (context) => Padding(
                          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                          child: OthersProfilePage(
                            otherUsersProfileObject: _searchUsersList[index],
                            showMessageButton: true,
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
    );
  }
}

class SearchAppBar extends StatelessWidget {
  final Function(String) _setSearchInput;
  const SearchAppBar({required Function(String) setSearchInput, Key? key})
      : _setSearchInput = setSearchInput,
        super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(10, 20 + MediaQuery.of(context).padding.top, 10, 20),
      width: MediaQuery.of(context).size.width,
      child: Row(
        children: [
          SizedBox(width: 10),
          CupertinoButton(
            padding: EdgeInsets.all(0),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            child: Icon(
              CupertinoIcons.left_chevron,
              color: Colors.yellow,
              size: 20,
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
    required Function(String) setSearchInput,
    Key? key,
  })  : _setSearchInput = setSearchInput,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.only(left: 0, right: 15),
        padding: EdgeInsets.symmetric(horizontal: 8),
        height: 40,
        decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(100)),
        child: TextField(
          onSubmitted: (input) {
            _setSearchInput(input);
          },
          autofocus: true,
          style: TextStyle(fontSize: 14, color: Colors.white, height: 1.3),
          decoration: InputDecoration(
            prefixIcon: Icon(
              CupertinoIcons.search,
              color: Colors.white54,
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
  final UserFirestore _userObject;
  const SearchUserRow({Key? key, userObject})
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
          Container(
            height: 50,
            width: 50,
            child: _userObject.photoURL!.isNotEmpty
                ? ClipRRect(
                    child: Image.network(
                      _userObject.photoURL!,
                      height: 50,
                      width: 50,
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(100)),
                  )
                : Image.asset(
                    "assets/user.png",
                    height: 40,
                    width: 40,
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userObject.displayName!,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: HelveticaFont.Roman,
                    ),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Text(
                    "@" + _userObject.userName!,
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
