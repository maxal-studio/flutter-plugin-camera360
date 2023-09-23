import 'package:camera_360/layouts/device_rotation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:motion_sensors/motion_sensors.dart';
import 'dart:async';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'dart:math';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:wakelock/wakelock.dart';

import 'camera_360_bindings_generated.dart';

class Camera extends StatefulWidget {
  // const Camera({super.key});
  final void Function(Map<String, dynamic>) onCaptureEnded;
  final void Function(int)? onCameraChanged;
  final int? userSelectedCameraKey;
  final int? userNrPhotos;
  final int? userCapturedImageWidth;
  final int? userCapturedImageQuality;
  final double? userDeviceVerticalCorrectDeg;

  const Camera({
    Key? key,
    required this.onCaptureEnded,
    this.onCameraChanged,
    this.userSelectedCameraKey = 0,
    this.userNrPhotos = 16,
    this.userCapturedImageWidth = 1500,
    this.userCapturedImageQuality = 50,
    this.userDeviceVerticalCorrectDeg = 75,
  }) : super(key: key);

  @override
  State<Camera> createState() => _CameraState();
}

// THE STATE IS BEING UPDATED EVERY SET SECONDS
// The state is updated by this function _setupSensors
class _CameraState extends State<Camera> {
  late List<CameraDescription> cameras;
  late CameraController controller;
  bool _isReady = false;
  double posX = 180, posY = 350;
  final Vector3 _absoluteOrientation = Vector3.zero();
  final List<StreamSubscription<dynamic>> _streamSubscriptions =
      <StreamSubscription<dynamic>>[];

  // CONSTANTS
  // Centered dot
  static const double centeredDotRadius = 30;
  static const double centeredDotBorder = 2;

  // Helper dot
  double deviceVerticalCorrectDeg = 75;
  static const double helperDotRadius = 20;
  bool helperDotVerticalInPos = false;
  static const double helperDotVerticalTolerance = 1; // *2
  static const double helperDotHorizontalTolerance = 2; // *2
  static const double helperDotRotationTolerance = 4; // *2

  // System Variables (Some of these variables can be updated via the Constructor)
  late int capturedImageWidth;
  late int capturedImageQuality;
  late int nrPhotos;
  late double degreesPerPhotos;
  late double goBackDegrees;
  late double degToNextPosition;

  // VARIABLES
  List<XFile> capturedImages = [];
  // This value will be updated with the deg the phone must move horizontally
  double horizontalMovementNeeded = 0;
  double lastSuccessHorizontalPosition = 0; // H Deg on last success image taken
  bool helperDotIsHorizontalInPos = false;
  double? helperDotHorizontalReach;
  List rightRanges = [];
  double? deviceHorizontalDegInitial;
  bool deviceInCorrectPosition = false;
  bool takingPicture = false;
  bool hasStitchingFailed = false;
  int selectedCameraKey = 0;

  int nrPhotosTaken = 0;
  late XFile testStichingImage; // Stitched panorama image
  late XFile finalStitchedImage; // Stitched panorama image
  bool imageSaved = false;
  bool isPanoramaBeingStitched = false;
  bool lastPhoto = false;
  bool lastPhotoTaken = false;

  @override
  void initState() {
    super.initState();

    // Updating System Variables depending on User Variables
    deviceVerticalCorrectDeg = widget.userDeviceVerticalCorrectDeg ?? 75;
    capturedImageWidth = widget.userCapturedImageWidth ?? 1000;
    capturedImageQuality = widget.userCapturedImageQuality ?? 50;
    nrPhotos = widget.userNrPhotos ?? 16;
    degreesPerPhotos = 360 / nrPhotos;
    goBackDegrees = (20 * degreesPerPhotos / 100) * -1; // 20% back
    degToNextPosition = 360 / nrPhotos;
    selectedCameraKey = widget.userSelectedCameraKey ?? 0;

    _setupSensors();
    _setupCameras();
  }

