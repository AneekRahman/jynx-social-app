import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_app/models/MyUserObject.dart';

class MyProfilePage extends StatelessWidget {
  MyUserObject userObject;
  MyProfilePage({this.userObject});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark),
      child: Scaffold(
        backgroundColor: Colors.black87,
        body: Column(
          children: [
            ProfilePageAppBar(),
          ],
        ),
      ),
    );
  }
}

class ProfilePageAppBar extends StatelessWidget {
  const ProfilePageAppBar({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(Icons.keyboard_arrow_down),
        Icon(Icons.more_horiz),
      ],
    );
  }
}
