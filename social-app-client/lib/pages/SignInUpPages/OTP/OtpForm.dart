import 'package:flutter/material.dart';
import 'package:social_app/modules/constants.dart';

class OtpForm extends StatefulWidget {
  final Function onOtpChange;
  const OtpForm({Key? key, required this.onOtpChange}) : super(key: key);

  @override
  _OtpFormState createState() => _OtpFormState();
}

class _OtpFormState extends State<OtpForm> {
  late FocusNode pin1FocusNode;
  late FocusNode pin2FocusNode;
  late FocusNode pin3FocusNode;
  late FocusNode pin4FocusNode;
  late FocusNode pin5FocusNode;
  late FocusNode pin6FocusNode;
  List<String?> values = new List.filled(6, null, growable: true); // TODO CHeck if this wordks

  @override
  void initState() {
    super.initState();
    pin1FocusNode = FocusNode();
    pin2FocusNode = FocusNode();
    pin3FocusNode = FocusNode();
    pin4FocusNode = FocusNode();
    pin5FocusNode = FocusNode();
    pin6FocusNode = FocusNode();
  }

  @override
  void dispose() {
    super.dispose();
    pin1FocusNode.dispose();
    pin2FocusNode.dispose();
    pin3FocusNode.dispose();
    pin4FocusNode.dispose();
    pin5FocusNode.dispose();
    pin6FocusNode.dispose();
  }

  void nextField(String value, FocusNode focusNode) {
    if (value.length == 1) {
      focusNode.requestFocus();
    }
  }

  SizedBox buildInputNode(FocusNode focusNode, FocusNode nextFocusNode, int index) {
    return SizedBox(
      width: 60,
      child: TextFormField(
        focusNode: focusNode,
        style: TextStyle(fontSize: 24),
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        decoration: otpInputDecoration,
        maxLength: 1,
        onChanged: (value) {
          if (value.isEmpty) {
            values[index] = null;
          }
          values[index] = value;
          nextField(value, nextFocusNode);
          widget.onOtpChange(values.join());
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        children: [
          SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buildInputNode(pin1FocusNode, pin2FocusNode, 0),
              buildInputNode(pin2FocusNode, pin3FocusNode, 1),
              buildInputNode(pin3FocusNode, pin4FocusNode, 2),
              buildInputNode(pin4FocusNode, pin5FocusNode, 3),
              buildInputNode(pin5FocusNode, pin6FocusNode, 4),
              SizedBox(
                width: 60,
                child: TextFormField(
                  focusNode: pin6FocusNode,
                  style: TextStyle(fontSize: 24),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  decoration: otpInputDecoration,
                  onChanged: (value) {
                    if (value.isEmpty) {
                      values[5] = null;
                    }
                    pin6FocusNode.unfocus();
                    values[5] = value;
                    widget.onOtpChange(values.join());
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
