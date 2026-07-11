import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import 'shimmer.dart';

/// A network image that shows a [ShimmerBox] while loading and a calm branded
/// glyph when the url is missing or fails — never a broken-image icon or a
/// blank box (designed states everywhere).
class ShimmerImage extends StatelessWidget {
  const ShimmerImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.radius,
    this.fallbackIcon = Icons.storefront_outlined,
    this.fit = BoxFit.cover,
  });

  final String? url;
  final double? width;
  final double? height;
  final BorderRadius? radius;
  final IconData fallbackIcon;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final r = radius ?? AppRadius.mdAll;
    final image = _buildImage(context);
    return ClipRRect(borderRadius: r, child: image);
  }

  Widget _buildImage(BuildContext context) {
    final url = this.url;
    if (url == null || url.isEmpty) return _fallback(context);

    // A bundled asset path (e.g. demo seed shop logos) rather than a remote
    // URL — load it from the app bundle, no network/shimmer needed.
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, _, _) => _fallback(context),
      );
    }

    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return ShimmerBox(width: width, height: height, radius: radius);
      },
      errorBuilder: (context, _, _) => _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        fallbackIcon,
        color: scheme.secondary,
        size: 28,
      ),
    );
  }
}
