import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/theme_provider.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/center_stage.dart';
import '../../widgets/side_wallets.dart';
import '../../widgets/bottom_bar.dart';
import '../../widgets/background_effects.dart';
import '../wallet/wallet_content/projects_wallet.dart';
import '../wallet/wallet_content/services_wallet.dart';
import '../wallet/wallet_content/books_wallet.dart';
import '../wallet/wallet_content/social_wallet.dart';
import '../wallet/wallet_content/cv_wallet.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/portfolio_voice_service.dart';
import '../../data/models/project_model.dart';
import '../../data/models/service_model.dart';
import '../../data/models/book_model.dart';
import '../../data/models/social_model.dart';
import '../../data/models/cv_model.dart';

enum WalletType {
  projects,
  services,
  books,
  social,
  cv,
  contact;

  String get displayName {
    switch (this) {
      case WalletType.projects:
        return 'Projects';
      case WalletType.services:
        return 'Services';
      case WalletType.books:
        return 'Books';
      case WalletType.social:
        return 'Social';
      case WalletType.cv:
        return 'Resume';
      case WalletType.contact:
        return 'Contact';
    }
  }

  IconData get icon {
    switch (this) {
      case WalletType.projects:
        return Icons.dashboard_outlined;
      case WalletType.services:
        return Icons.build_outlined;
      case WalletType.books:
        return Icons.menu_book_outlined;
      case WalletType.social:
        return Icons.share_outlined;
      case WalletType.cv:
        return Icons.description_outlined;
      case WalletType.contact:
        return Icons.mail_outline;
    }
  }

