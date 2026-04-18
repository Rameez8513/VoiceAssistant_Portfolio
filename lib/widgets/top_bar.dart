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
          )
              .animate()
              .fadeIn(duration: AppConstants.durationMedium)
              .slideX(
                begin: -0.1,
                duration: AppConstants.durationMedium,
                curve: AppConstants.curveStandard,
              ),
          const Spacer(),
          _AvailableBadge(theme: theme)
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

class _AvailableBadge extends StatelessWidget {
  final ThemeData theme;

  const _AvailableBadge({required this.theme});

  static const _green = Color(0xFF22C55E);
  static const _greenGlow = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.space12,
        vertical: AppConstants.space6,
      ),
      decoration: BoxDecoration(
        color: _green.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        border: Border.all(
          color: _green.withOpacity(0.55),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _green.withOpacity(0.18),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(2.2, 2.2),
                    duration: const Duration(milliseconds: 1600),
                    curve: Curves.easeOut,
                  )
                  .fadeOut(
                    begin: 0.7,
                    duration: const Duration(milliseconds: 1600),
                    curve: Curves.easeOut,
                  ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _greenGlow.withOpacity(0.6),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: AppConstants.space8),
          Text(
            'Available for Work',
            style: theme.textTheme.labelSmall?.copyWith(
              color: _green,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}