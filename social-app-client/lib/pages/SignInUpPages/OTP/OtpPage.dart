import 'package:flutter/material.dart';
import 'package:social_app/modules/constants.dart';
import 'package:provider/provider.dart';
import 'package:social_app/services/auth_service.dart';

import 'OtpForm.dart';

class OtpPage extends StatefulWidget {
  final String phoneNo;
  final Function goBackToEnterPhonePage;
  OtpPage({required this.phoneNo, required this.goBackToEnterPhonePage});
  @override
  _OtpPageState createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  String? _smsCode;
  String _msg = "";
  bool _loading = false, _resentCode = false, _reSendingCode = false;
  int _resendCodeTimer = 60;

  void _resendCode() async {
    if (_reSendingCode || _resentCode || _resendCodeTimer != 0) return;
    // Update the UI
    setState(() {
      _reSendingCode = true;
    });
    // OTP code resend
    await context.read<AuthenticationService>().sendPhoneVerificationCode(
        phoneNo: widget.phoneNo,
        callback: (msg) {
          if (msg == "success") {
            // Update the UI
            setState(() {
              _resentCode = true;
              _reSendingCode = false;
            });
          } else {
            setState(() {
              _msg = msg;
              _reSendingCode = false;
              _resentCode = false;
            });
          }
        });
  }

  void _phoneSignIn() async {
    // If already loading, return
    if (_loading) return;
    // If the smsCode is null or not exactly 6 digits show an error
    if (_smsCode == null || _smsCode!.length != 6) {
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

    // Start phoneSignIn
    await context
        .read<AuthenticationService>()
        .phoneSignIn(
          smsCode: _smsCode,
        )
        .then((response) {
      if (response == "success") {
        // Wait for the User provider to update to HomePage
        // Navigator.pushNamed(context, HomePage.routeName);

        // Stop loading animation
        if (this.mounted)
          setState(() {
            _loading = false;
          });
      } else {
        // Show an error
        setState(() {
          _msg = response;
          _loading = false;
        });
      }
    });
  }

  Row _buildResendCodeRow() {
    return Row(
      children: [
        Text("Didn't get it?"),
        SizedBox(width: 16),
        TweenAnimationBuilder(
          tween: Tween(begin: 60.0, end: 0.0),
          duration: Duration(seconds: 60),
          builder: (_, value, child) {
            _resendCodeTimer = value.toInt();
            return Row(
              children: [
                _buildResendCodeButton(),
                Text(
                  " 00:" + "$_resendCodeTimer".padLeft(_resendCodeTimer < 10 ? 2 : 0, "0"),
                  style: TextStyle(color: _reSendingCode || _resentCode || _resendCodeTimer != 0 ? Colors.white38 : Colors.white),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildResendCodeButton() {
    String text = "Resend Code";
    if (_reSendingCode) text = "Resending code...";
    if (_resentCode) text = "Code sent";
    return GestureDetector(
      onTap: () async {
        _resendCode();
      },
      child: Text(
        text,
        style: TextStyle(
            decoration: TextDecoration.underline,
            color: _reSendingCode || _resentCode || _resendCodeTimer != 0 ? Colors.white38 : Colors.blue),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * .05),
                  Text("Enter verification code", style: Constants.SignInHeadingStyle),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Text("Sent to: " + widget.phoneNo),
                      SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => widget.goBackToEnterPhonePage(),
                        child: Text(
                          "Not you?",
                          style: TextStyle(decoration: TextDecoration.underline, color: Colors.blue),
                        ),
                      )
                    ],
                  ),
                  OtpForm(
                    onOtpChange: (smsCode) {
                      _smsCode = smsCode;
                    },
                  ),
                  _msg.isNotEmpty
                      ? Column(
                          children: [
                            SizedBox(height: 20),
                            Text(
                              _msg,
                              style: TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 10),
                          ],
                        )
                      : SizedBox(),
                  SizedBox(height: 20),
                  _buildResendCodeRow(),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: buildYellowButton(
            child: Text(
              "Verify code",
              style: TextStyle(color: Colors.black, fontFamily: HelveticaFont.Bold, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            onTap: _phoneSignIn,
            loading: _loading,
            context: context,
          ),
        ),
      ],
    );
  }
}
