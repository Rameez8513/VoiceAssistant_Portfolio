import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/social_model.dart';

class SocialContent extends StatelessWidget {
  final List<SocialModel> socials;
  final bool isDark;
  final bool isMobile;

  const SocialContent({
    super.key,
    required this.socials,
    required this.isDark,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    if (socials.isEmpty) {
      return _EmptyState(isDark: isDark);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppConstants.space16),
      physics: const BouncingScrollPhysics(),
      itemCount: socials.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppConstants.space12),
      itemBuilder: (context, index) {
        return _SocialCard(
          social: socials[index],
          index: index,
        )
            .animate()
            .fadeIn(
              delay: Duration(milliseconds: index * 50),
              duration: AppConstants.durationMedium,
            )
            .slideX(
              begin: 0.1,
              delay: Duration(milliseconds: index * 50),
              duration: AppConstants.durationMedium,
              curve: AppConstants.curveStandard,
            );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;

  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.share_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppConstants.space16),
          Text(
            'No social links yet',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialCard extends StatelessWidget {
  final SocialModel social;
  final int index;

  const _SocialCard({
    required this.social,
    required this.index,
  });

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'github':
        return Icons.code;
      case 'linkedin':
        return Icons.work;
      case 'twitter':
      case 'x':
        return Icons.tag;
      case 'instagram':
        return Icons.photo_camera;
      case 'youtube':
        return Icons.play_circle;
      default:
        return Icons.link;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: InkWell(
        onTap: () async {
          final uri = Uri.tryParse(social.url);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.space16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                ),
                child: Icon(
                  _getPlatformIcon(social.platform),
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppConstants.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      social.platform,
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      social.handle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: AppConstants.iconSM,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
