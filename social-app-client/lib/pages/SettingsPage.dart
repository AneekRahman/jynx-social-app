import 'package:flutter/material.dart';
import 'package:social_app/modules/constants.dart';
import 'package:social_app/pages/Home.dart';
import 'package:social_app/services/auth_service.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _recieveNotifications = false;

  TextStyle _normalTextStyle = TextStyle(
    color: Colors.white,
    fontFamily: HelveticaFont.Roman,
  );

  TextStyle _buttonTextStyle = TextStyle(
    color: Colors.white,
    fontFamily: HelveticaFont.Medium,
    fontSize: 16,
  );

  Widget _buildHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        text,
        style: TextStyle(color: Colors.white, fontFamily: HelveticaFont.Bold, fontSize: 20),
      ),
    );
  }

  Widget _buildButton(String text, Function() onTap) {
    return TextButton(
        style: ButtonStyle(
          padding: MaterialStateProperty.all(EdgeInsets.all(14)),
        ),
        onPressed: onTap,
        child: Container(
          width: MediaQuery.of(context).size.width,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: _buttonTextStyle,
          ),
        ));
    // return OutlineButton(
    //   padding: EdgeInsets.all(14),
    //   borderSide: BorderSide(
    //     color: Colors.white30,
    //     width: 1,
    //   ),
    //   onPressed: onTap,
    //   child: Container(
    //     width: MediaQuery.of(context).size.width,
    //     child: Text(
    //       text,
    //       textAlign: TextAlign.center,
    //       style: _buttonTextStyle,
    //     ),
    //   ),
    // );
  }

  Widget _buildCheckBoxTile(String title, String subTitle, {bool? value, void onChanged(bool? checked)?}) {
    return CheckboxListTile(
      activeColor: Colors.yellow,
      checkColor: Colors.black,
      contentPadding: EdgeInsets.all(0),
      value: value,
      onChanged: onChanged,
      title: Text(
        title,
        style: _buttonTextStyle,
      ),
      subtitle: Text(
        subTitle,
        style: _normalTextStyle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0a0a0a),
      body: SafeArea(
        child: Column(
          children: [
            SettingsPageAppBar(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader("Security"),
                      Text(
                        "By changing the passwords, you automatically log out of other devices",
                        style: _normalTextStyle,
                      ),
                      SizedBox(height: 20),
                      buildYellowButton(
                          child: Text(
                            "Change password",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontFamily: HelveticaFont.Bold),
                          ),
                          onTap: () {},
                          context: context,
                          loading: false),
                      SizedBox(height: 30),
                      _buildHeader("Notifications"),
                      _buildCheckBoxTile(
                        "Recieve notifications",
                        "Control if you want to recieve notifications from Jynx",
                        value: _recieveNotifications,
                        onChanged: (checked) {
                          setState(() => _recieveNotifications = checked!);
                        },
                      ),
                      SizedBox(height: 30),
                      buildYellowButton(
                          child: Text(
                            "Logout",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontFamily: HelveticaFont.Bold),
                          ),
                          onTap: () {
                            context.read<AuthenticationService>().signOut();
                            Navigator.popUntil(context, (route) => route.isFirst);
                          },
                          context: context,
                          loading: false),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPageAppBar extends StatelessWidget {
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
            "Settings",
            style: TextStyle(fontFamily: HelveticaFont.Bold, fontSize: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
