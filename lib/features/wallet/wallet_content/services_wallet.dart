import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/service_model.dart';

class ServicesContent extends StatefulWidget {
  final List<ServiceModel> services;
  final bool isDark;
  final bool isMobile;

  const ServicesContent({
    super.key,
    required this.services,
    required this.isDark,
    required this.isMobile,
  });

  @override
  State<ServicesContent> createState() => _ServicesContentState();
}

class _ServicesContentState extends State<ServicesContent> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.services.isEmpty) {
      return _EmptyState(isDark: widget.isDark);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppConstants.space16),
      physics: const BouncingScrollPhysics(),
      itemCount: widget.services.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppConstants.space12),
      itemBuilder: (context, index) {
        final service = widget.services[index];
        final isExpanded = _expandedIndex == index;

        return _ServiceCard(
          service: service,
          isDark: widget.isDark,
          isExpanded: isExpanded,
          onTap: () =>
              setState(() => _expandedIndex = isExpanded ? null : index),
        )
            .animate()
            .fadeIn(
              delay: Duration(milliseconds: index * 50),
              duration: AppConstants.durationMedium,
            )
            .slideY(
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
            Icons.build_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppConstants.space16),
          Text(
            'No services yet',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final bool isDark;
  final bool isExpanded;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.service,
    required this.isDark,
    required this.isExpanded,
    required this.onTap,
  });

  IconData _getIcon(String iconKey) {
    switch (iconKey.toLowerCase()) {
      case 'design':
        return Icons.palette_outlined;
      case 'code':
        return Icons.code;
      case 'mobile':
        return Icons.smartphone;
      case 'web':
        return Icons.language;
      case 'ai':
        return Icons.auto_awesome;
      default:
        return Icons.bolt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppConstants.space8),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusSM),
                    ),
                    child: Icon(
                      _getIcon(service.icon),
                      size: AppConstants.iconMD,
                      color: colorScheme.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppConstants.space12),
                  Expanded(
                    child: Text(
                      service.title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: AppConstants.durationFast,
                    child: Icon(
                      Icons.expand_more,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.space12),
              Text(
                service.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: isExpanded ? null : 2,
                overflow: isExpanded ? null : TextOverflow.ellipsis,
              ),
              AnimatedSize(
                duration: AppConstants.durationMedium,
                curve: AppConstants.curveStandard,
                child: isExpanded && service.features.isNotEmpty
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppConstants.space16),
                          Divider(height: 1, color: colorScheme.outlineVariant),
                          const SizedBox(height: AppConstants.space16),
                          ...service.features.map((feature) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                  bottom: AppConstants.space8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: AppConstants.iconSM,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: AppConstants.space8),
                                  Expanded(
                                    child: Text(
                                      feature,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
