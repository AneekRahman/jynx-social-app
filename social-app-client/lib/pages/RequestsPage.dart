import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_app/modules/constants.dart';
import 'package:provider/provider.dart';
import 'package:social_app/services/firestore_service.dart';

import '../modules/Home/RTDUsersChatsList.dart';
import '../services/rtd_service.dart';

class RequestsPage extends StatefulWidget {
  @override
  _RequestsPageState createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  User? _currentUser;

  @override
  void initState() {
    _currentUser = context.read<User>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light),
      child: Scaffold(
        backgroundColor: Color(0xFF0a0a0a),
        body: Column(
          children: [
            HomeAppBar(),
            RTDUsersChatsList(
              stream: context.read<RealtimeDatabaseService>().getUsersRequestedChatsStream(userUid: _currentUser!.uid),
              currentUser: _currentUser!,
              fromRequestList: true,
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
      padding: EdgeInsets.fromLTRB(_padding, _padding + MediaQuery.of(context).padding.top, _padding, _padding),
      width: MediaQuery.of(context).size.width,
      child: Row(
        children: [
          CupertinoButton(
            padding: EdgeInsets.all(0),
            onPressed: () => Navigator.pop(context),
            child: Icon(
              CupertinoIcons.left_chevron,
              color: Colors.yellow,
              size: 20,
            ),
          ),
          Text(
            "Requests",
            style: TextStyle(fontFamily: HelveticaFont.Bold, fontSize: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
