import 'package:flutter/material.dart';

class EvinCoverImage extends StatelessWidget {
  final String? assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const EvinCoverImage({
    super.key,
    this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final validPath = (assetPath != null && assetPath!.isNotEmpty)
        ? assetPath!
        : 'assets/images/greeting.jpg';

    Widget imageWidget = Image.asset(
      validPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/images/greeting.jpg',
          width: width,
          height: height,
          fit: fit,
        );
      },
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
