import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_controller.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _streamUrlController = TextEditingController();
  final TextEditingController _streamKeyController = TextEditingController();
  late final AppController _appController;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _appController = Get.find<AppController>();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _streamUrlController,
            decoration: const InputDecoration(
              labelText: 'StreamUrl',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _streamKeyController,
            decoration: const InputDecoration(
              labelText: 'StreamKey',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              final url = _streamUrlController.text;
              final key = _streamKeyController.text;
              _appController.setStreamUrl(url);
              _appController.setStreamKey(key);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Submitted: URL=$url, Key=$key')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}
