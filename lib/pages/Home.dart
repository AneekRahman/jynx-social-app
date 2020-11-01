import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_app/modules/constants.dart';
import 'package:social_app/services/auth_service.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  static final String routeName = "/HomePage";
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark),
      child: Scaffold(
        body: Column(
          children: [
            HomeAppBar(),
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
                  color: Colors.black38,
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
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20),
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 20),
        decoration: BoxDecoration(
            color: Color(0xFF12121212),
            borderRadius: BorderRadius.circular(100)),
        child: Row(
          children: [
            Icon(Icons.search),
            SizedBox(
              width: 6,
            ),
            Text(
              "Search using phone numbers",
              style: TextStyle(fontFamily: HelveticaFont.Roman, fontSize: 12),
            )
          ],
        ),
      ),
    );
  }
}
