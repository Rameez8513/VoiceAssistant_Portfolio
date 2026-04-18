import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants/app_constants.dart';
import '../data/services/portfolio_voice_service.dart';

class CenterStage extends StatefulWidget {
  final bool isDark;
  final List<Map<String, String>> conversation;
  final bool isAgentSpeaking;
  final Function(String) onQuestionTap;
  final Function(String) onVoiceQuery;
  final bool isMobile;
  final PortfolioVoiceService? voiceService;

  const CenterStage({
    super.key,
    required this.isDark,
    required this.conversation,
    required this.isAgentSpeaking,
    required this.onQuestionTap,
    required this.onVoiceQuery,
    this.isMobile = false,
    this.voiceService,
  });

  @override
  State<CenterStage> createState() => _CenterStageState();
}

class _CenterStageState extends State<CenterStage> {
  final ScrollController _scrollController = ScrollController();
  VoiceState _voiceState = VoiceState.idle;
  VoiceState _displayedVoiceState = VoiceState.idle;
  StreamSubscription? _voiceStateSub;
  Timer? _speakingDebounce;

  @override
  void initState() {
    super.initState();
    _subscribeVoiceState();
  }

  void _subscribeVoiceState() {
    _voiceStateSub?.cancel();
    _voiceStateSub = widget.voiceService?.stateStream.listen((s) {
      if (!mounted) return;
      _voiceState = s;
      _updateDisplayedState(s);
    });
    if (widget.voiceService != null) {
      _voiceState = widget.voiceService!.currentState;
      _displayedVoiceState = _voiceState;
    }
  }

  void _updateDisplayedState(VoiceState newState) {
    _speakingDebounce?.cancel();

    if (newState == VoiceState.speaking) {
      _speakingDebounce = Timer(const Duration(milliseconds: 120), () {
        if (!mounted || _voiceState != VoiceState.speaking) return;
        setState(() => _displayedVoiceState = VoiceState.speaking);
      });
    } else if (newState == VoiceState.listening) {
      _speakingDebounce = Timer(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        setState(() => _displayedVoiceState = VoiceState.listening);
      });
    } else {
      setState(() => _displayedVoiceState = newState);
    }
  }

  @override
  void didUpdateWidget(CenterStage old) {
    super.didUpdateWidget(old);
    if (widget.voiceService != old.voiceService) _subscribeVoiceState();
    if (widget.conversation.length != old.conversation.length) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final pos = _scrollController.position;
      if (pos.maxScrollExtent <= 0) return;
      _scrollController.animateTo(
        pos.maxScrollExtent,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _speakingDebounce?.cancel();
    _voiceStateSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasConversation = widget.conversation.isNotEmpty;
    if (widget.isMobile) return _buildMobile(context, hasConversation);
    return LayoutBuilder(builder: (context, constraints) {
      final h = constraints.maxHeight.isFinite ? constraints.maxHeight : 700.0;
      return SizedBox(height: h, child: _buildDesktop(context, hasConversation));
    });
  }

  Widget _buildDesktop(BuildContext context, bool hasConversation) {
    return Column(
      mainAxisAlignment:
          hasConversation ? MainAxisAlignment.start : MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (!hasConversation) ...[
          _HeroSection(isDark: widget.isDark, isMobile: false),
          const SizedBox(height: 28),
        ] else
          const SizedBox(height: 16),
        _PremiumVoiceOrb(
          isDark: widget.isDark,
          isMobile: false,
          voiceState: _displayedVoiceState,
        ),
        const SizedBox(height: 20),
        if (hasConversation)
          Expanded(
            child: _ConversationView(
              conversation: widget.conversation,
              scrollController: _scrollController,
              isMobile: false,
              voiceState: _displayedVoiceState,
            ),
          )
        else
          const SizedBox(height: 8),
        _QuickActions(
          isDark: widget.isDark,
          onTap: widget.onQuestionTap,
          isMobile: false,
          voiceState: _displayedVoiceState,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMobile(BuildContext context, bool hasConversation) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!hasConversation) ...[
          _HeroSection(isDark: widget.isDark, isMobile: true),
          const SizedBox(height: 20),
        ],
        _PremiumVoiceOrb(
          isDark: widget.isDark,
          isMobile: true,
          voiceState: _displayedVoiceState,
        ),
        const SizedBox(height: 18),
        if (hasConversation) ...[
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: _ConversationView(
              conversation: widget.conversation,
              scrollController: _scrollController,
              isMobile: true,
              voiceState: _displayedVoiceState,
            ),
          ),
          const SizedBox(height: 12),
        ],
        _QuickActions(
          isDark: widget.isDark,
          onTap: widget.onQuestionTap,
          isMobile: true,
          voiceState: _displayedVoiceState,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _HeroSection extends StatelessWidget {
  final bool isDark;
  final bool isMobile;

  const _HeroSection({required this.isDark, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          AppConstants.appName,
          style: isMobile
              ? theme.textTheme.headlineMedium
              : theme.textTheme.headlineLarge,
          textAlign: TextAlign.center,
        )
            .animate()
            .fadeIn(duration: 600.ms)
            .slideY(begin: 0.12, duration: 600.ms),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppConstants.appRole,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 500.ms)
            .slideY(begin: 0.12, delay: 200.ms, duration: 500.ms),
      ],
    );
  }
}

