# 360 Camera

This plugin allows the users to take 360 Panoramic Images using the phones Camera. It uses OpenCV to stitch the images together.
A simple UI guides the user throughout the process, by displaying dots on the screen that the user should follow.

# Installation

### IOS
Add these lines into `Info.plist`
```plist
<key>NSCameraUsageDescription</key>
<string>This application needs access to your Camera in order to capture360 Images</string>
<key>NSMicrophoneUsageDescription</key>
<string>This application needs access to your Microphone in order tocapture videos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This application needs access to your Photo Library in order to saved the captured images</string>
```

### Android

#### Attention when building release versions since OpenCV has been built for different CPUS we recommend running this command to build multiple APKs:

```properties
flutter build apk --split-per-abi --release
```

Change the minimum Android sdk version to 21 (or higher) in your `android/app/build.gradle` file.

```properties
minSdkVersion 21
```

`AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
 ```

### Dart
```dart
import 'package:camera_360/camera_360.dart';
import 'package:image_picker/image_picker.dart';
Camera360(
    userSelectedCameraKey: 2,
    onCaptureEnded: (data) {
      // Returned data will be a map like below
      //{
      //  'success': true or false
      //  'panorama': XFile or null,
      //  'options': {
      //    'selected_camera': int KEY,
      //    'vertical_camera_angle': int DEG,
      //  }
      //}
      if (data['success'] == true) {
        XFile panorama = data['panorama'];
        print("Final image returned $panorama.toString()");
      } else {
        print("Final image failed");
      }
    },
    onCameraChanged: (cameraKey) {
      print("Camera changed ${cameraKey.toString()}");
    },
    onProgressChanged: (newProgressPercentage) {
      debugPrint("'Panorama360': Progress changed: $newProgressPercentage");
    }),
),
```

> `onCaptureEnded` will return `XFile` or `null`  
> - `XFile` if the panorama has been captured successfully   
> - `null` if the panorama has failed  


## [Developer Documentation](docs/developer.md)



    