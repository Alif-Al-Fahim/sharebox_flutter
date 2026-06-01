import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final VoidCallback? onTap;
  final bool showBorder;
  final Color? borderColor;

  const UserAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.radius = 24,
    this.onTap,
    this.showBorder = false,
    this.borderColor,
  });

  String get _initials {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
      backgroundImage:
          imageUrl != null ? CachedNetworkImageProvider(imageUrl!) : null,
      child: imageUrl == null
          ? Text(
              _initials,
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w700,
                fontSize: radius * 0.65,
              ),
            )
          : null,
    );

    if (showBorder) {
      avatar = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor ?? AppTheme.primaryColor,
            width: 2,
          ),
        ),
        child: avatar,
      );
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }
}

class AvatarStack extends StatelessWidget {
  final List<String?> imageUrls;
  final List<String> names;
  final double radius;
  final double overlap;
  final int maxShow;

  const AvatarStack({
    super.key,
    required this.imageUrls,
    required this.names,
    this.radius = 18,
    this.overlap = 10,
    this.maxShow = 3,
  });

  @override
  Widget build(BuildContext context) {
    final shown = imageUrls.take(maxShow).toList();
    final extra = imageUrls.length - maxShow;

    return SizedBox(
      width: radius * 2 + (shown.length - 1) * (radius * 2 - overlap),
      height: radius * 2,
      child: Stack(
        children: [
          for (int i = 0; i < shown.length; i++)
            Positioned(
              left: i * (radius * 2 - overlap),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: UserAvatar(
                  imageUrl: shown[i],
                  name: i < names.length ? names[i] : 'U',
                  radius: radius,
                ),
              ),
            ),
          if (extra > 0)
            Positioned(
              left: shown.length * (radius * 2 - overlap),
              child: Container(
                width: radius * 2,
                height: radius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '+$extra',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: radius * 0.55,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
