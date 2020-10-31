import 'package:flutter/material.dart';
import 'package:social_app/modules/MyBottomButton.dart';
import 'package:social_app/modules/constants.dart';
import 'package:provider/provider.dart';
import 'package:social_app/pages/Home.dart';
import 'package:social_app/services/auth_service.dart';

import 'OtpForm.dart';

class OtpPage extends StatefulWidget {
  final String phoneNo;
  OtpPage({this.phoneNo});
  @override
  _OtpPageState createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  String _smsCode, _msg;
  bool _loading = false;

  void _phoneSignIn() {
    print('CODE IS: ${_smsCode}');
    if (_loading) return;
    if (_smsCode == null || _smsCode.length != 6) {
      setState(() {
        _msg = "Enter a 6 digit code sent to you";
      });
      return;
    }
    // Update the loading anim

    setState(() {
      _loading = true;
      _msg = "";
    });
    context
        .read<AuthenticationService>()
        .phoneSignIn(
          smsCode: _smsCode,
        )
        .then((response) {
      if (response == "success") {
        Navigator.pushNamed(context, HomePage.routeName);
      }
      setState(() {
        _loading = false;
        _msg = response;
      });
    });
  }

  Row buildTimer() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Wait before requesting a new code"),
        TweenAnimationBuilder(
          tween: Tween(begin: 60.0, end: 0.0),
          duration: Duration(seconds: 60),
          builder: (_, value, child) => Text(
            "00:${value.toInt()}",
            style: TextStyle(color: Color(0xFF757575)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 30),
                      Text(
                        "Phone Verification",
                        style: headingStyle,
                      ),
                      SizedBox(height: 10),
                      Text("Enter the code sent to: " + widget.phoneNo),
                      OtpForm(
                        onOtpChange: (smsCode) {
                          _smsCode = smsCode;
                          print('GOT NEW SMS CODE: ${smsCode}');
                        },
                      ),
                      SizedBox(height: 20),
                      Text(
                        _msg ?? "",
                        style: TextStyle(color: Colors.red),
                      ),
                      SizedBox(height: 40),
                      buildTimer(),
                      SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          // OTP code resend
                        },
                        child: Text(
                          "Send New Code",
                          style:
                              TextStyle(decoration: TextDecoration.underline),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            MyBottomButton(
              text: "Verify phone",
              onTap: () {
                _phoneSignIn();
              },
            )
          ],
        ),
      ),
    );
  }
}
