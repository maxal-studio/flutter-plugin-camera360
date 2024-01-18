import 'package:camera_360/camera_360.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gallery_saver/gallery_saver.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('360 Camera App'),
        ),
        body: const CameraPage(),
      ),
    );
  }
}

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  int progressPecentage = 0;

  @override
  Widget build(BuildContext context) {
    void displayPanoramaMessage(context, String message) {
      final snackBar = SnackBar(
        content: Text(message),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }

    return Stack(
      children: [
        Camera360(
          // Text shown while panorama image is being prepared
          userLoadingText: "Preparing panorama...",
          // Text shown on while taking the first image
          userHelperText: "Point the camera at the dot",
          // Text shown when user should tilt the device to the left
          userHelperTiltLeftText: "Tilt left",
          // Text shown when user should tilt the device to the right
          userHelperTiltRightText: "Tilt Right",
          // Suggested key for iPhone >= 11 is 2 to select the wide-angle camera
          // On android devices 0 is suggested as at the moment Camera switching is not possible on android
          userSelectedCameraKey: 2,
          // Camera selector Visibilitiy
          cameraSelectorShow: true,
          // Camera selector Info Visibilitiy
          cameraSelectorInfoPopUpShow: true,
          // Camera selector Info Widget
          cameraSelectorInfoPopUpContent: const Column(
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  "Notice: This feature only works if your phone has a wide angle camera.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xffDB4A3C),
                  ),
                ),
              ),
              Text(
                "Select the camera with the widest viewing angle below.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xffEFEFEF),
                ),
              ),
            ],
          ),
          // Callback function called when 360 capture ended
          onCaptureEnded: (data) {
            if (data['success'] == true) {
              // Save image to the gallery
              XFile panorama = data['panorama'];
              GallerySaver.saveImage(panorama.path);
              displayPanoramaMessage(context, 'Panorama saved!');
            } else {
              displayPanoramaMessage(context, 'Panorama failed!');
            }
            print(data);
          },
          // Callback function called when the camera lens is changed
          onCameraChanged: (cameraKey) {
            displayPanoramaMessage(
                context, "Camera changed ${cameraKey.toString()}");
          },
          // Callback function called when capture progress is changed
          onProgressChanged: (newProgressPercentage) {
            debugPrint(
                "'Panorama360': Progress changed: $newProgressPercentage");
            setState(() {
              progressPecentage = newProgressPercentage;
            });
          },
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              "Progress: $progressPecentage",
              style: const TextStyle(
                  color: Colors.white, backgroundColor: Colors.black),
            )
          ],
        ),
      ],
    );
  }
}