  // Reset Main
  Future<void> restartApp() async {
    debugPrint("Restarting app");

    // Delete all images
    await deletePanoramaImages().whenComplete(() {
      capturedImages = [];
      horizontalMovementNeeded =
          0; // This value will be updated with the deg the phone must move horizontally
      lastSuccessHorizontalPosition = 0; // H Deg on last success image taken
      helperDotIsHorizontalInPos = false;
      helperDotHorizontalReach = null;
      rightRanges = [];
      deviceHorizontalDegInitial = null;
      deviceInCorrectPosition = false;
      takingPicture = false;
      hasStitchingFailed = false;
      nrPhotosTaken = 0;
      imageSaved = false;
      isPanoramaBeingStitched = false;
      lastPhoto = false;
      lastPhotoTaken = false;
    });
  }

  // Remove last captured image
  Future<void> removeLastCapturedImage() async {
    try {
      if (await File(capturedImages[capturedImages.length - 1].path).exists()) {
        await File(capturedImages[capturedImages.length - 1].path).delete();
      }
    } catch (e) {
      // Error in getting access to the file.
      debugPrint("Failed Deleting panorama image");
    }

    // Remove from list
    capturedImages.removeAt(capturedImages.length - 1);
  }

  // Delete all panorama images
  Future<void> deletePanoramaImages() async {
    for (var capturedImage in capturedImages) {
      try {
        if (await File(capturedImage.path).exists()) {
          await File(capturedImage.path).delete();
        }
      } catch (e) {
        // Error in getting access to the file.
        debugPrint("Failed Deleting panorama images");
      }
    }
  }

  void _setupSensors() {
    // Update interval
    int interval = Duration.microsecondsPerSecond ~/ 30;
    motionSensors.absoluteOrientationUpdateInterval = interval;
    motionSensors.orientationUpdateInterval = interval;

    // Stream
    _streamSubscriptions.add(motionSensors.absoluteOrientation
        .listen((AbsoluteOrientationEvent event) {
      setState(() {
        _absoluteOrientation.setValues(event.yaw, event.pitch, event.roll);
      });
    }));
  }

  // Setup Cameras
  Future<void> _setupCameras() async {
    cameras = await availableCameras();
    cameras = cameras.where((CameraDescription description) {
      return description.lensDirection == CameraLensDirection.back ||
          description.lensDirection == CameraLensDirection.external;
    }).toList();
    debugPrint(cameras.toString());
    // Open selected camera by user or first one
    _initCamera(selectedCameraKey);
  }

  // Initialize camera
  Future<void> _initCamera(int cameraKey) async {
    CameraDescription description = cameras[cameraKey];
    // Update selectedCameraKey
    selectedCameraKey = cameraKey;
    // Change the camera
    try {
      // initialize camera controllers.
      controller = CameraController(description, ResolutionPreset.high);
      await controller.initialize();
    } on CameraException catch (_) {
      // do something on error.
    }
    if (!mounted) return;
    setState(() {
      _isReady = true;
    });
  }

  // Prepare for taking next image
  void prepareForNextImageCatpure([double? degToNextPositionOverwrite]) {
    // If picture is taken then degToNextPositionOverwrite is null
    if (degToNextPositionOverwrite == null) {
      lastSuccessHorizontalPosition = helperDotHorizontalReach!;
    }

    // If degToNextPositionOverwrite is not set then is equal to degToNextPosition
    degToNextPositionOverwrite ??= degToNextPosition;
    // Move the helper to the next position
    _moveHelperDotToNextPosition(degToNextPositionOverwrite);
    // Generate right Ranges again
    rightRanges = generateRightRanges(helperDotHorizontalReach!);
    // Allow to take pictures again
    takingPicture = false;
  }

  Future<XFile> resizeImage(img) async {
    ImageProperties properties =
        await FlutterNativeImage.getImageProperties(img.path);

    File compressedFile = await FlutterNativeImage.compressImage(img.path,
        quality: capturedImageQuality,
        targetWidth: capturedImageWidth,
        targetHeight:
            (properties.height! * capturedImageWidth / properties.width!)
                .round());

    // delete original file
    try {
      if (await File(img.path).exists()) {
        await File(img.path).delete();
      }
    } catch (e) {
      // Error in getting access to the file.
    }

    return XFile(compressedFile.path);
  }

