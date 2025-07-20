import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haishin_kit/audio_settings.dart';
import 'package:haishin_kit/audio_source.dart';
import 'package:haishin_kit/capture_settings.dart';
import 'package:haishin_kit/net_stream_drawable_texture.dart';
import 'package:haishin_kit/rtmp_connection.dart';
import 'package:haishin_kit/rtmp_stream.dart';
import 'package:haishin_kit/video_settings.dart';
import 'package:haishin_kit/video_source.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app_controller.dart';

class ScreenView extends StatefulWidget {
  const ScreenView({Key? key}) : super(key: key);

  @override
  State<ScreenView> createState() => _MyAppState();
}

class _MyAppState extends State<ScreenView> with AutomaticKeepAliveClientMixin {
  RtmpConnection? _connection;
  RtmpStream? _stream;
  bool _recording = false;
  String _mode = "publish";
  CameraPosition currentPosition = CameraPosition.back;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  void dispose() {
    _stream?.dispose();
    _connection?.dispose();
    super.dispose();
  }

  Future<void> initPlatformState() async {
    await Permission.camera.request();
    await Permission.microphone.request();

    // Set up AVAudioSession for iOS.
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.allowBluetooth,
    ));

    RtmpConnection connection = await RtmpConnection.create();
    connection.eventChannel.receiveBroadcastStream().listen((event) {
      print("event: ${event["data"]?["code"]}");
      switch (event["data"]?["code"]) {
        case 'NetConnection.Connect.Success':
          if (_mode == "publish") {
            AppController appController = Get.find<AppController>();
            print(">>> Stream Key: ${appController.streamKey.value}");
            _stream?.publish(appController.streamKey.value);
          } else {
            _stream?.play("live_666701106_nwUDsBVyy1ooM9SkHRjnyDfLVjYdJ9");
          }
          setState(() {
            _recording = true;
          });
          break;
        case "SpeedStatistics":
          print("outSpeed（KB/s）:");
          print(event["data"]?["outSpeedInByte"] / 1000);
          print("inSpeed（KB/s）:");
          print(event["data"]?["inSpeedInByte"] / 1000);
          break;
      }
    });

    RtmpStream stream = await RtmpStream.create(connection);
    stream.audioSettings = AudioSettings(muted: false, bitrate: 64 * 1000);
    stream.videoSettings = VideoSettings(
      width: 720,
      height: 1280,
      bitrate: 3000 * 1000,
    );
    stream.attachAudio(AudioSource());
    stream.attachVideo(VideoSource(position: currentPosition));
    stream.captureSettings = CaptureSettings(
      continuousAutofocus: false,
      continuousExposure: false,
      fps: 60,
      sessionPreset: AVCaptureSessionPreset.medium,
    );

    stream.videoSettings = VideoSettings(
      width: 720,
      height: 1280,
      bitrate: 3000 * 1000,
      profileLevel: ProfileLevel.H264ConstrainedHighAutoLevel,
      frameInterval: 4,
    );
    if (!mounted) return;

    setState(() {
      _connection = connection;
      _stream = stream;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stream View'), actions: [
        IconButton(
          icon: const Icon(Icons.play_arrow),
          onPressed: () {
            if (_mode == "publish") {
              _mode = "playback";
              _stream?.attachVideo(null);
              _stream?.attachAudio(null);
            } else {
              _mode = "publish";
              print("publish");
              _stream?.attachAudio(AudioSource());
              _stream?.attachVideo(VideoSource(position: currentPosition));
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.flip_camera_android),
          onPressed: () {
            if (currentPosition == CameraPosition.front) {
              currentPosition = CameraPosition.back;
            } else {
              currentPosition = CameraPosition.front;
            }
            _stream?.attachVideo(VideoSource(position: currentPosition));
          },
        )
      ]),
      body: Center(
        child: _stream == null
            ? const Text("")
            : NetStreamDrawableTexture(_stream),
      ),
      floatingActionButton: FloatingActionButton(
        child: _recording
            ? const Icon(Icons.fiber_smart_record)
            : const Icon(Icons.not_started),
        onPressed: () {
          onStartStream();
        },
      ),
    );
  }

  void onStartStream() {
    if (_recording) {
      _connection?.close();
      setState(() {
        _recording = false;
      });
    } else {
      AppController appController = Get.find<AppController>();
      String streamUrl = appController.streamUrl.value;
      String streamKey = appController.streamKey.value;
      if (streamUrl.isNotEmpty && streamKey.isNotEmpty) {
        _connection?.connect(streamUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Stream Url & Stream Key can not be null: \nURL = $streamUrl \nKey = $streamKey')),
        );
      }
    }
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}
