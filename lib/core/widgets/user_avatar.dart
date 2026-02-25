import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final bool hasStory;
  final bool isOnline;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.radius = 24,
    this.hasStory = false,
    this.isOnline = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            padding: EdgeInsets.all(hasStory ? 3 : 0),
            decoration: hasStory
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.storyGradient,
                  )
                : null,
            child: Container(
              padding: EdgeInsets.all(hasStory ? 2 : 0),
              decoration: hasStory
                  ? const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.darkBg,
                    )
                  : null,
              child: CircleAvatar(
                radius: radius,
                backgroundColor: AppColors.darkCard,
                backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(imageUrl!)
                    : null,
                child: imageUrl == null || imageUrl!.isEmpty
                    ? Icon(
                        Icons.person_rounded,
                        size: radius,
                        color: AppColors.textMuted,
                      )
                    : null,
              ),
            ),
          ),
          if (isOnline)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.darkBg, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
