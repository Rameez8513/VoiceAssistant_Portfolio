import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants/app_constants.dart';
import '../../features/home/home_screen.dart';
import '../data/services/firebase_service.dart';
import '../data/models/project_model.dart';
import '../data/models/service_model.dart';
import '../data/models/book_model.dart';
import '../data/models/social_model.dart';
import '../data/models/cv_model.dart';
import '../features/wallet/wallet_content/projects_wallet.dart';
import '../features/wallet/wallet_content/services_wallet.dart';
import '../features/wallet/wallet_content/books_wallet.dart';
import '../features/wallet/wallet_content/social_wallet.dart';
import '../features/wallet/wallet_content/cv_wallet.dart';

enum WalletSide { left, right }

const List<WalletType> _leftWallets = [
  WalletType.projects,
  WalletType.services,
  WalletType.books,
];

const List<WalletType> _rightWallets = [
  WalletType.social,
  WalletType.cv,
  WalletType.contact,
];

class SideWallets extends StatelessWidget {
  final bool isDark;
  final WalletSide side;
  final WalletType? activeWallet;
  final Function(WalletType) onWalletTap;
  final VoidCallback onClose;
  final bool isCompact;
  final FirebaseService firebaseService;

  const SideWallets({
    super.key,
    required this.isDark,
    required this.side,
    required this.activeWallet,
    required this.onWalletTap,
    required this.onClose,
    this.isCompact = false,
    required this.firebaseService,
  });

  @override
  Widget build(BuildContext context) {
    final wallets = side == WalletSide.left ? _leftWallets : _rightWallets;
    final isExpanded = activeWallet != null && wallets.contains(activeWallet);

    final collapsedWidth = isCompact ? 56.0 : AppConstants.sidebarCollapsed;
    final expandedWidth = isCompact ? 320.0 : AppConstants.sidebarExpanded;

    return AnimatedContainer(
      duration: AppConstants.durationMedium,
      curve: AppConstants.curveStandard,
      width: isExpanded ? expandedWidth : collapsedWidth,
      child: Stack(
        children: [
          Positioned.fill(
            child: _WalletNav(
              isDark: isDark,
              wallets: wallets,
              activeType: activeWallet,
              onTap: onWalletTap,
            ),
          ),
          if (isExpanded && activeWallet != null)
            Positioned.fill(
              child: _WalletPanel(
                isDark: isDark,
                walletType: activeWallet!,
                onClose: onClose,
                firebaseService: firebaseService,
              ),
            ),
        ],
      ),
    );
  }
}

class _WalletNav extends StatelessWidget {
  final bool isDark;
  final List<WalletType> wallets;
  final WalletType? activeType;
  final Function(WalletType) onTap;

  const _WalletNav({
    required this.isDark,
    required this.wallets,
    required this.activeType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: AppConstants.space12),
      child: Column(
        children: wallets.asMap().entries.map((entry) {
          final index = entry.key;
          final type = entry.value;
          final isActive = activeType == type;

          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.space12,
              vertical: AppConstants.space4,
            ),
            child: _NavItem(
              type: type,
              isActive: isActive,
              onTap: () => onTap(type),
            )
                .animate()
                .fadeIn(
                  delay: Duration(milliseconds: 100 + (index * 50)),
                  duration: AppConstants.durationMedium,
                )
                .slideX(
                  begin: 0.2,
                  delay: Duration(milliseconds: 100 + (index * 50)),
                  duration: AppConstants.durationMedium,
                  curve: AppConstants.curveStandard,
                ),
          );
        }).toList(),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final WalletType type;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.type,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: isActive ? colorScheme.secondaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(AppConstants.radiusMD),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppConstants.space12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                type.icon,
                color: isActive
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.onSurfaceVariant,
                size: AppConstants.iconMD,
              ),
              const SizedBox(height: AppConstants.space4),
              Text(
                type.displayName,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isActive
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletPanel extends StatelessWidget {
  final bool isDark;
  final WalletType walletType;
  final VoidCallback onClose;
  final FirebaseService firebaseService;

  const _WalletPanel({
    required this.isDark,
    required this.walletType,
    required this.onClose,
    required this.firebaseService,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.horizontal(
          left: Radius.circular(AppConstants.radiusLG),
          right: Radius.circular(AppConstants.radiusLG),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.space16),
            child: Row(
              children: [
                Icon(walletType.icon, color: walletType.accentColor),
                const SizedBox(width: AppConstants.space12),
                Expanded(
                  child: Text(
                    walletType.displayName,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainerHigh,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colorScheme.outlineVariant),
          Expanded(child: _buildContent()),
        ],
      ),
    ).animate().fadeIn(duration: AppConstants.durationFast).slideX(
          begin: 0.1,
          duration: AppConstants.durationMedium,
          curve: AppConstants.curveStandard,
        );
  }

  Widget _buildContent() {
    switch (walletType) {
      case WalletType.projects:
        return StreamBuilder<List<ProjectModel>>(
          stream: firebaseService.getProjects(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return ProjectsContent(
              projects: snapshot.data ?? [],
              isDark: isDark,
              isMobile: false,
            );
          },
        );
      case WalletType.services:
        return StreamBuilder<List<ServiceModel>>(
          stream: firebaseService.getServices(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return ServicesContent(
              services: snapshot.data ?? [],
              isDark: isDark,
              isMobile: false,
            );
          },
        );
      case WalletType.books:
        return StreamBuilder<List<BookModel>>(
          stream: firebaseService.getBooks(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return BooksContent(
              books: snapshot.data ?? [],
              isDark: isDark,
              isMobile: false,
            );
          },
        );
      case WalletType.social:
        return StreamBuilder<List<SocialModel>>(
          stream: firebaseService.getSocial(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return SocialContent(
              socials: snapshot.data ?? [],
              isDark: isDark,
              isMobile: false,
            );
          },
        );
      case WalletType.cv:
        return StreamBuilder<CvModel?>(
          stream: firebaseService.getCv(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return CvContent(
              cv: snapshot.data,
              isDark: isDark,
              isMobile: false,
            );
          },
        );
      case WalletType.contact:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.space24),
            child: Text('Contact content here'),
          ),
        );
    }
  }
}
