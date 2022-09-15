import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:social_app/models/P2PCallQueue.dart';
import 'package:social_app/modules/constants.dart';
import 'package:social_app/services/rtd_service.dart';

class RandomVideoCallPage extends StatefulWidget {
  final User currentUser;
  const RandomVideoCallPage({super.key, required this.currentUser});

  @override
  State<RandomVideoCallPage> createState() => _RandomVideoCallPageState();
}

class _RandomVideoCallPageState extends State<RandomVideoCallPage> {
  // When this user is waiting for someone to accept his [offer] then shouldCreateOfferFirst = true. Otherwise the user will actively
  // keep fetching /p2pCallQueue/ for a user who is not occupied
  bool shouldCreateOfferFirst = false;
  // When user is not yet in a call and searching for a match this will be true. User can opt to stop searching for a match.
  bool _searchingForMatch = false;
  // When user is searching for a match, or has just stopped calling this will be true
  bool _inACall = false;

  // Should the user wait for someone to connect or connect himself
  Timer? _retryTimer;
  StreamSubscription<DatabaseEvent>? _ownP2PQueueListener;

  Future<bool> _checkCamMicPermission() async {
    final _camPermStatus = await Permission.camera.status;
    final _micPermStatus = await Permission.microphone.status;
    if (_camPermStatus.isGranted && _micPermStatus.isGranted) return true;

    return false;
  }

  Future _createP2PQueue() async {
    // 1. First create the node in /p2pCallQueue/[currentUserUid] and set the [offer] and listen in with a stream

    // 2. Set the onDisconnect node to delete the created /p2pCallQueue/ node if currentUser leaves this page

    // 3. Wait for 1.5 seconds to check if any otherUser tries to connect to currentUsers node in /p2pCallQueue/

    // 4. If someone connects to currentUsers node in /p2pCallQueue/[currentUserUid] where currentUsers [offer] exists
    //    and otherUser sets [occBy] = otherUsersUid, [occ] = true for currentUsers node as well as otherUsers own node,
    //    then get otherUsers node from /p2pCallQueue/[otherUserUid]. Since, currentUsers [offer] was accepted by otherUser,
    //    currentUser needs to wait for otherUsers [answer] in otherUsers node in /p2pCallQueue/[otherUserUid] to set it.

    // 5. If no one tries to connect to our /p2pCallQueue/[currentUserUid], search for another user who isn't occupied to connect to theirs.
    //    After finding an otherUser with [occ] = false, with a transaction first set [occBy] = currentUsersUid, [occ] = true in
    //    otherUsers /p2pCallQueue/[otherUserUid]. Also, set [occBy] = otherUsersUid, [occ] = true in currentUsers /p2pCallQueue/[currentUserUid].
    //    Since no one else can now connect to currentUsers or otherUsers node in /p2pCallQueue/ we can proceed to accept the [offer]
    //    from otherUsers /p2pCallQueue/[otherUserUid]. After accepting the offer, generate an answer and set it in currentUsers
    //    node in /p2pCallQueue/[currentUserUid]. The otherUser will listen to currentUsers node to accept the "answer" in currentUser node.

    // First create the queue node in /p2pCallQueue/worldwide/[currentUserUid]
  }

  Future _initSearchingForAMatch() async {
    final allPermGranted = await _checkCamMicPermission();

    if (allPermGranted) {
      // Randomly select if currentUser should be the first to create an [offer]
      shouldCreateOfferFirst = new Random().nextInt(2) == 0;

      // TODO use shouldCreateOfferFirst to only select either the role of offerer or answerer for this user.
      // TODO remove the swtitching between [_initRetryTimer] and [_listenOwnP2PQueueStream]

      if (shouldCreateOfferFirst) {
        // Create a queue in /p2pCallQueue/[currentUserUid]
        // TODO Remember to delete this if switching to actively looking for a queue
        await context.read<RealtimeDatabaseService>().createOwnP2PQueueNode(userUid: widget.currentUser.uid);
        // After creating own queue, listen to it
        _listenOwnP2PQueueStream();
      } else {
        // For 4 seconds keep trying to get an [offer] from otherUsers /p2pCallQueue/[otherUserUid]
        await context.read<RealtimeDatabaseService>().deleteP2PQueue(currentUserUid: widget.currentUser.uid);
        // Due to the -1 second delay, the searching of [_initRetryTimer] will be behind the switch [_initOffererOrAnswererSwitcher]
        Future.delayed(Duration(milliseconds: 10)).then((a) {
          _initRetryTimer();
        });
      }
    }
  }