  Color get accentColor {
    switch (this) {
      case WalletType.projects:
        return const Color(0xFF6750A4);
      case WalletType.services:
        return const Color(0xFF7D5260);
      case WalletType.books:
        return const Color(0xFF625B71);
      case WalletType.social:
        return const Color(0xFF6750A4);
      case WalletType.cv:
        return const Color(0xFF7D5260);
      case WalletType.contact:
        return const Color(0xFF625B71);
    }
  }
}

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const HomeScreen({super.key, required this.onToggleTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  WalletType? _activeWallet;
  final List<Map<String, String>> _conversation = [];
  late final AnimationController _backgroundController;
  final _firebaseService = FirebaseService();
  PortfolioVoiceService? _voiceService;
  bool _isAgentSpeaking = false;
  bool _voiceInitialized = false;
  StreamSubscription? _voiceMessageSub;
  StreamSubscription? _voiceStateSub;

  Timer? _idleTimer;
  int _idlePromptCount = 0;
  static const int _maxIdlePrompts = 2;
  static const String _kWelcomeTrigger =
      'Please welcome the visitor who just arrived at this portfolio website warmly and briefly introduce yourself.';
  static const String _kIdleTrigger =
      'The visitor has been quiet for a while. Please gently and warmly ask if they have any questions or if there is anything you can help them discover.';

  List<ProjectModel> _projects = [];
  List<ServiceModel> _services = [];
  List<BookModel> _books = [];
  List<SocialModel> _socials = [];
  CvModel? _cv;

  final List<StreamSubscription> _firestoreSubs = [];

  bool _isSystemTrigger(String text) =>
      text == _kWelcomeTrigger || text == _kIdleTrigger;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _initializeData();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _idleTimer?.cancel();
    _voiceMessageSub?.cancel();
    _voiceStateSub?.cancel();
    for (final sub in _firestoreSubs) {
      sub.cancel();
    }
    _voiceService?.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      await _loadFirebaseData();
      await _initializeVoiceAgent();
    } catch (e) {
      debugPrint('Initialization error: $e');
    }
  }

  Future<void> _loadFirebaseData() async {
    final results = await Future.wait([
      _firebaseService.getProjects().first,
      _firebaseService.getServices().first,
      _firebaseService.getBooks().first,
      _firebaseService.getSocial().first,
      _firebaseService.getCv().first,
    ]);

    if (mounted) {
      setState(() {
        _projects = results[0] as List<ProjectModel>;
        _services = results[1] as List<ServiceModel>;
        _books = results[2] as List<BookModel>;
        _socials = results[3] as List<SocialModel>;
        _cv = results[4] as CvModel?;
      });
    }

    _firestoreSubs.add(_firebaseService.getProjects().skip(1).listen((data) {
      if (mounted) setState(() => _projects = data);
    }));
    _firestoreSubs.add(_firebaseService.getServices().skip(1).listen((data) {
      if (mounted) setState(() => _services = data);
    }));
    _firestoreSubs.add(_firebaseService.getBooks().skip(1).listen((data) {
      if (mounted) setState(() => _books = data);
    }));
    _firestoreSubs.add(_firebaseService.getSocial().skip(1).listen((data) {
      if (mounted) setState(() => _socials = data);
    }));
    _firestoreSubs.add(_firebaseService.getCv().skip(1).listen((data) {
      if (mounted) setState(() => _cv = data);
    }));
  }

  Future<void> _initializeVoiceAgent() async {
    try {
      final configDoc = await FirebaseFirestore.instance
          .collection('config')
          .doc('azure_voice_portfolio')
          .get();

      if (!configDoc.exists || !mounted) return;

      final data = configDoc.data()!;
      final apiKey = data['apiKey'] as String? ?? '';
      final resourceName = data['resourceName'] as String? ?? '';

      if (apiKey.isEmpty || resourceName.isEmpty) {
        debugPrint('Voice config incomplete');
        return;
      }

      _voiceService = PortfolioVoiceService();

      _voiceMessageSub = _voiceService!.messageStream.listen((message) {
        if (!mounted) return;
        if (message.isUser && _isSystemTrigger(message.text)) return;
        setState(() {
          _conversation.add({
            'role': message.isUser ? 'user' : 'agent',
            'message': message.text,
          });
          _isAgentSpeaking = !message.isUser;
        });
        if (!message.isUser) _resetIdleTimer();
      });

      _voiceStateSub = _voiceService!.stateStream.listen((state) {
        if (!mounted) return;
        if (state == VoiceState.listening || state == VoiceState.idle) {
          setState(() => _isAgentSpeaking = false);
        } else if (state == VoiceState.speaking) {
          setState(() => _isAgentSpeaking = true);
        }
      });

      await _voiceService!.initialize(
        apiKey: apiKey,
        resourceName: resourceName,
        model: data['model'] as String? ?? 'gpt-4.1',
        voiceName: data['voiceName'] as String? ?? 'en-US-AvaNeural',
        instructions: data['instructions'] as String? ??
            'You are a helpful AI assistant for a portfolio website. Help visitors learn about projects, skills, and experience. Keep responses concise, warm and conversational.',
        projects: _projects,
        services: _services,
        books: _books,
        socials: _socials,
        cv: _cv,
      );

      if (mounted) {
        setState(() => _voiceInitialized = true);
        _triggerWelcome();
      }
    } catch (e) {
      debugPrint('Voice initialization error: $e');
    }
  }

  void _triggerWelcome() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted || _voiceService == null) return;
      _voiceService!.sendTextMessage(_kWelcomeTrigger);
      _resetIdleTimer();
    });
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: 28), _sendIdlePrompt);
  }

  void _sendIdlePrompt() {
    if (!mounted || _voiceService == null) return;
    if (_idlePromptCount >= _maxIdlePrompts) return;
    final state = _voiceService!.currentState;
    if (state != VoiceState.listening) {
      _resetIdleTimer();
      return;
    }
    _idlePromptCount++;
    _voiceService!.sendTextMessage(_kIdleTrigger);
    if (_idlePromptCount < _maxIdlePrompts) _resetIdleTimer();
  }

  void _openWallet(WalletType type) {
    if (_activeWallet == type) {
      _closeWallet();
    } else {
      setState(() => _activeWallet = type);
    }
  }

  void _closeWallet() {
    setState(() => _activeWallet = null);
  }

  void _handleQuestionTap(String question) {
    _idlePromptCount = 0;
    _resetIdleTimer();

    if (_voiceInitialized && _voiceService != null) {
      _voiceService!.sendTextMessage(question);
    } else {
      setState(() {
        _conversation.add({'role': 'user', 'message': question});
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _conversation.add({
              'role': 'agent',
              'message': 'Voice agent is connecting. Please try again shortly.',
            });
          });
        }
      });
    }
  }

  void _handleVoiceQuery(String query) {
    _handleQuestionTap(query);
  }

  void _showMobileWalletSheet(BuildContext context, WalletType type) {
    final isDark = ThemeProvider.of(context).isDark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MobileModal(
        walletType: type,
        isDark: isDark,
        firebaseService: _firebaseService,
        onClose: () => Navigator.of(context).pop(),
      ),
    ).then((_) => _closeWallet());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeProvider.of(context).isDark;
    final screenSize = MediaQuery.of(context).size;
    final isMobile = AppConstants.isMobile(screenSize.width);
    final isTablet = AppConstants.isTablet(screenSize.width);

    return Scaffold(
      body: Stack(
        children: [
          BackgroundEffects(isDark: isDark, controller: _backgroundController),
          SafeArea(
            child: isMobile
                ? _MobileLayout(
                    isDark: isDark,
                    conversation: _conversation,
                    isAgentSpeaking: _isAgentSpeaking,
                    onToggleTheme: widget.onToggleTheme,
                    onQuestionTap: _handleQuestionTap,
                    onVoiceQuery: _handleVoiceQuery,
                    voiceService: _voiceService,
                    onWalletTap: (type) {
                      _openWallet(type);
                      _showMobileWalletSheet(context, type);
                    },
                  )
                : _DesktopLayout(
                    isDark: isDark,
                    isTablet: isTablet,
                    conversation: _conversation,
                    isAgentSpeaking: _isAgentSpeaking,
                    activeWallet: _activeWallet,
                    onToggleTheme: widget.onToggleTheme,
                    onQuestionTap: _handleQuestionTap,
                    onVoiceQuery: _handleVoiceQuery,
                    onWalletTap: _openWallet,
                    onCloseWallet: _closeWallet,
                    firebaseService: _firebaseService,
                    voiceService: _voiceService,
                  ),
          ),
        ],
      ),
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  final bool isDark;
  final bool isTablet;
  final List<Map<String, String>> conversation;
  final bool isAgentSpeaking;
  final WalletType? activeWallet;
  final VoidCallback onToggleTheme;
  final Function(String) onQuestionTap;
  final Function(String) onVoiceQuery;
  final Function(WalletType) onWalletTap;
  final VoidCallback onCloseWallet;
  final FirebaseService firebaseService;
  final PortfolioVoiceService? voiceService;

  const _DesktopLayout({
    required this.isDark,
    required this.isTablet,
    required this.conversation,
    required this.isAgentSpeaking,
    required this.activeWallet,
    required this.onToggleTheme,
    required this.onQuestionTap,
    required this.onVoiceQuery,
    required this.onWalletTap,
    required this.onCloseWallet,
    required this.firebaseService,
    this.voiceService,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TopBar(isDark: isDark, onToggleTheme: onToggleTheme),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SideWallets(
                isDark: isDark,
                side: WalletSide.left,
                activeWallet: activeWallet,
                onWalletTap: onWalletTap,
                onClose: onCloseWallet,
                isCompact: isTablet,
                firebaseService: firebaseService,
              ),
              Expanded(
                child: Center(
                  child: CenterStage(
                    isDark: isDark,
                    conversation: conversation,
                    isAgentSpeaking: isAgentSpeaking,
                    onQuestionTap: onQuestionTap,
                    onVoiceQuery: onVoiceQuery,
                    voiceService: voiceService,
                  ),
                ),
              ),
              SideWallets(
                isDark: isDark,
                side: WalletSide.right,
                activeWallet: activeWallet,
                onWalletTap: onWalletTap,
                onClose: onCloseWallet,
                isCompact: isTablet,
                firebaseService: firebaseService,
              ),
            ],
          ),
        ),
        BottomBar(isDark: isDark),
      ],
    );
  }
}

