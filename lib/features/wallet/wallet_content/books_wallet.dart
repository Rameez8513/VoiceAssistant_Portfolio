import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/book_model.dart';

class BooksContent extends StatelessWidget {
  final List<BookModel> books;
  final bool isDark;
  final bool isMobile;

  const BooksContent({
    super.key,
    required this.books,
    required this.isDark,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return _EmptyState(isDark: isDark);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppConstants.space16),
      physics: const BouncingScrollPhysics(),
      itemCount: books.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppConstants.space12),
      itemBuilder: (context, index) {
        return _BookCard(
          book: books[index],
          isDark: isDark,
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
            Icons.menu_book_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppConstants.space16),
          Text(
            'No books yet',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final BookModel book;
  final bool isDark;

  const _BookCard({
    required this.book,
    required this.isDark,
  });

  Color _getCoverColor() {
    try {
      final colorString = book.coverColor.replaceFirst('#', '');
      return Color(int.parse('FF$colorString', radix: 16));
    } catch (_) {
      return const Color(0xFF6750A4);
    }
  }

  String _getStatusLabel() {
    switch (book.status.toLowerCase()) {
      case 'reading':
        return 'Reading';
      case 'completed':
      case 'done':
        return 'Completed';
      default:
        return 'To Read';
    }
  }

  Color _getStatusColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (book.status.toLowerCase()) {
      case 'reading':
        return colorScheme.tertiary;
      case 'completed':
      case 'done':
        return colorScheme.primary;
      default:
        return colorScheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: book.link.isNotEmpty
            ? () async {
                final uri = Uri.tryParse(book.link);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.space16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 80,
                decoration: BoxDecoration(
                  color: _getCoverColor(),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    book.title.isNotEmpty ? book.title[0].toUpperCase() : 'B',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.space8,
                        vertical: AppConstants.space4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(context).withOpacity(0.15),
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusFull),
                      ),
                      child: Text(
                        _getStatusLabel(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _getStatusColor(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.space8),
                    Text(
                      book.title,
                      style: theme.textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppConstants.space4),
                    Text(
                      book.author,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (book.link.isNotEmpty)
                Icon(
                  Icons.open_in_new,
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