  /// Will only run when [shouldCreateOfferFirst] = true
  void _listenOwnP2PQueueStream() {
    // TODO try to remove this. Only keep either listening or requesting.
    // Listen for when an [answer] is added by otherUsers after they accept currentUsers [offer].
    _ownP2PQueueListener =
        context.read<RealtimeDatabaseService>().getOwnP2PQueueStream(userUid: widget.currentUser.uid).listen((DatabaseEvent event) {
      if (!_inACall && shouldCreateOfferFirst && _searchingForMatch && event.snapshot.exists) {
        // Check if [answer] is available for this DatabaseEvent
        final P2PCallQueue p2pCallQueue = P2PCallQueue.fromMap(event.snapshot.value as Map, userUid: event.snapshot.key!);
        if (p2pCallQueue.answer != null) {
          _inACall = true;
          _searchingForMatch = false;
          // TODO Accept the [answer] here
        }
      }
    });
  }

  /// Will only run when [shouldCreateOfferFirst] = false
  void _initRetryTimer() {
    _retryTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
      // When
      if (!_inACall && !shouldCreateOfferFirst && _searchingForMatch) {
        print("GOT: _initRetryTimer after 3 seconds");
      }
    });
  }

  Future _tryAnswerOthersOffer() async {
    try {
      // First get a random and not occupied queue call sapshot
      DataSnapshot randomQueueSnapshot = await context.read<RealtimeDatabaseService>().getRandomP2PQueue();

      // TODO First create the answer and then try to set the transaction
      // Then try to accept that call with a transaction
      TransactionResult transactionResult = await context
          .read<RealtimeDatabaseService>()
          .transactionP2PAnswer(randomQueueSnapshot: randomQueueSnapshot, currentUserUid: widget.currentUser.uid);

      if (transactionResult.committed) {
        _inACall = true;
        _searchingForMatch = false;

        // TODO
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    // TODO Do this after the renderers are ready
    _initSearchingForAMatch();

    super.initState();
  }

  @override
  void dispose() {
    if (_retryTimer != null) _retryTimer!.cancel();
    if (_ownP2PQueueListener != null) _ownP2PQueueListener!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Container(),
          ),
          PermissionRequiredMsg(
            onChange: () {
              _initSearchingForAMatch();
            },
          ),
          Expanded(
            child: Column(
              children: [
                WebRTCChatBox(),
                ContolsBar(
                    searchingForMatch: _searchingForMatch,
                    inACall: _inACall,
                    onNextPressed: () {
                      setState(() {
                        _searchingForMatch = !_searchingForMatch;
                      });
                    }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PermissionRequiredMsg extends StatefulWidget {
  final Function onChange;
  const PermissionRequiredMsg({
    Key? key,
    required this.onChange,
  }) : super(key: key);

  @override
  State<PermissionRequiredMsg> createState() => _PermissionRequiredMsgState();
}

class _PermissionRequiredMsgState extends State<PermissionRequiredMsg> with WidgetsBindingObserver {
  PermissionStatus _micAndCamPermStatus = PermissionStatus.granted;
  String? _permissionStatusMsg = null;
  bool _comingBackFromSettings = false;

  Future getPermissionStatus(bool requestPermission) async {
    if (requestPermission) {
      await Permission.camera.request();
      await Permission.microphone.request();
    }
    final _camPermStatus = await Permission.camera.status;
    final _micPermStatus = await Permission.microphone.status;

    if (_camPermStatus.isGranted && _micPermStatus.isGranted) {
      _micAndCamPermStatus = PermissionStatus.granted;
    } else if (_camPermStatus.isDenied || _micPermStatus.isDenied) {
      // We didn't ask for permission yet or the permission has been denied before but not permanently.
      _permissionStatusMsg = "Permission for camera or audio was denied. These are required if you want to video chat with others.";
      _micAndCamPermStatus = PermissionStatus.denied;
    } else if (_camPermStatus.isPermanentlyDenied || _micPermStatus.isPermanentlyDenied) {
      _permissionStatusMsg =
          "Permission for camera or audio was permenantly denied. Please open the settings and allow these permissions to video chat with others.";
      _micAndCamPermStatus = PermissionStatus.permanentlyDenied;
    }
    if (mounted) setState(() {});
    widget.onChange();
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    getPermissionStatus(true);
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _comingBackFromSettings) {
      getPermissionStatus(false);
      print("GOT AppLifecycleState.resumed");
      _comingBackFromSettings = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return !_micAndCamPermStatus.isGranted
        ? Container(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  "Permission required:",
                  style: TextStyle(fontFamily: HelveticaFont.Medium, fontSize: 20),
                ),
                SizedBox(height: 10),
                Text(
                  _permissionStatusMsg != null ? _permissionStatusMsg! : "Allow the permissions to chat.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: HelveticaFont.Medium, fontSize: 14),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      style: ButtonStyle(
                        shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(100)))),
                        backgroundColor: MaterialStateProperty.all(Colors.yellow),
                        padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 18)),
                      ),
                      onPressed: () async {
                        getPermissionStatus(true);
                      },
                      child: Text("Allow Permissions", style: TextStyle(color: Colors.black)),
                    ),
                    SizedBox(width: 10),
                    TextButton(
                      style: ButtonStyle(
                        shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(100)))),
                        backgroundColor: MaterialStateProperty.all(Colors.yellow),
                        padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 18)),
                      ),
                      onPressed: () async {
                        _comingBackFromSettings = true;
                        openAppSettings();
                      },
                      child: Text("Open Settings", style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
              ],
            ),
          )
        : SizedBox();
  }
}

