import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../../modules/constants.dart';
import '../ProfilePage/MyProfilePage.dart';

class VideosCommentsModal extends StatefulWidget {
  const VideosCommentsModal({super.key});

  @override
  State<VideosCommentsModal> createState() => _VideosCommentsModalState();
}

class _VideosCommentsModalState extends State<VideosCommentsModal> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.black,
            flexibleSpace: VideosCommentsModalAppBar(),
            automaticallyImplyLeading: false,
            toolbarHeight: 30,
          ),
          _buildPostInfo(context),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return CommentBubble();
              },
            ),
          ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildPostInfo(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUsersInfoBlock(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    "As a beauty editor, I’ve jumped on many skincare trends. Some have been more helpful than others, I’ll admit. But over the years",
                    style: TextStyle(fontFamily: HelveticaFont.Roman, color: Colors.white, fontSize: 14),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
                SizedBox(height: 10),
                Text(
                  "2.4k views",
                  style: TextStyle(fontFamily: HelveticaFont.Bold, color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(width: double.infinity, height: 1, color: Colors.white.withOpacity(.2)),
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Text(
              "1k comments",
              style: TextStyle(fontFamily: HelveticaFont.Bold, color: Colors.white, fontSize: 12),
            ),
          ),
          MyCommentBox(
            setInput: (input) {},
          ),
        ],
      ),
    );
  }

  CupertinoButton _buildUsersInfoBlock(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.fromLTRB(14, 0, 14, 14),
      onPressed: () {
        // Show others profile
        showMaterialModalBottomSheet(
          backgroundColor: Colors.transparent,
          context: context,
          builder: (context) => Padding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: MyProfilePage(),
            // child: OthersProfilePage(
            //   otherUsersProfileObject: UserFirestore.fromChatRoomsInfosMem(otherPrivateChatRoomUser),
            //   showMessageButton: false,
            // ),
          ),
        );
      },
      child: Row(
        children: [
          _buildOtherUsersProfilePic(),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Aneek Rahman",
                style: TextStyle(fontFamily: HelveticaFont.Bold, color: Colors.white, fontSize: 14),
              ),
              Text(
                "@mr_rahman",
                style: TextStyle(fontFamily: HelveticaFont.Roman, color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Container _buildOtherUsersProfilePic() {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(10000),
        border: Border.all(color: Colors.yellow, width: 2),
      ),
      child:
          // otherPrivateChatRoomUser.url.isNotEmpty
          //     ? ClipRRect(
          //         child: Image.network(
          //           otherPrivateChatRoomUser.url,
          //           height: 45,
          //           width: 45,
          //           fit: BoxFit.cover,
          //         ),
          //         borderRadius: BorderRadius.all(Radius.circular(100)),
          //       ):
          Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.1),
          borderRadius: BorderRadius.circular(10000),
        ),
      ),
    );
  }
}

class VideosCommentsModalAppBar extends StatelessWidget {
  const VideosCommentsModalAppBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 36,
            ),
          ),
          SizedBox(width: 10),
          Text("Posted ", style: TextStyle(fontFamily: HelveticaFont.Roman)),
          Text("29 days ago", style: TextStyle(fontFamily: HelveticaFont.Bold)),
        ],
      ),
    );
  }
}

class MyCommentBox extends StatelessWidget {
  final Function(String) _setInput;

  const MyCommentBox({
    required Function(String) setInput,
    Key? key,
  })  : _setInput = setInput,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            margin: EdgeInsets.only(left: 14, right: 14),
            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)),
            child: TextField(
              maxLines: 5,
              minLines: 1,
              autofocus: true,
              style: TextStyle(fontSize: 14, color: Colors.white, height: 1.3),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(14.0),
                hintText: 'Comment here...',
              ),
              onSubmitted: (input) {
                _setInput(input);
              },
            ),
          ),
        ),
        CupertinoButton(
          padding: EdgeInsets.all(0),
          onPressed: () async {},
          child: Image.asset("assets/icons/Send-icon.png", height: 30, width: 30),
        ),
        SizedBox(width: 14),
      ],
    );
  }
}

class CommentBubble extends StatelessWidget {
  const CommentBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)),
              padding: EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 30,
                    width: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.1),
                      borderRadius: BorderRadius.circular(10000),
                    ),
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text("@anonymous", style: TextStyle(fontFamily: HelveticaFont.Roman)),
                          SizedBox(width: 10),
                          Text("3 days ago", style: TextStyle(fontFamily: HelveticaFont.Roman, color: Colors.white54)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text("Hey, this is an amazing video!", style: TextStyle(fontFamily: HelveticaFont.Roman)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 10),
          Column(
            children: [
              CupertinoButton(
                padding: EdgeInsets.all(0),
                minSize: 30,
                onPressed: () {},
                child: Opacity(
                  child: Image.asset("assets/icons/Like-icon.png", height: 20),
                  opacity: .8,
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.all(0),
                minSize: 30,
                onPressed: () {},
                child: Opacity(
                  child: Image.asset("assets/icons/Dislike-icon.png", height: 20),
                  opacity: .8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
