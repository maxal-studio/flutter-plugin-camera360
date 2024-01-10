import 'package:flutter/material.dart';

class FirstPictureHelperText extends StatelessWidget {
  final String helperText;
  final bool shown;
  const FirstPictureHelperText({
    super.key,
    this.shown = true,
    this.helperText = "",
  });

  @override
  Widget build(BuildContext context) {
    return shown == true && helperText.isNotEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 250),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    helperText,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          )
        : Container();
  }
}
