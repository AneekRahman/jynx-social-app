import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './OTP/OtpPage.dart';
import './PhoneSendCodePage.dart';

class PhoneSignInPage extends StatefulWidget {
  @override
  _PhoneSignInPageState createState() => _PhoneSignInPageState();
}

class _PhoneSignInPageState extends State<PhoneSignInPage> {
  int _pageNum = 0;
  String? _phoneNumber;

  Widget _getStepPage() {
    if (_pageNum == 1 && _phoneNumber != null) {
      return OtpPage(
        phoneNo: _phoneNumber!,
      );
    }

    // Return the default first page if none of the other pages are selected
    return PhoneSendCodePage(saveSentPhoneNo: (phoneNo) {
      _phoneNumber = phoneNo;
      setState(() {
        _pageNum = 1;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_pageNum > 0) {
          setState(() {
            _pageNum--;
          });

          return false;
        } else
          return true;
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark),
        child: Scaffold(
          body: SafeArea(
            child: _getStepPage(),
          ),
        ),
      ),
    );
  }
}