class _MobileLayout extends StatelessWidget {
  final bool isDark;
  final List<Map<String, String>> conversation;
  final bool isAgentSpeaking;
  final VoidCallback onToggleTheme;
  final Function(String) onQuestionTap;
  final Function(String) onVoiceQuery;
  final Function(WalletType) onWalletTap;
  final PortfolioVoiceService? voiceService;

  const _MobileLayout({
    required this.isDark,
    required this.conversation,
    required this.isAgentSpeaking,
    required this.onToggleTheme,
    required this.onQuestionTap,
    required this.onVoiceQuery,
    required this.onWalletTap,
    this.voiceService,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TopBar(isDark: isDark, onToggleTheme: onToggleTheme, isMobile: true),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.space16,
              vertical: AppConstants.space12,
            ),
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                CenterStage(
                  isDark: isDark,
                  conversation: conversation,
                  isAgentSpeaking: isAgentSpeaking,
                  onQuestionTap: onQuestionTap,
                  onVoiceQuery: onVoiceQuery,
                  isMobile: true,
                  voiceService: voiceService,
                ),
                const SizedBox(height: AppConstants.space24),
                _MobileWalletGrid(isDark: isDark, onTap: onWalletTap),
                const SizedBox(height: AppConstants.space24),
              ],
            ),
          ),
        ),
        BottomBar(isDark: isDark, isMobile: true),
      ],
    );
  }
}

