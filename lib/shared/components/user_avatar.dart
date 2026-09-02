import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String name;
  final String imageUrl;
  final double diameter;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final TextStyle? textStyle;

  const UserAvatar({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.diameter,
    this.backgroundColor,
    this.foregroundColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final fallback = ColoredBox(
      color: backgroundColor ?? colorScheme.primaryContainer,
      child: Center(
        child: Text(
          initial,
          style:
              textStyle ??
              TextStyle(
                color: foregroundColor ?? colorScheme.primary,
                fontWeight: FontWeight.w800,
                fontSize: diameter * 0.36,
              ),
        ),
      ),
    );

    return Semantics(
      image: imageUrl.isNotEmpty,
      label: '$name profil fotoğrafı',
      child: ClipOval(
        child: SizedBox.square(
          dimension: diameter,
          child: imageUrl.isEmpty
              ? fallback
              : CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => fallback,
                  errorWidget: (_, _, _) => fallback,
                ),
        ),
      ),
    );
  }
}
