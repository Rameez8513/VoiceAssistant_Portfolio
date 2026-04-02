import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/cv_model.dart';

class CvContent extends StatelessWidget {
  final CvModel? cv;
  final bool isDark;
  final bool isMobile;

  const CvContent({
    super.key,
    required this.cv,
    required this.isDark,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    if (cv == null) {
      return _EmptyState(isDark: isDark);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.space16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CvHeader(cv: cv!, isDark: isDark)
              .animate()
              .fadeIn(duration: AppConstants.durationMedium)
              .slideY(
                begin: 0.1,
                duration: AppConstants.durationMedium,
                curve: AppConstants.curveStandard,
              ),
          if (cv!.highlights.isNotEmpty) ...[
            const SizedBox(height: AppConstants.space24),
            ...cv!.highlights.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.space12),
                child: _HighlightItem(
                  text: entry.value,
                  index: entry.key,
                )
                    .animate()
                    .fadeIn(
                      delay: Duration(milliseconds: 100 + (entry.key * 50)),
                      duration: AppConstants.durationMedium,
                    )
                    .slideX(
                      begin: 0.1,
                      delay: Duration(milliseconds: 100 + (entry.key * 50)),
                      duration: AppConstants.durationMedium,
                      curve: AppConstants.curveStandard,
                    ),
              );
            }),
          ],
          const SizedBox(height: AppConstants.space24),
          FilledButton.icon(
            onPressed: () async {
              final uri = Uri.tryParse(cv!.downloadUrl);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.download),
            label: const Text('Download Resume'),
          )
              .animate()
              .fadeIn(
                delay:
                    Duration(milliseconds: 200 + (cv!.highlights.length * 50)),
                duration: AppConstants.durationMedium,
              )
              .scale(
                begin: const Offset(0.95, 0.95),
                delay:
                    Duration(milliseconds: 200 + (cv!.highlights.length * 50)),
                duration: AppConstants.durationMedium,
                curve: AppConstants.curveStandard,
              ),
        ],
      ),
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
            Icons.description_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppConstants.space16),
          Text(
            'Resume not available',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CvHeader extends StatelessWidget {
  final CvModel cv;
  final bool isDark;

  const _CvHeader({required this.cv, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.space16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppConstants.radiusMD),
              ),
              child: Icon(
                Icons.description,
                color: colorScheme.onPrimaryContainer,
                size: AppConstants.iconLG,
              ),
            ),
            const SizedBox(width: AppConstants.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Curriculum Vitae',
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    'Updated ${cv.lastUpdated}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightItem extends StatelessWidget {
  final String text;
  final int index;

  const _HighlightItem({
    required this.text,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.space16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppConstants.space12),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
