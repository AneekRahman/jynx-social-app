import 'package:flutter/material.dart';
import 'package:social_app/services/auth_service.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  static final String routeName = "/home";
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Jynx"),
        ),
        body: Center(
            child: Column(
          children: [
            Text("Home Page"),
            RaisedButton(
              onPressed: () {
                context.read<AuthenticationService>().signOut();
              },
              child: Text("Sign out"),
            ),
          ],
        )));
  }
}
