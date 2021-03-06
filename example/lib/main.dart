import 'package:flutter/material.dart';
import 'package:webrtc/RTCPeerConnection.dart';
import 'package:webrtc/RTCPeerConnectionFactory.dart';
import 'package:webrtc/MediaStream.dart';
import 'package:webrtc/getUserMedia.dart';
import 'package:webrtc/RTCSessionDescrption.dart';
import 'package:webrtc/RTCVideoView.dart';
import 'package:webrtc/RTCIceCandidate.dart';
import 'dart:async';
import 'dart:core';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  MediaStream _localStream;
  RTCPeerConnection _peerConnection;
  var _width = 240.0;
  var _height = 180.0;
  var _rotation = 0;
  final _localVideoRenderer = new RTCVideoRenderer();
  final _remoteVideoRenderer = new RTCVideoRenderer();

  @override
  initState() {
    super.initState();
    initPlatformState();
    _localVideoRenderer.onVideoRotationChange = _onVideoRotationChange;
    _localVideoRenderer.onVideoSizeChange = _onVideoSizeChange;
  }

  _onVideoRotationChange(int textureId, int rotation)
  {
     setState((){
       _rotation = rotation;
     });
  }

  _onVideoSizeChange(int textureId, double width, double height){

  }

  _onSignalingState(RTCSignalingState state) {
    print(state);
  }

  _onIceGatheringState(RTCIceGatheringState state) {
    print(state);
  }

  _onIceConnectionState(RTCIceConnectionState state) {
    print(state);
  }

  _onAddStream(MediaStream stream) {
    print('addStream: ' + stream.id);
    _remoteVideoRenderer.srcObject = stream;
  }

  _onRemoveStream(MediaStream stream) {
    _remoteVideoRenderer.srcObject = null;
  }

  _onCandidate(RTCIceCandidate candidate) {
    print('onCandidate: ' + candidate.candidate);
    _peerConnection.addCandidate(candidate);
  }

  _onRenegotiationNeeded() {
    print('RenegotiationNeeded');
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  initPlatformState() async {
    final Map<String, dynamic> mediaConstraints = {
      "audio": true,
      "video": {
        "mandatory": {
          "minWidth":
              '640', // Provide your own width, height and frame rate here
          "minHeight": '480',
          "minFrameRate": '30',
        },
        "facingMode": "user",
        "optional": [],
      }
    };
    /*
    final Map<String, dynamic> mediaConstraints = {
      "audio": true,
      "video": true,
    };*/
    Map<String, dynamic> configuration = {
      "iceServers": [
        {"url": "stun:stun.l.google.com:19302"},
      ]
    };

    final Map<String, dynamic> OFFER_SDP_CONSTRAINTS = {
      "mandatory": {
        "OfferToReceiveAudio": true,
        "OfferToReceiveVideo": true,
      },
      "optional": [],
    };

    final Map<String, dynamic> LOOPBACK_CONSTRAINTS = {
      "mandatory": {},
      "optional": [
        {"DtlsSrtpKeyAgreement": false},
      ],
    };

    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      _localStream = await getUserMedia(mediaConstraints);
      await _localVideoRenderer.initialize();
      await _remoteVideoRenderer.initialize();
      _localVideoRenderer.srcObject = _localStream;

      _peerConnection =
          await createPeerConnection(configuration, LOOPBACK_CONSTRAINTS);

      _peerConnection.onSignalingState = _onSignalingState;
      _peerConnection.onIceGatheringState = _onIceGatheringState;
      _peerConnection.onIceConnectionState = _onIceConnectionState;
      _peerConnection.onAddStream = _onAddStream;
      _peerConnection.onRemoveStream = _onRemoveStream;
      _peerConnection.onIceCandidate = _onCandidate;
      _peerConnection.onRenegotiationNeeded = _onRenegotiationNeeded;

      _peerConnection.addStream(_localStream);
      RTCSessionDescrption description =
          await _peerConnection.createOffer(OFFER_SDP_CONSTRAINTS);
      print(description.sdp);
      _peerConnection.setLocalDescription(description);
      //change for loopback.
      description.type = 'answer';
      _peerConnection.setRemoteDescription(description);
    } catch (e) {
      //'Failed to get platform version.';
    }
    if (!mounted) return;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: new Text('Flutter-WebRTC example'),
        ),
        body: new Center(
            child: new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              new Text('Loopback demo.'),
              new Transform(
                child: new Container(
                  width: _width,
                  height: _height,
                  child: _remoteVideoRenderer.isInitialized
                      ? new Texture(textureId: _remoteVideoRenderer.renderId)
                      : null,
                ),
                alignment: FractionalOffset.center, // set transform origin
                transform: new Matrix4.identity()
                  ..rotateZ(_rotation * 3.1415927 / 180),
              ),
              new Text('Local video'),
              new Transform(
                child: new Container(
                  width: _width,
                  height: _height,
                  child: _remoteVideoRenderer.isInitialized
                      ? new Texture(textureId: _remoteVideoRenderer.renderId)
                      : null,
                ),
                alignment: FractionalOffset.center, // set transform origin
                transform: new Matrix4.identity()
                  ..rotateZ(90 * 3.1415927 / 180),
              ),
              new Text('Remote video'),
            ])),
      ),
    );
  }
}