  // Take picture
  Future<XFile?> _takePicture() async {
    try {
      takingPicture = true;
      // Attempt to take a picture and then get the location
      // where the image file is saved.
      final image = await controller.takePicture().then((XFile? file) {
        return resizeImage(file);
      });

      // Prepare for taking the next image
      // Add captured image to the lsit
      capturedImages.add(image);
      // Update nrPhotosTaken
      nrPhotosTaken++;

      // Check if last two images can be stiched
      if (nrPhotosTaken > 1) {
        List<XFile> toStitch = [
          capturedImages[capturedImages.length - 2],
          image
        ];
        // List<XFile> toStitch = capturedImages;

        stitchImages(toStitch, false).then((value) {
          testStichingImage = value;
          prepareForNextImageCatpure();
        }).onError((error, stackTrace) async {
          print(error.toString());
          // Delete last taken image
          await removeLastCapturedImage();
          // Move the helperDot back
          prepareForNextImageCatpure(goBackDegrees);

          // Update nrPhotosTaken
          nrPhotosTaken--;
          // Delete last photos if set
          lastPhoto = false;
        });
      } else {
        testStichingImage = image;
        prepareForNextImageCatpure();
      }

      return image;
    } catch (e) {
      // If an error occurs, log the error to the console.
      return null;
    }
  }

  // Moive helper dot to the next position to take the next picture
  void _moveHelperDotToNextPosition([double? degToNextPositionOverwrite]) {
    // If degToNextPositionOverwrite is not set then is equal to degToNextPosition
    degToNextPositionOverwrite ??= degToNextPosition;

    helperDotHorizontalReach =
        (helperDotHorizontalReach! + degToNextPositionOverwrite);
    if (helperDotHorizontalReach! > 360) {
      helperDotHorizontalReach = (helperDotHorizontalReach! - 360);
    }

    if (helperDotHorizontalReach! <= lastSuccessHorizontalPosition) {
      stitchingFailed();
    }
  }

  // Update Helper Dot Vertical Position
  double updateHelperDotVerticalPosition(deviceVerticalDeg, containerHeight) {
    // Top available movement
    // double helperDotUpperMin = 0;
    double helperDotUpperMax = (containerHeight / 2);
    // Bottom available movement
    double helperDotBottomMin = containerHeight / 2;
    // double helperDotBottomMax = containerHeight;
    double helperDotPosY = (containerHeight / 2) - helperDotRadius;
    // MODIFY HELPER VERTICAL POSITION
    // If device is looking down
    if (deviceVerticalDeg < deviceVerticalCorrectDeg) {
      // If device is looking down to back
      if (deviceVerticalDeg <= 0) {
        helperDotPosY = 0;
      } else {
        // If device is looking down to up
        helperDotPosY = deviceVerticalDeg *
            (helperDotUpperMax - helperDotRadius) /
            (deviceVerticalCorrectDeg);
      }
    } else if (deviceVerticalDeg > deviceVerticalCorrectDeg) {
      // Device looking up
      helperDotPosY = deviceVerticalDeg *
          (helperDotBottomMin - helperDotRadius) /
          (deviceVerticalCorrectDeg);
    }

    // CHECK VERTICAL POSITION
    // Check if phone is vertically aligned
    if ((deviceVerticalDeg <
            (deviceVerticalCorrectDeg - helperDotVerticalTolerance)) ||
        (deviceVerticalDeg >
            (deviceVerticalCorrectDeg + helperDotVerticalTolerance))) {
      // Device not aligned vertically
      helperDotVerticalInPos = false;
    } else {
      // Device aligned vertically
      helperDotVerticalInPos = true;
    }

    return helperDotPosY;
  }

  // Generate right ranges
  List generateRightRanges(double reachDeg) {
    // Convert initial deg to 0
    // reachDeg = calculateDegreesFromZero(reachDeg, reachDeg);
    double right = reachDeg + 180;
    List rightRanges = [];

    if (right > 360) {
      right = right - 360;
      rightRanges.add([0, right]);
      rightRanges.add([reachDeg, 360]);
    } else {
      rightRanges.add([reachDeg, right]);
    }
    return rightRanges;
  }

