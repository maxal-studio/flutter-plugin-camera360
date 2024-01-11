##
# - Developer Documentation

# Debuging vs Release (Android)

On Android while debuging under `android/build.gardle` uncomment the lines after the comment `//For debuging` and comment out lines after the comment `//For release`


### Install cmake and ninja
```bash
 brew install cmake
 brew unlink cmake && brew link cmake
 brew install ninja
 ```


>For the Android `SDK` and `NDK`, define the following paths as environment variables. Typically, you add them to your shell config file, e.g.,  `~/.bashrc` or `~/.zshrc`. Make sure your NDK version is newer than `23.0.75`.
> Then run source to read the new comands into the shell `source ~/.zshrc` or `source ~/.bashrc`
>
>To install the SDK and NDK use Android Studio
>Open `Android Studio Preference` (or "File->Settings") > `Appearance & Behavior` >`System Settings` > `Android SDK`. 
>On the next tab: `SDK Tools` , you can check if NDK is installed

> Update `26.0.10792818` with your NDK version

```bash
export ANDROID_HOME=/$HOME/Library/Android/sdk
export ANDROID_NDK_HOME=$ANDROID_HOME/ndk
export ANDROID_NDK=$ANDROID_NDK_HOME
export NDK=$ANDROID_HOME/ndk/26.0.10792818
```

### First we need to download and prepare OpenCV for both platforms
```properties
cd /src
sh prebuild.sh
```

### Now we need to build the OpenCV Framework for iOS and Android

## iOS
```properties
cd /ios/
sh build.sh
```
  
### And the last step is to generate the Binding and install PODS
  From the main dir of the plugin
```properties
sh build.sh
```

# Developer Reference links

1. [Scanbot.io](https://scanbot.io/blog/implementing-a-flutter-plugin-with-native-opencv-support-via-dartffi-part-1-2/)
2. [Configure CMAKE for OpenCV](https://docs.opencv.org/4.x/db/d05/tutorial_config_reference.html)
3. [Configure CMAKE for OpenCV - Opmtimized](https://github.com/opencv/opencv/wiki/Compact-build-advice)