import 'dart:ui';

import 'package:event_manager/components/constants.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class loadingWidget extends StatelessWidget {
  const loadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topLeft, // Specify alignment directly here
      fit: StackFit.expand,
      children: [
        // Background Container with Blur Effect
        Container(
          constraints: const BoxConstraints.expand(),
          decoration: BoxDecoration(
            color:
                Colors.black.withOpacity(0.5), // Adjust the opacity as needed
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(
                sigmaX: 5, sigmaY: 5), // Adjust the blur intensity
            child: Container(
              color: Colors.black.withOpacity(0), // Transparent color
            ),
          ),
        ),
        // Loading Animation
        Center(
          child: Container(
            width: 50,
            height: 50,
            child: LoadingAnimationWidget.twistingDots(
              leftDotColor: const Color.fromARGB(255, 255, 255, 255),
              rightDotColor: kTextColor,
              size: 50,
            ),
          ),
        ),
      ],
    );
  }
}

class loadingWidget2 extends StatelessWidget {
  const loadingWidget2({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(children: [
        LoadingAnimationWidget.twistingDots(
          leftDotColor: const Color.fromARGB(255, 255, 255, 255),
          rightDotColor: kTextColor,
          size: 50,
        ),
      ]),
    );
  }
}
