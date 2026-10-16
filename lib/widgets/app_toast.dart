import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../theme.dart';

enum ToastType { success, error, warning, info }

/// Shows short messages at the top of the screen that slide in and disappear
/// on their own. Tap or swipe up to dismiss early. Only one toast is visible
/// at a time; a new one replaces the current one.
class AppToast {
  AppToast._();

  /// Attach to MaterialApp.navigatorKey so toasts can be shown from anywhere.
  static final navigatorKey = GlobalKey<NavigatorState>();

  static _ToastEntry? _current;

  static void success(String message) => show(message, type: ToastType.success);

  static void error(String message) => show(message, type: ToastType.error);

  static void warning(String message) => show(message, type: ToastType.warning);

  static void info(String message) => show(message, type: ToastType.info);

  /// Shows an API or unexpected error. Job state conflicts (HTTP 409) get a
  /// clear localized message and a warning style, since the user can refresh
  /// and act again. Other errors are prefixed with [fallback].
  static void fromError(
    Object error, {
    required AppLocalizations loc,
    String? fallback,
  }) {
    if (error is ApiException && error.isConflict) {
      show(loc.conflictMessage(error.message), type: ToastType.warning);
      return;
    }
    show(describeError(error, fallback: fallback), type: ToastType.error);
  }

  /// "fallback: reason" without Dart's "Exception: " prefix.
  static String describeError(Object error, {String? fallback}) {
    var reason = error is ApiException ? error.message : error.toString();
    reason = reason.replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
    if (fallback == null || fallback.isEmpty) return reason;
    if (reason.isEmpty) return fallback;
    return '$fallback: $reason';
  }

  static void show(
    String message, {
    ToastType type = ToastType.info,
    Duration? duration,
  }) {
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) {
      debugPrint('AppToast: no overlay to show "$message"');
      return;
    }

    _current?.remove();
    final entry = _ToastEntry(
      message: message,
      type: type,
      duration: duration ?? _defaultDuration(type),
    );
    _current = entry;
    entry.insert(
      overlay,
      onRemoved: () {
        if (identical(_current, entry)) _current = null;
      },
    );
  }

  static Duration _defaultDuration(ToastType type) {
    switch (type) {
      case ToastType.error:
      case ToastType.warning:
        return const Duration(seconds: 4);
      case ToastType.success:
      case ToastType.info:
        return const Duration(milliseconds: 2800);
    }
  }
}

class _ToastEntry {
  final String message;
  final ToastType type;
  final Duration duration;
  OverlayEntry? _overlayEntry;
  VoidCallback? _onRemoved;

  _ToastEntry({
    required this.message,
    required this.type,
    required this.duration,
  });

  void insert(OverlayState overlay, {required VoidCallback onRemoved}) {
    _onRemoved = onRemoved;
    _overlayEntry = OverlayEntry(
      builder: (_) => _TopToast(
        message: message,
        type: type,
        duration: duration,
        onDismissed: remove,
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  void remove() {
    final entry = _overlayEntry;
    if (entry == null) return;
    _overlayEntry = null;
    entry.remove();
    _onRemoved?.call();
  }
}

class _TopToast extends StatefulWidget {
  final String message;
  final ToastType type;
  final Duration duration;
  final VoidCallback onDismissed;

  const _TopToast({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    reverseDuration: const Duration(milliseconds: 220),
  );
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, -1.2),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(widget.duration, _close);
  }

  Future<void> _close() async {
    if (_closing || !mounted) return;
    _closing = true;
    _timer?.cancel();
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = _ToastStyle.of(widget.type);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _controller,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: GestureDetector(
                onTap: _close,
                onVerticalDragEnd: (details) {
                  if ((details.primaryVelocity ?? 0) < 0) _close();
                },
                child: Material(
                  color: Colors.transparent,
                  child: Semantics(
                    liveRegion: true,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                      decoration: BoxDecoration(
                        color: style.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: style.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: style.accent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              style.icon,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.message,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _close,
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.close,
                              size: 18,
                              color: AppColors.text2,
                            ),
                            tooltip: MaterialLocalizations.of(
                              context,
                            ).closeButtonTooltip,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastStyle {
  final Color accent;
  final Color background;
  final Color border;
  final IconData icon;

  const _ToastStyle(this.accent, this.background, this.border, this.icon);

  static _ToastStyle of(ToastType type) {
    switch (type) {
      case ToastType.success:
        return const _ToastStyle(
          AppColors.green,
          AppColors.greenPale,
          Color(0xFFA5D6A7),
          Icons.check_rounded,
        );
      case ToastType.error:
        return const _ToastStyle(
          AppColors.red,
          AppColors.redPale,
          Color(0xFFEF9A9A),
          Icons.error_outline_rounded,
        );
      case ToastType.warning:
        return const _ToastStyle(
          AppColors.orange,
          AppColors.orangePale,
          Color(0xFFFFCC80),
          Icons.warning_amber_rounded,
        );
      case ToastType.info:
        return const _ToastStyle(
          AppColors.blue,
          AppColors.bluePale,
          Color(0xFF90CAF9),
          Icons.info_outline_rounded,
        );
    }
  }
}
