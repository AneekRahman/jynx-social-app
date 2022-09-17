import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import 'package:social_app/models/IncomingCall.dart';
import 'package:social_app/services/rtd_service.dart';

typedef void StreamStateCallback(MediaStream stream);
typedef void OnPeerConnectionStateCallback(RTCPeerConnectionState state);

class WebRTCSignaling {
  Map<String, dynamic> configuration = {
    'iceServers': [
      {
        'urls': ['stun:stun1.l.google.com:19302', 'stun:stun2.l.google.com:19302']
      }
    ]
  };
  final Map<String, dynamic> offerSdpConstraints = {
    "mandatory": {
      "OfferToReceiveAudio": true,
      "OfferToReceiveVideo": true,
    },
    "optional": [],
  };

  final BuildContext rootContext;
  String? chatRoomUid;
  final User currentUser;

  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  StreamStateCallback? onAddRemoteStream;
  OnPeerConnectionStateCallback? onPeerConnectionStateCallback;

  bool _alreadyAddedAnswer = false;
  bool _startedOrAccepted = false;

  WebRTCSignaling({this.chatRoomUid, required this.rootContext, required this.currentUser});

  Future createRoom(RTCVideoRenderer remoteRenderer) async {
    if (_startedOrAccepted) return;
    _startedOrAccepted = true;

    print('Create PeerConnection with configuration: $configuration');
    peerConnection = await createPeerConnection(configuration, offerSdpConstraints);
    registerPeerConnectionListeners();

    // The localStream returns the video and audio of currentUser
    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

    // After the [peerConnection] get currentUsers Ice Candidates, save them in RTD as /caller/
    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) async {
      // JsonEncode the iceCandidate and save it in RTD under /caller/
      await rootContext.read<RealtimeDatabaseService>().pushIncomingCallNodeICECandidates(
            chatRoomUid: chatRoomUid!,
            iceCandidate: jsonEncode(candidate.toMap()),
            isFromCaller: true,
          );
    };

    // Create an [offer] and save it in RTD as /caller/
    RTCSessionDescription offer = await peerConnection!.createOffer();
    // Set the local description
    await peerConnection!.setLocalDescription(offer);

    // Create a usable map (with all the needed things) that is parsable
    Map<String, dynamic> offerMapForRTD = {'type': offer.type, 'sdp': offer.sdp};

    // Create a offer string to save in RTD
    await rootContext.read<RealtimeDatabaseService>().createIncomingCallNode(
          chatRoomUid: chatRoomUid!,
          callerUid: currentUser.uid,
          offer: jsonEncode(offerMapForRTD),
        );

    // When a track comes from remote connection add it in [remoteStream]
    peerConnection?.onTrack = (RTCTrackEvent event) {
      print('Got remote track: ${event.streams[0]}');
      event.streams[0].getTracks().forEach((track) {
        print('Add a track to the remoteStream $track');
        remoteStream?.addTrack(track);
      });
    };

