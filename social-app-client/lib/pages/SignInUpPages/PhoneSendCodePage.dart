import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:social_app/modules/MyBottomButton.dart';
import 'package:social_app/modules/constants.dart';
import 'package:social_app/services/auth_service.dart';
import 'package:provider/provider.dart';

class PhoneSendCodePage extends StatefulWidget {
  final Function saveSentPhoneNo;
  PhoneSendCodePage({required this.saveSentPhoneNo});
  @override
  _PhoneSendCodePageState createState() => _PhoneSendCodePageState();
}

class _PhoneSendCodePageState extends State<PhoneSendCodePage> {
  TextEditingController _phoneTextEditController = TextEditingController();
  String? _dialCode, _phoneNo, _msg = "";
  bool _loading = false;

  void _sendCode() async {
    // If already loading, return
    if (_loading) return;
    // If the phoneNo is null or not exactly 6 digits show an error
    if (_phoneNo == null || _phoneNo!.isEmpty || _phoneNo!.length - _dialCode!.length <= 0) {
      setState(() {
        _msg = "Enter a phone number";
      });
      return;
    }

    // Start loading animation
    setState(() {
      _msg = "";
      _loading = true;
    });

    // Send a phone no verification code
    await context.read<AuthenticationService>().sendPhoneVerificationCode(
        phoneNo: _phoneNo,
        callback: (msg) {
          if (msg == "success") {
            // Go to OTP page after successfully sent code
            widget.saveSentPhoneNo(_phoneNo);
            // Stop loading animation
            setState(() {
              _loading = false;
            });
          } else {
            // Show an error
            setState(() {
              _msg = msg;
              _loading = false;
            });
          }
        });
  }

  Widget _buildForm() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          InternationalPhoneNumberInput(
            inputDecoration: InputDecoration(
                labelText: "Phone",
                floatingLabelBehavior: FloatingLabelBehavior.always,
                hintText: "Enter your number",
                contentPadding: EdgeInsets.fromLTRB(0, 0, 0, 10)),
            textStyle: normalTextStyle,
            onInputChanged: (PhoneNumber number) {
              _phoneNo = number.phoneNumber;
              _dialCode = number.dialCode;
            },
            selectorConfig: SelectorConfig(
              selectorType: PhoneInputSelectorType.DIALOG,
            ),
            ignoreBlank: false,
            selectorTextStyle: TextStyle(color: Colors.black, fontSize: 16),
            textFieldController: _phoneTextEditController,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 20),
                Text("Phone Login", style: headingStyle),
                SizedBox(height: MediaQuery.of(context).size.height * .06),
                _buildForm(),
                SizedBox(height: 10),
                Text(
                  _msg ?? "",
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                Text(
                  'By continuing your confirm that you agree \nwith our Terms and Conditions',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.caption,
                )
              ],
            ),
          ),
        ),
        MyBottomButton(
          text: "Get Code",
          isLoading: _loading,
          onTap: () {
            _sendCode();
          },
        )
      ],
    );
  }
}