  // Update Helper Dot Horizontal Position
  double updateHelperDotHorizontalPosition(
      deviceHorizontalDegManipulated, containerWidth) {
    double helperDotPosX = (containerWidth / 2) - helperDotRadius;

    // Check if current deg is in rightRanges
    bool moveRight = false;
    for (List rightRange in rightRanges) {
      if (deviceHorizontalDegManipulated >= rightRange[0] &&
          deviceHorizontalDegManipulated <= rightRange[1]) {
        moveRight = true;
        break;
      } else {
        moveRight = false;
      }
    }

    // if moveRight is true, then dotHelper should be on the left
    if (moveRight == true) {
      // The dotHelper should be on the left
      // Calculate how much I should move
      horizontalMovementNeeded = deviceHorizontalDegManipulated -
          (helperDotHorizontalReach! - helperDotHorizontalTolerance);

      helperDotPosX = (containerWidth / 2) -
          (centeredDotRadius / 2) -
          horizontalMovementNeeded -
          2;

      // If deviceHorizontalDegManipulated is smaller then 0-x right range then,
      // it means the user has rotated more then 360deg, so
      // deviceHorizontalDegManipulated start from 0 again and we need to move
      // the helperDotPosX 360 to the left
      if (rightRanges.length == 2) {
        if (deviceHorizontalDegManipulated <= rightRanges[0][1]) {
          helperDotPosX -= 360;
        }
      }

      if (helperDotPosX < helperDotRadius) {
        helperDotPosX = helperDotRadius;
      }
    } else {
      // The dotHelper should be on the right
      // Calculate how much I should move
      horizontalMovementNeeded =
          (helperDotHorizontalReach! - helperDotHorizontalTolerance) -
              deviceHorizontalDegManipulated;

      helperDotPosX = (containerWidth / 2) -
          (centeredDotRadius / 2) +
          horizontalMovementNeeded -
          2;

      if (helperDotPosX < 0) {
        if (rightRanges.length == 1) {
          helperDotPosX = helperDotPosX + 360;
        }
      }

      if (helperDotPosX > containerWidth - helperDotRadius) {
        helperDotPosX = containerWidth - helperDotRadius;
      }
    }

    // CHECK HELPER DOT HORIZONTAL POSITION
    if ((deviceHorizontalDegManipulated <
            (helperDotHorizontalReach! - helperDotHorizontalTolerance)) ||
        (deviceHorizontalDegManipulated >
            (helperDotHorizontalReach! + helperDotHorizontalTolerance))) {
      helperDotIsHorizontalInPos = false;
    } else {
      helperDotIsHorizontalInPos = true;
    }

    return helperDotPosX;
  }

  // Check if Device Roation is correct
  bool checkDeviceRotation(deviceRotationDeg) {
    if (deviceRotationDeg > helperDotRotationTolerance ||
        deviceRotationDeg < (helperDotRotationTolerance * -1)) {
      return false;
    }
    return true;
  }

  void prepareOnCaptureEnded(finalStitchedImage) {
    // Check if resolution is greater then 2:1

    Map<String, dynamic> returnedData = {
      'success': finalStitchedImage != null ? true : false,
      'panorama': finalStitchedImage,
      'options': {
        'selected_camera': selectedCameraKey,
        'vertical_camera_angle': deviceVerticalCorrectDeg,
      },
    };

    widget.onCaptureEnded(returnedData);
  }

  // Check if can take more photos
  bool canTakeMorePhotos() {
    if (lastPhoto == true && lastPhotoTaken == true) {
      return false;
    }

    if (lastPhoto == true) {
      lastPhotoTaken = true;
      // Download image
      if (imageSaved == false) {
        imageSaved = true;
        if (isPanoramaBeingStitched == false) {
          isPanoramaBeingStitched = true;

          stitchImages(capturedImages, true).then((value) {
            finalStitchedImage = value;
            isPanoramaBeingStitched = false;

            // Delete panorama images
            deletePanoramaImages();

            // Callback function
            prepareOnCaptureEnded(finalStitchedImage);

            GallerySaver.saveImage(finalStitchedImage.path);
          }).onError((error, stackTrace) {
            stitchingFailed();

            // Callback function
            prepareOnCaptureEnded(null);
            print("Stitching failed");
          });
        }
      }

      return false;
    }

    if (helperDotHorizontalReach! + degreesPerPhotos >= 360) {
      lastPhoto = true;
    }

    return true;
  }

  // Check if ready to take photo
  bool readyToTakePhoto() {
    return deviceInCorrectPosition &&
        takingPicture == false &&
        hasStitchingFailed == false;
  }

