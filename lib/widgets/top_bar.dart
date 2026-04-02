import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

class TopBar extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;
  final bool isMobile;

  const TopBar({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: AppConstants.topBarHeight,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppConstants.space16 : AppConstants.space24,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                ),
                child: Center(
                  child: Text(
                    AppConstants.appInitials,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: AppConstants.space12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.appName,
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      AppConstants.appRole,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ).animate().fadeIn(duration: AppConstants.durationMedium).slideX(
                begin: -0.1,
                duration: AppConstants.durationMedium,
                curve: AppConstants.curveStandard,
              ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.space12,
              vertical: AppConstants.space6,
            ),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusFull),
              border: Border.all(
                color: AppColors.success.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppConstants.space6),
                Text(
                  'Available',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(
                delay: const Duration(milliseconds: 100),
                duration: AppConstants.durationMedium,
              )
              .scale(
                begin: const Offset(0.9, 0.9),
                delay: const Duration(milliseconds: 100),
                duration: AppConstants.durationMedium,
                curve: AppConstants.curveStandard,
              ),
          const SizedBox(width: AppConstants.space12),
          IconButton(
            onPressed: onToggleTheme,
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHigh,
            ),
          )
              .animate()
              .fadeIn(
                delay: const Duration(milliseconds: 150),
                duration: AppConstants.durationMedium,
              )
              .scale(
                begin: const Offset(0.9, 0.9),
                delay: const Duration(milliseconds: 150),
                duration: AppConstants.durationMedium,
                curve: AppConstants.curveStandard,
              ),
        ],
      ),
    );
  }
}