class _MobileWalletGrid extends StatelessWidget {
  final bool isDark;
  final Function(WalletType) onTap;

  const _MobileWalletGrid({required this.isDark, required this.onTap});

  static const _walletTypes = [
    WalletType.projects,
    WalletType.services,
    WalletType.books,
    WalletType.social,
    WalletType.cv,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Explore', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppConstants.space12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppConstants.space12,
            mainAxisSpacing: AppConstants.space12,
            childAspectRatio: 2.0,
          ),
          itemCount: _walletTypes.length,
          itemBuilder: (context, index) {
            return _MobileWalletCard(
              walletType: _walletTypes[index],
              isDark: isDark,
              onTap: () => onTap(_walletTypes[index]),
            )
                .animate()
                .fadeIn(
                  delay: Duration(milliseconds: 50 * index),
                  duration: AppConstants.durationMedium,
                )
                .scale(
                  begin: const Offset(0.9, 0.9),
                  delay: Duration(milliseconds: 50 * index),
                  duration: AppConstants.durationMedium,
                  curve: AppConstants.curveStandard,
                );
          },
        ),
      ],
    );
  }
}

class _MobileWalletCard extends StatelessWidget {
  final WalletType walletType;
  final bool isDark;
  final VoidCallback onTap;

  const _MobileWalletCard({
    required this.walletType,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(AppConstants.radiusMD),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.space12),
          child: Row(
            children: [
              Icon(walletType.icon, color: walletType.accentColor, size: 20),
              const SizedBox(width: AppConstants.space8),
              Expanded(
                child: Text(
                  walletType.displayName,
                  style: theme.textTheme.labelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileModal extends StatelessWidget {
  final WalletType walletType;
  final bool isDark;
  final FirebaseService firebaseService;
  final VoidCallback onClose;

  const _MobileModal({
    required this.walletType,
    required this.isDark,
    required this.firebaseService,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.9,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXL),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppConstants.space12),
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppConstants.space16),
            child: Row(
              children: [
                Icon(walletType.icon, color: walletType.accentColor),
                const SizedBox(width: AppConstants.space12),
                Expanded(
                  child: Text(walletType.displayName,
                      style: theme.textTheme.titleLarge),
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
    )
        .animate()
        .slideY(
          begin: 0.1,
          duration: AppConstants.durationMedium,
          curve: AppConstants.curveStandard,
        )
        .fadeIn(duration: AppConstants.durationFast);
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
              isMobile: true,
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
              isMobile: true,
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
              isMobile: true,
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
              isMobile: true,
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
              isMobile: true,
            );
          },
        );
      case WalletType.contact:
        return _ContactContent(isDark: isDark);
    }
  }
}

class _ContactContent extends StatelessWidget {
  final bool isDark;

  const _ContactContent({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mail_outline, size: 64, color: colorScheme.primary),
            const SizedBox(height: AppConstants.space24),
            Text('Get in Touch', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppConstants.space8),
            Text(
              AppConstants.appEmail,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppConstants.space24),
            FilledButton.icon(
              onPressed: () async {
                final uri = Uri.parse('mailto:${AppConstants.appEmail}');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              icon: const Icon(Icons.send),
              label: const Text('Send Email'),
            ),
          ],
        ),
      ),
    );
  }
}