class _ConversationView extends StatelessWidget {
  final List<Map<String, String>> conversation;
  final ScrollController scrollController;
  final bool isMobile;
  final VoiceState voiceState;

  const _ConversationView({
    required this.conversation,
    required this.scrollController,
    required this.isMobile,
    required this.voiceState,
  });

  bool get _showTyping =>
      voiceState == VoiceState.processing &&
      (conversation.isEmpty || conversation.last['role'] == 'user');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainer.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                physics: const BouncingScrollPhysics(),
                itemCount: conversation.length + (_showTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == conversation.length && _showTyping) {
                    return _TypingIndicator(cs: cs);
                  }
                  final msg = conversation[index];
                  final isUser = msg['role'] == 'user';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _MessageBubble(
                      message: msg['message'] ?? '',
                      isUser: isUser,
                      index: index,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  final ColorScheme cs;

  const _TypingIndicator({required this.cs});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8, bottom: 2),
            decoration: BoxDecoration(
              color: widget.cs.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome,
                size: 14, color: widget.cs.onPrimaryContainer),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: widget.cs.surfaceContainerHigh,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final delay = i * 0.33;
                    final val = (_ctrl.value + delay) % 1.0;
                    final scale = 0.5 + (math.sin(val * math.pi) * 0.5);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: widget.cs.onSurfaceVariant
                            .withOpacity(0.4 + scale * 0.5),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 200.ms)
        .slideX(begin: -0.05, duration: 200.ms);
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final int index;

  const _MessageBubble({
    required this.message,
    required this.isUser,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isUser) ...[
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8, bottom: 2),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome,
                size: 14, color: cs.onPrimaryContainer),
          ),
        ],
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser ? cs.primary : cs.surfaceContainerHigh,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 18),
              ),
              boxShadow: [
                BoxShadow(
                  color: isUser
                      ? cs.primary.withOpacity(0.25)
                      : Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isUser ? cs.onPrimary : cs.onSurface,
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 280.ms).slideX(
          begin: isUser ? 0.06 : -0.06,
          duration: 280.ms,
          curve: Curves.easeOut,
        );
  }
}

class _PremiumVoiceOrb extends StatefulWidget {
  final bool isDark;
  final bool isMobile;
  final VoiceState voiceState;

  const _PremiumVoiceOrb({
    required this.isDark,
    required this.isMobile,
    required this.voiceState,
  });

  @override
  State<_PremiumVoiceOrb> createState() => _PremiumVoiceOrbState();
}