  // Stitch the images
  Future<XFile> stitchImages(List<XFile> images, bool cropped) async {
    // For Android, you call DynamicLibrary to find and open the shared library
    // You don’t need to do this in iOS since all linked symbols map when an app runs.
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
    final Camera360Bindings _bindings = Camera360Bindings(dylib);

    String dirpath =
        "${(await getApplicationDocumentsDirectory()).path}/stitched-panorama-${DateTime.now().millisecondsSinceEpoch}.jpg";

    bool isStiched = _bindings.stitch(
        imagePaths.toString().toNativeUtf8() as Pointer<Char>,
        dirpath.toNativeUtf8() as Pointer<Char>,
        cropped);

    if (!isStiched) {
      throw Exception('Stiching failed');
    }

    // Return the stiched image
    return XFile(dirpath);
  }

  // Stitching failed
  void stitchingFailed() {
    hasStitchingFailed = true;
    restartApp();
  }

  // Select camera lens
  void selectCamera(int cameraKey) {
    // Inform that camera has changed
    widget.onCameraChanged?.call(cameraKey);
    // Initialize new camera
    _initCamera(cameraKey).then((value) {
      // Restart app
      restartApp();
    });
  }

  // Calculate currentDeg as starting from 0
  double calculateDegreesFromZero(double initialDeg, double currentDeg) {
    double calculatedDeg = currentDeg;
    double deviceHorizontalDegReset = 360 - initialDeg;
    // This line of commented below, converts the deg to true 0-360 values,
    // not negative ones
    if (currentDeg >= 0 && currentDeg < initialDeg) {
      calculatedDeg = calculatedDeg + deviceHorizontalDegReset;
    } else {
      calculatedDeg = calculatedDeg - deviceHorizontalDegInitial!;
    }

    return calculatedDeg;
  }

  @override
  void dispose() {
    // Disable screen always on
    Wakelock.disable();
    controller.dispose();
    for (StreamSubscription<dynamic> subscription in _streamSubscriptions) {
      subscription.cancel();
    }

    restartApp();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) return Container();

    // Kepp the screen on
    Wakelock.enable();

    double deviceVerticalDeg =
        double.parse(degrees(_absoluteOrientation.y).toStringAsFixed(1));
    double deviceHorizontalDeg = double.parse(
        (360 - degrees(_absoluteOrientation.x + _absoluteOrientation.z) % 360)
            .toStringAsFixed(1));
    double deviceRotationDeg =
        double.parse(degrees(_absoluteOrientation.z).toStringAsFixed(1));
    deviceHorizontalDegInitial ??= deviceHorizontalDeg;
    // Manipulate deg starting from 0
    double deviceHorizontalDegManipulated = calculateDegreesFromZero(
        deviceHorizontalDegInitial ?? 0, deviceHorizontalDeg);
    // Set default helperDotHorizontalReach
    helperDotHorizontalReach ??= deviceHorizontalDegManipulated;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double containerWidth = constraints.maxWidth;
        double containerHeight = constraints.maxHeight;
        bool isDeviceRotationCorrect = checkDeviceRotation(deviceRotationDeg);

        // Centered dot
        double centeredDotPosX =
            (containerWidth / 2) - centeredDotRadius - centeredDotBorder;
        double centeredDotPosY =
            (containerHeight / 2) - centeredDotRadius - centeredDotBorder;

        // Update Helper Dot horizontal position
        double helperDotPosX = updateHelperDotHorizontalPosition(
            deviceHorizontalDegManipulated, containerWidth);
        // Update Gelper Dot vertical position
        double helperDotPosY =
            updateHelperDotVerticalPosition(deviceVerticalDeg, containerHeight);
        // Update device correct position
        deviceInCorrectPosition = (helperDotVerticalInPos == true &&
            helperDotIsHorizontalInPos == true &&
            isDeviceRotationCorrect == true);

        // Generate right ranges
        rightRanges = generateRightRanges(helperDotHorizontalReach!);

        // Take picture
        if (readyToTakePhoto()) {
          _takePicture();
        }

        // Centere dot color
        var centeredDotColor = deviceInCorrectPosition == true
            ? Colors.white.withOpacity(0.7)
            : Colors.transparent;

        //  Helper dot color depending on device rotation
        var helperDotColor =
            isDeviceRotationCorrect == true ? Colors.white : Colors.red;

