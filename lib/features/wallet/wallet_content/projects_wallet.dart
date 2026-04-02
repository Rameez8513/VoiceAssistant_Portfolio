import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/project_model.dart';

class ProjectsContent extends StatelessWidget {
  final List<ProjectModel> projects;
  final bool isDark;
  final bool isMobile;

  const ProjectsContent({
    super.key,
    required this.projects,
    required this.isDark,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) {
      return _EmptyState(isDark: isDark);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppConstants.space16),
      physics: const BouncingScrollPhysics(),
      itemCount: projects.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppConstants.space12),
      itemBuilder: (context, index) {
        return _ProjectCard(
          project: projects[index],
          index: index,
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
            Icons.dashboard_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppConstants.space16),
          Text(
            'No projects yet',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final ProjectModel project;
  final int index;

  const _ProjectCard({
    required this.project,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final uri = Uri.tryParse(project.link);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.space8,
                      vertical: AppConstants.space4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusSM),
                    ),
                    child: Text(
                      project.category,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    project.year,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.space12),
              Text(
                project.title,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppConstants.space8),
              Text(
                project.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (project.tags.isNotEmpty) ...[
                const SizedBox(height: AppConstants.space12),
                Wrap(
                  spacing: AppConstants.space6,
                  runSpacing: AppConstants.space6,
                  children: project.tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      labelStyle: theme.textTheme.labelSmall,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
