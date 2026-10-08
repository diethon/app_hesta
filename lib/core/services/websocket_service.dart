import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../app/config/providers.dart';
import '../storage/token_storage.dart';
import '../utils/app_logger.dart';

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  final service = WebSocketService(
    url: environment.wsUrl,
    tokenStorage: ref.watch(tokenStorageProvider),
    logger: ref.watch(appLoggerProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

/// backend_hesta gom chung vào một WebSocket STOMP endpoint duy nhất (:8080/ws)
final notificationWebSocketServiceProvider = Provider<WebSocketService>((ref) {
  return ref.watch(webSocketServiceProvider);
});

/// STOMP client trên WebSocket — CONNECT (kèm JWT Authorization)/SUBSCRIBE/
/// UNSUBSCRIBE/MESSAGE cho topic /topic/homes/{homeId}/events của backend_hesta.
class WebSocketService {
  WebSocketService({
    required this.url,
    TokenStore? tokenStorage,
    required Logger logger,
  })  : _tokenStorage = tokenStorage,
        _logger = logger;

  final String url;
  final TokenStore? _tokenStorage;
  final Logger _logger;

  WebSocket? _socket;
  bool _stompConnected = false;
  bool _connecting = false;
  bool _disposed = false;
  int _subscriptionSeq = 0;
  int _reconnectAttempt = 0;
  Timer? _reconnectTimer;

  /// destination → subscription đang hoạt động.
  final Map<String, _StompSubscription> _subscriptions = {};

  /// Subscribe một destination STOMP; emit body JSON đã decode.
  /// Stream là broadcast — nhiều listener dùng chung một SUBSCRIBE.
  Stream<Map<String, dynamic>> subscribeJson(String destination) {
    final existing = _subscriptions[destination];
    if (existing != null) {
      return existing.controller.stream;
    }

    final subscription = _StompSubscription(
      id: 'sub-${_subscriptionSeq++}',
      destination: destination,
    );
    subscription.controller.onCancel = () {
      if (!subscription.controller.hasListener) {
        _unsubscribe(subscription);
      }
    };
    _subscriptions[destination] = subscription;

    if (_stompConnected) {
      _sendSubscribe(subscription);
    } else {
      unawaited(_ensureConnected());
    }
    return subscription.controller.stream;
  }

  Future<void> _ensureConnected() async {
    if (_disposed || _connecting || _stompConnected) {
      return;
    }
    _connecting = true;
    try {
      final socket = await WebSocket.connect(url);
      _socket = socket;
      socket.listen(
        _onData,
        onDone: _onDisconnected,
        onError: (Object error) {
          _logger.w('WebSocket error: $error');
          _onDisconnected();
        },
        cancelOnError: true,
      );

      final token = await _tokenStorage?.readAccessToken();
      final connectHeaders = <String, String>{
        'accept-version': '1.2',
        'heart-beat': '20000,20000',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };
      _sendFrame('CONNECT', connectHeaders);
    } catch (error) {
      _logger.w('WebSocket connect failed: $error');
      _scheduleReconnect();
    } finally {
      _connecting = false;
    }
  }

  void _onData(dynamic data) {
    final text = data is String ? data : utf8.decode(data as List<int>);
    // Một message WS có thể chứa nhiều frame, ngăn cách bởi NULL.
    for (final raw in text.split('\x00')) {
      final frame = raw.trimLeft();
      if (frame.isEmpty) {
        continue; // heartbeat hoặc phần dư sau NULL
      }
      _handleFrame(frame);
    }
  }

  void _handleFrame(String frame) {
    final headerEnd = frame.indexOf('\n\n');
    final head = headerEnd == -1 ? frame : frame.substring(0, headerEnd);
    final body = headerEnd == -1 ? '' : frame.substring(headerEnd + 2);
    final lines = head.split('\n');
    final command = lines.first.trim();
    final headers = <String, String>{};
    for (final line in lines.skip(1)) {
      final separator = line.indexOf(':');
      if (separator > 0) {
        headers[line.substring(0, separator)] = line.substring(separator + 1);
      }
    }

    switch (command) {
      case 'CONNECTED':
        _stompConnected = true;
        _reconnectAttempt = 0;
        _logger.d('STOMP connected → $url');
        for (final subscription in _subscriptions.values) {
          _sendSubscribe(subscription);
        }
      case 'MESSAGE':
        _dispatchMessage(headers['destination'], body);
      case 'ERROR':
        _logger.w('STOMP ERROR: ${headers['message']} $body');
      default:
        break;
    }
  }

  void _dispatchMessage(String? destination, String body) {
    if (destination == null) {
      return;
    }
    final subscription = _subscriptions[destination];
    if (subscription == null || body.isEmpty) {
      return;
    }
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        subscription.controller.add(decoded);
      }
    } catch (error) {
      _logger.w('STOMP body không phải JSON hợp lệ: $error');
    }
  }

  void _sendSubscribe(_StompSubscription subscription) {
    _sendFrame('SUBSCRIBE', {
      'id': subscription.id,
      'destination': subscription.destination,
    });
  }

  void _unsubscribe(_StompSubscription subscription) {
    _subscriptions.remove(subscription.destination);
    if (_stompConnected) {
      _sendFrame('UNSUBSCRIBE', {'id': subscription.id});
    }
    if (_subscriptions.isEmpty) {
      _closeSocket();
    }
  }

  void _sendFrame(String command, Map<String, String> headers, [String? body]) {
    final socket = _socket;
    if (socket == null) {
      return;
    }
    final buffer = StringBuffer()..writeln(command);
    headers.forEach((key, value) => buffer.writeln('$key:$value'));
    buffer
      ..writeln()
      ..write(body ?? '')
      ..write('\x00');
    socket.add(buffer.toString());
  }

  void _onDisconnected() {
    _stompConnected = false;
    _socket = null;
    if (_disposed || _subscriptions.isEmpty) {
      return;
    }
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed || _reconnectTimer != null) {
      return;
    }
    final delaySeconds = math.min(30, 1 << math.min(5, _reconnectAttempt));
    _reconnectAttempt++;
    _logger.d('STOMP reconnect sau ${delaySeconds}s');
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      _reconnectTimer = null;
      unawaited(_ensureConnected());
    });
  }

  void _closeSocket() {
    _stompConnected = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    final socket = _socket;
    _socket = null;
    unawaited(socket?.close());
  }

  void dispose() {
    _disposed = true;
    for (final subscription in _subscriptions.values) {
      unawaited(subscription.controller.close());
    }
    _subscriptions.clear();
    _closeSocket();
  }
}

class _StompSubscription {
  _StompSubscription({required this.id, required this.destination});

  final String id;
  final String destination;
  final StreamController<Map<String, dynamic>> controller =
      StreamController<Map<String, dynamic>>.broadcast();
}