class WebRTCChatBox extends StatelessWidget {
  const WebRTCChatBox({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Theme(
        data: ThemeData.light(),
        child: Container(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                color: Colors.black.withOpacity(.05),
                padding: EdgeInsets.all(6),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        maxLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(fontFamily: HelveticaFont.Medium, fontSize: 16),
                        maxLength: 200,
                        decoration: InputDecoration(
                          counterText: "",
                          contentPadding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),
                          hintText: 'Say hi...',
                          hintStyle: TextStyle(fontFamily: HelveticaFont.Medium, fontSize: 16),
                          border: InputBorder.none,
                        ),
                        onChanged: ((value) {}),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {},
                      icon: Image.asset("assets/icons/Send-icon.png", height: 30, width: 30),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: double.infinity),
                      Text("Connected to someone from...", style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ContolsBar extends StatelessWidget {
  final bool searchingForMatch;
  final bool inACall;
  final Function onNextPressed;
  const ContolsBar({super.key, required this.searchingForMatch, required this.inACall, required this.onNextPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: TextButton(
        style: ButtonStyle(
          shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
          backgroundColor: MaterialStateProperty.all(Colors.pink),
          padding: MaterialStateProperty.all(EdgeInsets.all(18)),
        ),
        onPressed: () {
          onNextPressed();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            searchingForMatch
                ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Icon(inACall ? Icons.stop_circle_rounded : Icons.video_label_rounded, size: 24, color: Colors.white),
            SizedBox(width: 16),
            Text(
              inACall ? "Stop Chatting" : "Start VidChatting",
              style: TextStyle(color: Colors.white, fontFamily: HelveticaFont.Medium, fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
