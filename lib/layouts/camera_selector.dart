import 'package:camera/camera.dart';
import 'package:camera_360/layouts/triangle_clipper.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CameraSelector extends StatefulWidget {
  final List<CameraDescription> cameras;
  final int selectedCameraKey;
  final bool infoPopUpShow;
  final Widget? infoPopUpContent;
  final void Function(int)? onCameraChanged;
  const CameraSelector({
    super.key,
    required this.cameras,
    required this.selectedCameraKey,
    this.infoPopUpShow = true,
    this.infoPopUpContent,
    this.onCameraChanged,
  });

  @override
  State<CameraSelector> createState() => _CameraSelectorState();
}

class _CameraSelectorState extends State<CameraSelector> {
  // Camera keys
  static List<String> cameraKeys = <String>[];
  bool infoPopUpShowValue = false;
  Widget? infoPopUpContentValue;
  late final SharedPreferences prefs;

  // When camera is changed call the callback
  void cameraChanged(int cameraKey) {
    widget.onCameraChanged?.call(cameraKey);
  }

  // Hide the helper popup
  void hideHelperPopUP() {
    infoPopUpShowValue = false;
    prefs.setBool('infoPopUpShowValue', false);
  }

  // Using SharedPreferences to register if user already clicked on
  // camera change dropdown, so that the helperPopUp will not be shown again
  Future<SharedPreferences> getSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();

    return prefs;
  }

  @override
  void initState() {
    super.initState();

    cameraKeys = [];
    // Populate camera keys
    for (int cameraKey = 0; cameraKey < widget.cameras.length; cameraKey++) {
      cameraKeys.add(cameraKey.toString());
    }

    infoPopUpContentValue = widget.infoPopUpContent ??
        const Column(
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
        );

    getSharedPreferences().then((prefs) {
      // Assign default values
      infoPopUpShowValue =
          prefs.getBool('infoPopUpShowValue') ?? widget.infoPopUpShow;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Helper Popup
            infoPopUpShowValue == true
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Container(
                          constraints: const BoxConstraints(maxWidth: 400),
                          padding: const EdgeInsets.symmetric(
                              vertical: 15, horizontal: 50),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: infoPopUpContentValue,
                        ),
                        ClipPath(
                          clipper: TriangleClipper(),
                          child: Container(
                            color: Colors.black.withOpacity(0.8),
                            height: 10,
                            width: 20,
                          ),
                        )
                      ],
                    ),
                  )
                : Container(),

            // DropDown Button
            Container(
              padding: const EdgeInsets.only(left: 10, right: 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: DropdownButton(
                onTap: () {
                  hideHelperPopUP();
                },
                dropdownColor: Colors.black.withOpacity(0.8),
                underline: const SizedBox(),
                icon: const ImageIcon(
                  AssetImage(
                    "images/arrow-down.png",
                    package: 'camera_360',
                  ),
                  size: 10,
                ),
                onChanged: (String? value) {
                  cameraChanged(int.parse(value!));
                },
                value: widget.selectedCameraKey.toString(),
                items: cameraKeys.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    alignment: AlignmentDirectional.center,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        value,
                        style: const TextStyle(color: Color(0xff999999)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
