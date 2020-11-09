import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_app/models/ChatList.dart';
import 'package:social_app/modules/constants.dart';
import 'package:social_app/pages/RequestsPage.dart';
import 'package:social_app/pages/SearchUsersPage.dart';
import 'package:social_app/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:social_app/services/firestore_service.dart';

class HomePage extends StatefulWidget {
  static final String routeName = "/HomePage";
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
              currentUser: _currentUser,
              stream: context
                  .watch<FirestoreService>()
                  .getUserChatsStream(_currentUser.uid, false),
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
          GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (context) => RequestsPage()),
                );
              },
              child: Icon(Icons.person_add)),
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
