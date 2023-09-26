import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfo {
  Future<Map<String?, String?>> get() async {
    if (Platform.isAndroid) {
      var androidInfo = await DeviceInfoPlugin().androidInfo;
      var modelAndroid = androidInfo.model;
      return {"platform": 'android', "model": modelAndroid};
    } else if (Platform.isIOS) {
      var iosInfo = await DeviceInfoPlugin().iosInfo;
      var model = iosInfo.utsname.machine;
      return {"platform": 'ios', "model": model};
    }

    return {"platform": null, "model": null};
  }
}
