import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import 'package:social_app/models/IncomingCall.dart';
import 'package:social_app/services/rtd_service.dart';

typedef void StreamStateCallback(MediaStream stream);

class WebRTCSignaling {
  Map<String, dynamic> configuration = {
    'iceServers': [
      {
        'urls': ['stun:stun1.l.google.com:19302', 'stun:stun2.l.google.com:19302']
      }
    ]
  };

  final BuildContext rootContext;
  String? chatRoomUid;
  final User currentUser;

  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  StreamStateCallback? onAddRemoteStream;

  WebRTCSignaling({this.chatRoomUid, required this.rootContext, required this.currentUser});

  Future createRoom(RTCVideoRenderer remoteRenderer) async {
    if (chatRoomUid == null) return;

    print('Create PeerConnection with configuration: $configuration');
    peerConnection = await createPeerConnection(configuration);
    registerPeerConnectionListeners();

    // The localStream returns the video and audio of currentUser
    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

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

    // After the [peerConnection] get currentUsers Ice Candidates, save them in RTD as /caller/
    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) async {
      print('Got candidate: ${candidate.toMap()}');
      // JsonEncode the iceCandidate and save it in RTD under /caller/
      await rootContext.read<RealtimeDatabaseService>().pushIncomingCallNodeICECandidates(
            chatRoomUid: chatRoomUid!,
            iceCandidate: jsonEncode(candidate.toMap()),
            isFromCaller: true,
          );
    };

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

        // When an [answer] is available, set the remoteDescription
        if (peerConnection?.getRemoteDescription() == null && incomingCall.calleeAnswer != null) {
          var answer = RTCSessionDescription(
            incomingCall.calleeAnswer!.sdp,
            incomingCall.calleeAnswer!.type,
          );

          print("Someone tried to connect");
          await peerConnection?.setRemoteDescription(answer);
        }

        // When new calleeIceCandidates are added on /incomingCall/callee/{iceCandidateUid}, add them
        if (event.type == DocumentChangeType.added && incomingCall.calleeIceCandidates != null) {
          incomingCall.calleeIceCandidates!.iceCandidates.forEach((iceCandidate) {
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
    final roomSnapshot = await rootContext.read<RealtimeDatabaseService>().getIncomingCallSnaphsot(chatRoomUid: chatRoomUid!);

    if (roomSnapshot.exists) {
      print('Create PeerConnection with configuration: $configuration');
      peerConnection = await createPeerConnection(configuration);
      registerPeerConnectionListeners();

      // The localStream returns the video and audio of currentUser
      localStream?.getTracks().forEach((track) {
        peerConnection?.addTrack(track, localStream!);
      });

      // Code for creating SDP answer below
      final IncomingCall incomingCall = IncomingCall.fromMap(map: roomSnapshot.value as Map, chatRoomUid: chatRoomUid!);

      if (incomingCall.callerOffer != null) {
        await peerConnection?.setRemoteDescription(
          RTCSessionDescription(incomingCall.callerOffer!.sdp, incomingCall.callerOffer!.type),
        );
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

        // After the [peerConnection] gets currentUsers Ice Candidates, save them in RTD as /callee/
        peerConnection?.onIceCandidate = (RTCIceCandidate candidate) async {
          print('Got candidate: ${candidate.toMap()}');
          // JsonEncode the iceCandidate and save it in RTD under /callere/
          await rootContext.read<RealtimeDatabaseService>().pushIncomingCallNodeICECandidates(
                chatRoomUid: chatRoomUid!,
                iceCandidate: jsonEncode(candidate.toMap()),
                isFromCaller: false,
              );
        };

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
    var stream = await navigator.mediaDevices.getUserMedia({'video': true, 'audio': false});

    localVideo.srcObject = stream;
    localStream = stream;

    remoteVideo.srcObject = await createLocalMediaStream('key');
  }

  Future<void> hangUp(RTCVideoRenderer localVideo) async {
    List<MediaStreamTrack> tracks = localVideo.srcObject!.getTracks();
    tracks.forEach((track) {
      track.stop();
    });

    if (remoteStream != null) {
      remoteStream!.getTracks().forEach((track) => track.stop());
    }
    if (peerConnection != null) peerConnection!.close();

    if (chatRoomUid != null) {
      // TODO user Realtime Database for this
      var db = FirebaseFirestore.instance;
      var roomRef = db.collection('webRTCRooms').doc(chatRoomUid);
      var calleeCandidates = await roomRef.collection('calleeCandidates').get();
      calleeCandidates.docs.forEach((document) => document.reference.delete());

      var callerCandidates = await roomRef.collection('callerCandidates').get();
      callerCandidates.docs.forEach((document) => document.reference.delete());

      await roomRef.delete();
    }

    localStream!.dispose();
    remoteStream?.dispose();
  }

  void registerPeerConnectionListeners() {
    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      print('ICE gathering state changed: $state');
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      print('Connection state change: $state');
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

  void onDisposeCalled() {}
}
