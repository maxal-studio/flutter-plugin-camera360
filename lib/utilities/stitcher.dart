import 'dart:ffi';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:camera_360/camera_360_bindings_generated.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class Stitcher {
  // Stitch the images
  static Future<XFile> stitchImages(List<XFile> images, bool cropped) async {
    // For Android, you call DynamicLibrary to find and open the shared library
    // You don't need to do this in iOS since all linked symbols map when an app runs.
    final dylib = Platform.isAndroid
        ? DynamicLibrary.open("libcamera_360.so")
        : DynamicLibrary.process();

    List<String> imagePaths = [];
    imagePaths = images.map((imageFile) {
      return imageFile.path;
    }).toList();
    imagePaths.toString().toNativeUtf8();
    debugPrint(imagePaths.toString());

    // Bindings
    final Camera360Bindings bindings = Camera360Bindings(dylib);

    String dirpath =
        "${(await getApplicationDocumentsDirectory()).path}/stitched-panorama-${DateTime.now().millisecondsSinceEpoch}.jpg";

    bool isStiched = bindings.stitch(
        imagePaths.toString().toNativeUtf8() as Pointer<Char>,
        dirpath.toNativeUtf8() as Pointer<Char>,
        cropped);

    if (!isStiched) {
      throw Exception('Stiching failed');
    }

    // Return the stiched image
    return XFile(dirpath);
  }
}
