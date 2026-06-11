import 'package:flutter/material.dart';

class Gap extends StatelessWidget {
  final double? height;
  final double? width;

  const Gap({super.key, this.height, this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height, width: width);
  }
}
