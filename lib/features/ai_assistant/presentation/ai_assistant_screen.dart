import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/l10n_extensions.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/glass_tokens.dart';
import '../../../core/widgets/glass/glass.dart';
import '../domain/assistant_models.dart';
import 'assistant_controller.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen>
    with SingleTickerProviderStateMixin {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late final AnimationController _micCtrl;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _micCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _micCtrl.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) {
      return;
    }
    ref
        .read(assistantControllerProvider.notifier)
        .send(text, errorFallback: context.l10n.assistantError);
    _textCtrl.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted || !_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: GlassTokens.durationMed,
        curve: GlassTokens.curve,
      );
    });
  }

  void _toggleMic() {
    setState(() => _isListening = !_isListening);
    if (_isListening) {
      _micCtrl.repeat(reverse: true);
    } else {
      _micCtrl.stop();
      _micCtrl.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final chat = ref.watch(assistantControllerProvider);
    ref.listen(assistantControllerProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    final suggestions = [
      l10n.suggestionEveningScene,
      l10n.suggestionLowerAc,
      l10n.suggestionLockDoor,
      l10n.suggestionEnergyReport,
    ];

    // Bong bóng chào luôn đứng đầu; typing indicator đứng cuối khi đang gửi.
    final bubbles = <_Bubble>[
      _Bubble(text: l10n.assistantGreeting, isUser: false),
      for (final ChatMessage message in chat.messages)
        _Bubble(text: message.text, isUser: message.isUser),
      if (chat.isSending)
        _Bubble(text: l10n.assistantTyping, isUser: false, isPending: true),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: GlassAppBar(
          centerTitle: false,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              boxShadow: GlassTokens.glow(
                theme.colorScheme.primary,
                intensity: 0.4,
              ),
            ),
            child: Icon(
              Icons.smart_toy_outlined,
              color: theme.colorScheme.primary,
              size: 22,
            ),
          ),
          title: l10n.assistantTitle,
          subtitle: l10n.assistantOnline,
        ),
      ),
      body: Column(
        children: [
          // Entry Automation nổi bật.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.md,
              AppSpacing.screen,
              0,
            ),
            child: GlassCard(
              onTap: () => context.push('/automation'),
              radius: AppRadius.card,
              padding: const EdgeInsets.all(AppSpacing.md),
              semanticLabel: l10n.automations,
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      boxShadow: GlassTokens.glow(
                        theme.colorScheme.primary,
                        intensity: 0.35,
                      ),
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.automations,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.automationsSubtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          ),

          // Chat list
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.lg,
                AppSpacing.screen,
                AppSpacing.md,
              ),
              itemCount: bubbles.length,
              itemBuilder: (context, index) {
                return _MessageBubble(message: bubbles[index]);
              },
            ),
          ),

          // Suggestion chips
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, i) {
                return GlassFilterChip(
                  label: suggestions[i],
                  selected: false,
                  onTap: () => _sendMessage(suggestions[i]),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Input bar kính
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screen,
              0,
              AppSpacing.screen,
              AppSpacing.navClearance - AppSpacing.md,
            ),
            child: GlassContainer(
              radius: AppRadius.pill,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textCtrl,
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: l10n.askAnything,
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.45,
                          ),
                        ),
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  GestureDetector(
                    onTap: chat.isSending
                        ? null
                        : () => _sendMessage(_textCtrl.text),
                    child: Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(left: AppSpacing.xs),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: chat.isSending
                            ? theme.colorScheme.primary.withValues(alpha: 0.4)
                            : theme.colorScheme.primary,
                        boxShadow: GlassTokens.glow(
                          theme.colorScheme.primary,
                          intensity: 0.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _toggleMic,
                    child: AnimatedBuilder(
                      animation: _micCtrl,
                      builder: (context, _) {
                        return Container(
                          width: 36,
                          height: 36,
                          margin: const EdgeInsets.only(
                            left: AppSpacing.xs + 2,
                          ),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isListening
                                ? AppColors.auroraError
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.08,
                                  ),
                            boxShadow: _isListening
                                ? [
                                    BoxShadow(
                                      color: AppColors.auroraError.withValues(
                                        alpha: 0.3 + _micCtrl.value * 0.3,
                                      ),
                                      blurRadius: 8 + _micCtrl.value * 8,
                                      spreadRadius: _micCtrl.value * 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            _isListening
                                ? Icons.stop_rounded
                                : Icons.mic_rounded,
                            color: _isListening
                                ? Colors.white
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                            size: 18,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble {
  const _Bubble({
    required this.text,
    required this.isUser,
    this.isPending = false,
  });

  final String text;
  final bool isUser;
  final bool isPending;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final _Bubble message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.15),
              ),
              child: Icon(Icons.smart_toy_outlined, color: accent, size: 18),
            ),
          ],
          Flexible(
            child: GlassContainer(
              radius: AppRadius.lg + 2,
              blur: GlassTokens.blurSm,
              fill: message.isUser ? accent : null,
              shadows: message.isUser
                  ? GlassTokens.glow(accent, intensity: 0.3)
                  : null,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 10,
              ),
              child: Text(
                message.text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                  fontStyle: message.isPending ? FontStyle.italic : null,
                  color: message.isUser
                      ? Colors.white
                      : theme.colorScheme.onSurface.withValues(
                          alpha: message.isPending ? 0.6 : 1,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
