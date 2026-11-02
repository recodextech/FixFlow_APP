import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../services/notification_service.dart';

/// Keeps a screen's job data fresh: refetches when a push notification
/// arrives (new job suggestion, claim approval, ...) and polls on an interval
/// while the screen is visible and the app is in the foreground.
mixin LiveRefreshMixin<T extends StatefulWidget> on State<T> {
  static const Duration liveRefreshInterval = Duration(seconds: 10);

  Timer? _liveRefreshTimer;
  StreamSubscription<RemoteMessage>? _notificationSubscription;
  AppLifecycleListener? _lifecycleListener;
  bool _isLiveRefreshing = false;
  bool _isLiveRefreshQueued = false;

  /// Refetch the screen's data without showing a loading state.
  Future<void> onLiveRefresh();

  void startLiveRefresh() {
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        _startTimer();
        _runLiveRefresh();
      },
      onHide: () => _liveRefreshTimer?.cancel(),
    );
    _notificationSubscription = NotificationService.messages.listen(
      (_) => _runLiveRefresh(),
    );
    _startTimer();
  }

  void stopLiveRefresh() {
    _lifecycleListener?.dispose();
    _notificationSubscription?.cancel();
    _liveRefreshTimer?.cancel();
  }

  void _startTimer() {
    _liveRefreshTimer?.cancel();
    _liveRefreshTimer = Timer.periodic(liveRefreshInterval, (_) {
      // Skip polling while another route (details, dialog) covers this screen.
      if (ModalRoute.of(context)?.isCurrent == false) return;
      _runLiveRefresh();
    });
  }

  Future<void> _runLiveRefresh() async {
    if (!mounted) return;
    if (_isLiveRefreshing) {
      // The running fetch may predate the change a notification announced.
      _isLiveRefreshQueued = true;
      return;
    }
    _isLiveRefreshing = true;
    try {
      await onLiveRefresh();
    } catch (error) {
      // Keep showing the current data; the next tick retries.
      debugPrint('Live refresh failed: $error');
    } finally {
      _isLiveRefreshing = false;
    }
    if (_isLiveRefreshQueued) {
      _isLiveRefreshQueued = false;
      _runLiveRefresh();
    }
  }

  /// Fetches [load] and hands back the result as an already-completed future,
  /// so a FutureBuilder swaps in the new data without flashing its spinner.
  /// Callers should only assign it if their future was not replaced meanwhile
  /// (e.g. by a user action), so stale data never overwrites newer data.
  Future<Future<R>> silentlyLoad<R>(Future<R> Function() load) async {
    return SynchronousFuture<R>(await load());
  }
}