        return Container(
          color: Colors.black,
          child: canTakeMorePhotos()
              ? Stack(
                  children: [
                    Center(
                      child: CameraPreview(controller),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "nrPhotos: $nrPhotos",
                          style: const TextStyle(color: Colors.white),
                        ),
                        Text(
                          "helperDotVerticalInPos: $helperDotVerticalInPos",
                          style: const TextStyle(color: Colors.white),
                        ),
                        Text(
                          "helperDotIsHorizontalInPos: $helperDotIsHorizontalInPos",
                          style: const TextStyle(color: Colors.white),
                        ),
                        Text(
                          "isDeviceRotationCorrect: $isDeviceRotationCorrect",
                          style: const TextStyle(color: Colors.white),
                        ),
                        Text(
                          "nrPhotosTaken: $nrPhotosTaken",
                          style: const TextStyle(color: Colors.white),
                        ),
                        Text(
                          "goBackDegrees: $goBackDegrees",
                          style: const TextStyle(color: Colors.white),
                        ),
                        Text(
                          "deviceHorizontalDegInitial: $deviceHorizontalDegInitial",
                          style: const TextStyle(color: Colors.white),
                        ),
                        Text(
                          "deviceHorizontalDegManipulated: ${deviceHorizontalDegManipulated.toStringAsFixed(2)}",
                          style: const TextStyle(color: Colors.white),
                        ),
                        Text(
                          "helperDotPosX: ${helperDotPosX.toStringAsFixed(2)}",
                          style: const TextStyle(color: Colors.white),
                        ),
                        Text(
                          "helperDotHorizontalReach: $helperDotHorizontalReach",
                          style: const TextStyle(color: Colors.white),
                        ),
                        Text(
                          "rightRanges: ${rightRanges.toString()}",
                          style: const TextStyle(color: Colors.white),
                        ),
                        Text(
                          "lastSuccessHorizontalPosition: ${lastSuccessHorizontalPosition.toString()}",
                          style: const TextStyle(color: Colors.white),
                        ),
                        Text(
                          "hasStitchingFailed: ${hasStitchingFailed.toString()}",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int cameraKey = 0;
                                cameraKey < cameras.length;
                                cameraKey++) ...[
                              ElevatedButton(
                                  style: ButtonStyle(
                                      backgroundColor:
                                          cameraKey == selectedCameraKey
                                              ? MaterialStateProperty.all(
                                                  Colors.red)
                                              : MaterialStateProperty.all(
                                                  Colors.blue)),
                                  onPressed: () => selectCamera(cameraKey),
                                  child: Text(cameraKey.toString()))
                            ],
                          ],
                        ),
                        // Reset
                        ElevatedButton(
                            onPressed: () => restartApp(),
                            child: const Text("reset")),
                        nrPhotosTaken >= 1
                            ? Center(
                                child: Image.file(File(testStichingImage.path),
                                    height: 100),
                              )
                            : Container()
                      ],
                    ),
                    // Helper dot
                    Transform.translate(
                      offset: Offset(helperDotPosX, helperDotPosY),
                      child: CircleAvatar(
                        radius: helperDotRadius,
                        backgroundColor: helperDotColor,
                      ),
                    ),
                    // Device Rotaion
                    isDeviceRotationCorrect
                        ? Container()
                        : DeviceRotation(deviceRotation: deviceRotationDeg),
                    // Centered
                    Transform.translate(
                      offset: Offset(centeredDotPosX, centeredDotPosY),
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                                width: centeredDotBorder, color: Colors.white)),
                        child: CircleAvatar(
                          radius: centeredDotRadius,
                          backgroundColor: centeredDotColor,
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: isPanoramaBeingStitched
                      ? hasStitchingFailed
                          ? const Text(
                              'Stitching failed',
                              style: TextStyle(color: Colors.white),
                            )
                          : const Text(
                              'Preparing panorama...',
                              style: TextStyle(color: Colors.white),
                            )
                      : Column(
                          children: [
                            Image.file(File(finalStitchedImage.path),
                                height: 200),
                            ElevatedButton(
                                onPressed: () => restartApp(),
                                child: const Text("reset")),
                          ],
                        )),
        );
      },
    );
  }
}
