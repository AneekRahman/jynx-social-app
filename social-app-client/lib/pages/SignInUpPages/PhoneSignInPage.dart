import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './OTP/OtpPage.dart';
import 'EnterNumberPage.dart';

class PhoneSignInPage extends StatefulWidget {
  @override
  _PhoneSignInPageState createState() => _PhoneSignInPageState();
}

class _PhoneSignInPageState extends State<PhoneSignInPage> {
  bool _showOtpPage = false;
  String? _phoneNumber;

  Widget _getSignInPage() {
    // Show OtpPage when there is a number added
    if (_showOtpPage && _phoneNumber != null) {
      return OtpPage(
        phoneNo: _phoneNumber!,
      );
    } else {
      // Return the default first page
      return EnterNumberPage(saveSentPhoneNo: (phoneNo) {
        setState(() {
          _phoneNumber = phoneNo;
          _showOtpPage = true;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_showOtpPage) {
          setState(() {
            _phoneNumber = null;
            _showOtpPage = false;
          });
          return false;
        } else
          return true;
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: _getSignInPage(),
          ),
        ),
      ),
    );
  }
}
