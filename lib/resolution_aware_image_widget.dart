import 'package:flutter/material.dart';
import 'get_better_resolution.dart';

class ResolutionAwareImageWidget extends StatefulWidget {

  final String referenceImageName;
  final double? width;
  final double? height;

  const ResolutionAwareImageWidget({
    Key? key,
    required this.referenceImageName,
    this.width,
    this.height
  }) : super(key: key);

  @override
  _ResolutionAwareImageWidgetState createState() => _ResolutionAwareImageWidgetState();
}

class _ResolutionAwareImageWidgetState extends State<ResolutionAwareImageWidget> {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      GetBetterResolution().get(
          context: context,
          referenceImageName: widget.referenceImageName,
          width: widget.width,
          height: widget.height
      ),
      width: widget.width,
      height: widget.height,
    );
  }
}
