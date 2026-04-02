import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';

class BottomBar extends StatelessWidget {
  final bool isDark;
  final bool isMobile;

  const BottomBar({
    super.key,
    required this.isDark,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: AppConstants.bottomBarHeight,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppConstants.space16 : AppConstants.space24,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          FilledButton.tonalIcon(
            onPressed: () async {
              final uri = Uri.parse('mailto:${AppConstants.appEmail}');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
            icon: const Icon(Icons.mail_outline, size: AppConstants.iconSM),
            label: Text(isMobile ? 'Email' : AppConstants.appEmail),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.space16,
                vertical: AppConstants.space12,
              ),
            ),
          ),
          const Spacer(),
          if (!isMobile)
            Text(
              AppConstants.appCopyright,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
