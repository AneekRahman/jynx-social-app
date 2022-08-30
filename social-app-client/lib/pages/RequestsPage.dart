import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_app/modules/ChatList.dart';
import 'package:social_app/modules/constants.dart';
import 'package:provider/provider.dart';
import 'package:social_app/services/firestore_service.dart';

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
            Expanded(
              child: ChatsList(
                currentUser: _currentUser!,
                stream: context.watch<FirestoreService>().getUserChatsRequestedStream(_currentUser!.uid, false),
              ),
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
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                Icons.arrow_back_ios,
                size: 16,
                color: Colors.white,
              ),
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
