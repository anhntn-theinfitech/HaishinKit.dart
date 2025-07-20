import 'package:get/get.dart';

class AppController extends GetxController {
  var isCameraOn = true.obs;
  var streamUrl = ''.obs;
  var streamKey = ''.obs;

  void toggleCamera() {
    isCameraOn.value = !isCameraOn.value;
    update();
  }
  void setStreamUrl(String url) {
    streamUrl.value = url;
    update();
  }
  void setStreamKey(String key) {
    streamKey.value = key;
    update();
  }
}