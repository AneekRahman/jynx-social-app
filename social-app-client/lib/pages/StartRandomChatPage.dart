import 'package:flutter/material.dart';
import 'package:social_app/modules/constants.dart';

class StartRandomChatPage extends StatefulWidget {
  const StartRandomChatPage({super.key});

  @override
  State<StartRandomChatPage> createState() => _StartRandomChatPageState();
}

class _StartRandomChatPageState extends State<StartRandomChatPage> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Random video chatting",
                style: TextStyle(fontSize: 18, fontFamily: HelveticaFont.Medium),
              ),
              SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(24)),
                child: Image.asset(
                  'assets/random-chat-banner1.jpg',
                  width: double.infinity,
                ),
              ),
              SizedBox(height: 30),
              Text(
                "How does this work?",
                style: TextStyle(fontSize: 14, fontFamily: HelveticaFont.Medium, color: Colors.white70),
              ),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.fromLTRB(24, 20, 24, 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF3BDDFA),
                      const Color(0xFF3EC2F9),
                    ],
                    begin: const FractionalOffset(0.0, 1.0),
                    end: const FractionalOffset(1.0, 0.0),
                    stops: [0.0, 1.0],
                    tileMode: TileMode.clamp,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "1. You will be matched with another person who is in the 'queue' in our servers.",
                      style: TextStyle(fontSize: 15, fontFamily: HelveticaFont.Medium, color: Colors.white.withOpacity(.9)),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "2. You can keep 'shuffling' through the queue to talk to different people.",
                      style: TextStyle(fontSize: 15, fontFamily: HelveticaFont.Medium, color: Colors.white.withOpacity(.9)),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "3. Your indentity will remain anonymous.",
                      style: TextStyle(fontSize: 15, fontFamily: HelveticaFont.Medium, color: Colors.white.withOpacity(.9)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              Text(
                "By tapping the button below you agree to adhere to our rules while calling other people.",
                style: TextStyle(fontSize: 12, fontFamily: HelveticaFont.Roman, color: Colors.white.withOpacity(.9)),
              ),
              SizedBox(height: 20),
              buildYellowButton(
                child: Text(
                  "Start random video call",
                  style: TextStyle(fontSize: 15, fontFamily: HelveticaFont.Bold, color: Colors.black),
                ),
                onTap: () {},
                loading: false,
                context: context,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