    // Listening for [answer] remote session description and added new [calleeIceCandidates]
    rootContext.read<RealtimeDatabaseService>().getIncomingCallStream(chatRoomUid: chatRoomUid!).listen((event) async {
      if (event.snapshot.exists) {
        IncomingCall incomingCall = IncomingCall.fromMap(map: event.snapshot.value as Map, chatRoomUid: chatRoomUid!);
        print("GOT: a new getIncomingCallStream event: ${incomingCall.calleeAnswer}");

        // When an [answer] is available, set the remoteDescription
        if (peerConnection?.getRemoteDescription() != null && incomingCall.calleeAnswer != null && !_alreadyAddedAnswer) {
          _alreadyAddedAnswer = true;
          print("GOT: adding calleeAnswer!");
          var answer = RTCSessionDescription(
            incomingCall.calleeAnswer!.sdp,
            incomingCall.calleeAnswer!.type,
          );
          await peerConnection?.setRemoteDescription(answer);
        }

        // When new calleeIceCandidates are added on /incomingCall/callee/{iceCandidateUid}, add them
        if (incomingCall.calleeIceCandidates != null) {
          incomingCall.calleeIceCandidates!.iceCandidates.forEach((iceCandidate) {
            print("GOT: adding calleeIceCandidates!");
            peerConnection!.addCandidate(
              RTCIceCandidate(
                iceCandidate.candidate,
                iceCandidate.sdpMid,
                iceCandidate.sdpMLineIndex,
              ),
            );
          });
        }
      }
    });
  }

  Future<void> joinRoom(RTCVideoRenderer remoteVideo) async {
    if (_startedOrAccepted) return;
    _startedOrAccepted = true;

    final roomSnapshot = await rootContext.read<RealtimeDatabaseService>().getIncomingCallSnaphsot(chatRoomUid: chatRoomUid!);
    if (roomSnapshot.exists) {
      print('Create PeerConnection with configuration: $configuration');
      peerConnection = await createPeerConnection(configuration, offerSdpConstraints);
      registerPeerConnectionListeners();

      // The localStream returns the video and audio of currentUser
      localStream?.getTracks().forEach((track) {
        peerConnection?.addTrack(track, localStream!);
      });

      // Code for creating SDP answer below
      final IncomingCall incomingCall = IncomingCall.fromMap(map: roomSnapshot.value as Map, chatRoomUid: chatRoomUid!);

      if (incomingCall.callerOffer != null) {
        // First set the remote description as the callers [offer]
        await peerConnection?.setRemoteDescription(
          RTCSessionDescription(incomingCall.callerOffer!.sdp, incomingCall.callerOffer!.type),
        );

        // After the [peerConnection] gets currentUsers Ice Candidates, save them in RTD as /callee/
        peerConnection?.onIceCandidate = (RTCIceCandidate candidate) async {
          // JsonEncode the iceCandidate and save it in RTD under /caller/
          await rootContext.read<RealtimeDatabaseService>().pushIncomingCallNodeICECandidates(
                chatRoomUid: chatRoomUid!,
                iceCandidate: jsonEncode(candidate.toMap()),
                isFromCaller: false,
              );
        };

        final answer = await peerConnection!.createAnswer();
        await peerConnection!.setLocalDescription(answer);
        print('Created Answer $answer');

        // Create a usable map (with all the needed things) that is parsable
        Map<String, dynamic> answerMapForRTD = {'type': answer.type, 'sdp': answer.sdp};

        // Update the answer string in RTD
        await rootContext.read<RealtimeDatabaseService>().answerIncomingCallNode(
              chatRoomUid: chatRoomUid!,
              calleeUid: currentUser.uid,
              answer: jsonEncode(answerMapForRTD),
            );

        // When a track comes from remote connection add it in [remoteStream]
        peerConnection?.onTrack = (RTCTrackEvent event) {
          print('Got remote track: ${event.streams[0]}');
          event.streams[0].getTracks().forEach((track) {
            print('Add a track to the remoteStream: $track');
            remoteStream?.addTrack(track);
          });
        };

        // Listening for added new [callerIceCandidates] of caller
        rootContext.read<RealtimeDatabaseService>().getIncomingCallStream(chatRoomUid: chatRoomUid!).listen((event) async {
          if (event.snapshot.exists) {
            IncomingCall incomingCall = IncomingCall.fromMap(map: event.snapshot.value as Map, chatRoomUid: chatRoomUid!);

            // When new callerIceCandidates are added on /incomingCall/caller/{iceCandidateUid}, add them
            if (event.type == DocumentChangeType.added && incomingCall.callerIceCandidates != null) {
              incomingCall.callerIceCandidates!.iceCandidates.forEach((iceCandidate) {
                peerConnection!.addCandidate(
                  RTCIceCandidate(
                    iceCandidate.candidate,
                    iceCandidate.sdpMid,
                    iceCandidate.sdpMLineIndex,
                  ),
                );
              });
            }
          }
        });
      }
    }
  }

  Future<void> openUserMedia(
    RTCVideoRenderer localVideo,
    RTCVideoRenderer remoteVideo,
  ) async {
    var stream = await navigator.mediaDevices.getUserMedia({'video': true, 'audio': true});

    localVideo.srcObject = stream;
    localStream = stream;

    remoteVideo.srcObject = await createLocalMediaStream('key');
  }

  Future<void> hangUp(RTCVideoRenderer localVideo) async {
    if (!_startedOrAccepted) return;

    localStream!.getTracks().forEach((track) => track.stop());

    if (remoteStream != null) {
      remoteStream!.getTracks().forEach((track) => track.stop());
    }

    if (peerConnection != null) {
      peerConnection!.close();
      peerConnection!.dispose();
    }

    RealtimeDatabaseService(FirebaseDatabase.instance).deleteIncomingCallNode(chatRoomUid: chatRoomUid!);

    localStream!.dispose();
    remoteStream?.dispose();

    _startedOrAccepted = false;
  }

  void registerPeerConnectionListeners() {
    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      print('ICE gathering state changed: $state');
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      print('Connection state change: $state');
      onPeerConnectionStateCallback?.call(state);
    };

    peerConnection?.onSignalingState = (RTCSignalingState state) {
      print('Signaling state change: $state');
    };

    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      print('ICE connection state change: $state');
    };

    peerConnection?.onAddStream = (MediaStream stream) {
      print("Add remote stream");
      onAddRemoteStream?.call(stream);
      remoteStream = stream;
    };
  }
}
