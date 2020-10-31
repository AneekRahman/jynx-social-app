import 'package:flutter/material.dart';
import 'package:social_app/modules/MyBottomButton.dart';
import 'package:social_app/modules/constants.dart';

class UpdateDisplayNamePage extends StatefulWidget {
  @override
  _UpdateDisplayNamePageState createState() => _UpdateDisplayNamePageState();
}

class _UpdateDisplayNamePageState extends State<UpdateDisplayNamePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Text("Display Name", style: headingStyle),
                    SizedBox(height: MediaQuery.of(context).size.height * .06),
                  ],
                ),
              ),
            ),
            MyBottomButton(
              text: "Get Code",
              onTap: () {},
            )
          ],
        ),
      ),
    );
  }
}