class _PremiumVoiceOrbState extends State<_PremiumVoiceOrb>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _rotateCtrl;
  late final AnimationController _breathCtrl;
  late final AnimationController _waveCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _rotateCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat();
    _breathCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
    _waveCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    _breathCtrl.dispose();
    _waveCtrl.dispose();
    super.dispose();
  }

  Color _primary(ColorScheme cs) {
    switch (widget.voiceState) {
      case VoiceState.idle:
        return cs.onSurfaceVariant;
      case VoiceState.connecting:
        return cs.tertiary;
      case VoiceState.listening:
        return cs.primary;
      case VoiceState.speaking:
        return cs.secondary;
      case VoiceState.processing:
        return cs.tertiary;
      case VoiceState.error:
        return cs.error;
    }
  }

  Color _secondary(ColorScheme cs) {
    switch (widget.voiceState) {
      case VoiceState.idle:
        return cs.surfaceContainerHigh;
      case VoiceState.connecting:
        return cs.tertiaryContainer;
      case VoiceState.listening:
        return cs.primaryContainer;
      case VoiceState.speaking:
        return cs.secondaryContainer;
      case VoiceState.processing:
        return cs.tertiaryContainer;
      case VoiceState.error:
        return cs.errorContainer;
    }
  }

  String _label() {
    switch (widget.voiceState) {
      case VoiceState.idle:
        return 'Initializing';
      case VoiceState.connecting:
        return 'Connecting';
      case VoiceState.listening:
        return 'Listening';
      case VoiceState.speaking:
        return 'Speaking';
      case VoiceState.processing:
        return 'Thinking';
      case VoiceState.error:
        return 'Reconnecting';
    }
  }

  bool get _isSpeaking => widget.voiceState == VoiceState.speaking;
  bool get _isListening => widget.voiceState == VoiceState.listening;
  bool get _isProcessing => widget.voiceState == VoiceState.processing;
  bool get _isConnecting => widget.voiceState == VoiceState.connecting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final primary = _primary(cs);
    final secondary = _secondary(cs);
    final orbSize = widget.isMobile ? 110.0 : 130.0;
    final totalSize = orbSize + 80;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge(
              [_pulseCtrl, _rotateCtrl, _breathCtrl, _waveCtrl]),
          builder: (context, _) {
            final breathScale = 1.0 + (_breathCtrl.value * 0.05);
            final speakScale = _isSpeaking
                ? 1.0 + (math.sin(_pulseCtrl.value * math.pi) * 0.10)
                : breathScale;

            return SizedBox(
              width: totalSize,
              height: totalSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_isSpeaking)
                    ...List.generate(4, (i) {
                      final delay = i * 0.25;
                      final p = (_waveCtrl.value + delay) % 1.0;
                      final opacity = (1.0 - p) * 0.45;
                      final size = orbSize * (0.9 + p * 0.8);
                      return Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: primary.withOpacity(opacity),
                            width: 1.5,
                          ),
                        ),
                      );
                    }),
                  if (_isListening)
                    ...List.generate(2, (i) {
                      final p = (_breathCtrl.value + i * 0.5) % 1.0;
                      return Container(
                        width: orbSize + 20 + (p * 18),
                        height: orbSize + 20 + (p * 18),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: primary.withOpacity(0.25 - p * 0.15),
                            width: 1,
                          ),
                        ),
                      );
                    }),
                  if (_isConnecting || _isProcessing)
                    Transform.rotate(
                      angle: _rotateCtrl.value * 2 * math.pi,
                      child: Container(
                        width: orbSize + 24,
                        height: orbSize + 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              primary.withOpacity(0.0),
                              primary.withOpacity(0.5),
                              primary.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Transform.scale(
                    scale: speakScale,
                    child: Container(
                      width: orbSize,
                      height: orbSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: Alignment.topLeft,
                          radius: 1.2,
                          colors: [
                            secondary.withOpacity(0.95),
                            primary.withOpacity(0.35),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withOpacity(_isSpeaking
                                ? 0.55
                                : _isListening
                                    ? 0.35
                                    : 0.18),
                            blurRadius: _isSpeaking
                                ? 36
                                : _isListening
                                    ? 22
                                    : 12,
                            spreadRadius: _isSpeaking
                                ? 6
                                : _isListening
                                    ? 2
                                    : 0,
                          ),
                          BoxShadow(
                            color: primary.withOpacity(0.08),
                            blurRadius: 60,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned.fill(
                              child: Transform.rotate(
                                angle:
                                    _rotateCtrl.value * 2 * math.pi * 0.5,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: SweepGradient(
                                      colors: [
                                        primary.withOpacity(0.0),
                                        primary.withOpacity(0.15),
                                        primary.withOpacity(0.0),
                                        primary.withOpacity(0.08),
                                        primary.withOpacity(0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            _OrbWaveform(
                              voiceState: widget.voiceState,
                              color: primary,
                              waveValue: _waveCtrl.value,
                              breathValue: _breathCtrl.value,
                              orbSize: orbSize,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_isListening || _isSpeaking)
                    Positioned(
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: primary.withOpacity(0.3), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(4, (i) {
                            final h = _isSpeaking
                                ? (8 +
                                        math.sin((_waveCtrl.value *
                                                    math.pi *
                                                    2) +
                                                i * 0.8) *
                                            10)
                                    .abs()
                                : (4 +
                                        math.sin(
                                                (_breathCtrl.value *
                                                        math.pi) +
                                                    i * 1.2) *
                                            3)
                                    .abs();
                            return Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              width: 3,
                              height: h.clamp(3.0, 18.0),
                              decoration: BoxDecoration(
                                color: primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        )
            .animate()
            .fadeIn(delay: 300.ms, duration: 700.ms)
            .scale(
                begin: const Offset(0.75, 0.75),
                delay: 300.ms,
                duration: 700.ms,
                curve: Curves.elasticOut),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _StatusLabel(
            key: ValueKey(_label()),
            label: _label(),
            color: _primary(cs),
            voiceState: widget.voiceState,
          ),
        ),
      ],
    );
  }
}

class _OrbWaveform extends StatelessWidget {
  final VoiceState voiceState;
  final Color color;
  final double waveValue;
  final double breathValue;
  final double orbSize;

  const _OrbWaveform({
    required this.voiceState,
    required this.color,
    required this.waveValue,
    required this.breathValue,
    required this.orbSize,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(orbSize, orbSize),
      painter: _WaveformPainter(
        voiceState: voiceState,
        color: color,
        waveValue: waveValue,
        breathValue: breathValue,
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final VoiceState voiceState;
  final Color color;
  final double waveValue;
  final double breathValue;

  const _WaveformPainter({
    required this.voiceState,
    required this.color,
    required this.waveValue,
    required this.breathValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint()
      ..color = color.withOpacity(0.7)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (voiceState == VoiceState.speaking) {
      const bars = 7;
      final spacing = size.width * 0.6 / bars;
      final startX = cx - (spacing * (bars - 1)) / 2;
      for (int i = 0; i < bars; i++) {
        final phase = waveValue * math.pi * 2 + i * 0.6;
        final h = (18 + math.sin(phase) * 16).abs();
        final x = startX + i * spacing;
        paint.strokeWidth = 2.5;
        canvas.drawLine(Offset(x, cy - h), Offset(x, cy + h), paint);
      }
    } else if (voiceState == VoiceState.listening) {
      paint.strokeWidth = 1.5;
      paint.color = color.withOpacity(0.5);
      const pts = 60;
      final path = Path();
      final radius = size.width * 0.28;
      for (int i = 0; i <= pts; i++) {
        final angle = (i / pts) * math.pi * 2;
        final noise =
            math.sin(angle * 3 + breathValue * math.pi * 2) * 4;
        final r = radius + noise;
        final x = cx + math.cos(angle) * r;
        final y = cy + math.sin(angle) * r;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    } else if (voiceState == VoiceState.processing ||
        voiceState == VoiceState.connecting) {
      paint.color = color.withOpacity(0.4);
      paint.strokeWidth = 1.5;
      for (int ring = 0; ring < 3; ring++) {
        final r = size.width * (0.12 + ring * 0.08);
        canvas.drawCircle(Offset(cx, cy), r, paint);
      }
    } else {
      paint.color = color.withOpacity(0.25);
      paint.strokeWidth = 1;
      canvas.drawCircle(Offset(cx, cy), size.width * 0.2, paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.waveValue != waveValue ||
      old.breathValue != breathValue ||
      old.voiceState != voiceState;
}

class _StatusLabel extends StatelessWidget {
  final String label;
  final Color color;
  final VoiceState voiceState;

  const _StatusLabel({
    super.key,
    required this.label,
    required this.color,
    required this.voiceState,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDot = voiceState == VoiceState.connecting ||
        voiceState == VoiceState.processing;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDot)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: SizedBox(
              width: 8,
              height: 8,
              child: CircularProgressIndicator(
                  strokeWidth: 1.5, color: color),
            ),
          )
        else
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 7),
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  final bool isDark;
  final Function(String) onTap;
  final bool isMobile;
  final VoiceState voiceState;

  const _QuickActions({
    required this.isDark,
    required this.onTap,
    required this.isMobile,
    required this.voiceState,
  });

  static const _actions = [
    'What projects have you built?',
    'What skills do you bring?',
    'Are you open to work?',
    'How can I reach you?',
  ];

  bool get _isEnabled =>
      voiceState == VoiceState.listening || voiceState == VoiceState.idle;

  String get _statusText {
    switch (voiceState) {
      case VoiceState.connecting:
        return 'Connecting to assistant...';
      case VoiceState.processing:
        return 'Assistant is thinking...';
      case VoiceState.speaking:
        return 'Assistant is speaking...';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: !_isEnabled && _statusText.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _statusText,
                      key: ValueKey(voiceState),
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: _actions.asMap().entries.map((e) {
              return _ActionChip(
                text: e.value,
                index: e.key,
                isEnabled: _isEnabled,
                onTap: () => onTap(e.value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String text;
  final int index;
  final bool isEnabled;
  final VoidCallback onTap;

  const _ActionChip({
    required this.text,
    required this.index,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isEnabled ? 1.0 : 0.4,
      child: ActionChip(
        label: Text(text),
        onPressed: isEnabled ? onTap : null,
        labelStyle: theme.textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      )
          .animate()
          .fadeIn(
              delay: Duration(milliseconds: 400 + (index * 60)),
              duration: 350.ms)
          .scale(
            begin: const Offset(0.88, 0.88),
            delay: Duration(milliseconds: 400 + (index * 60)),
            duration: 350.ms,
            curve: Curves.easeOut,
          ),
    );
  }
}