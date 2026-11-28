import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/glass_tokens.dart';
import '../../../../core/widgets/glass/glass_container.dart';

/// Hiển thị luồng video MJPEG trực tiếp (`/video_feed`) bằng `HttpClient` thuần Dart
/// và tự động quay về [fallback] khi dịch vụ AI Edge ngoại tuyến hoặc đang chạy test.
class MjpegLivePlayer extends StatefulWidget {
  const MjpegLivePlayer({
    required this.streamUrl,
    required this.fallback,
    this.reloadSignal = 0,
    super.key,
  });

  final String streamUrl;
  final Widget fallback;
  final int reloadSignal;

  @override
  State<MjpegLivePlayer> createState() => _MjpegLivePlayerState();
}

class _MjpegLivePlayerState extends State<MjpegLivePlayer> {
  HttpClient? _client;
  StreamSubscription<List<int>>? _subscription;
  Uint8List? _currentFrame;
  bool _hasError = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void didUpdateWidget(covariant MjpegLivePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streamUrl != widget.streamUrl ||
        oldWidget.reloadSignal != widget.reloadSignal) {
      _disconnect();
      _currentFrame = null;
      _hasError = false;
      _connect();
    }
  }

  void _connect() {
    final isTestEnv = Platform.environment.containsKey('FLUTTER_TEST');
    if (_disposed || widget.streamUrl.trim().isEmpty || isTestEnv) {
      return;
    }

    final uri = Uri.tryParse(widget.streamUrl.trim());
    if (uri == null || !uri.hasScheme) {
      if (mounted) {
        setState(() => _hasError = true);
      }
      return;
    }

    unawaited(_startStream(uri));
  }

  Future<void> _startStream(Uri uri) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
    _client = client;

    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (_disposed || response.statusCode != 200) {
        if (mounted && !_disposed) {
          setState(() => _hasError = true);
        }
        client.close(force: true);
        return;
      }

      final buffer = <int>[];
      int? soiIndex;

      _subscription = response.listen(
        (chunk) {
          if (_disposed) {
            return;
          }
          buffer.addAll(chunk);
          // Ngăn tràn bộ nhớ nếu stream gửi dữ liệu lỗi kéo dài.
          if (buffer.length > 2 * 1024 * 1024) {
            buffer.clear();
            soiIndex = null;
            return;
          }

          int searchFrom = 0;
          while (true) {
            final start =
                soiIndex ?? _findMarker(buffer, searchFrom, 0xFF, 0xD8);
            if (start == null) {
              if (buffer.length > 1) {
                final lastByte = buffer.last;
                buffer
                  ..clear()
                  ..add(lastByte);
              }
              break;
            }
            soiIndex = start;

            final eoiIndex = _findMarker(buffer, start + 2, 0xFF, 0xD9);
            if (eoiIndex == null) {
              break;
            }

            final frameEnd = eoiIndex + 2;
            final frameBytes = Uint8List.fromList(
              buffer.sublist(start, frameEnd),
            );
            buffer.removeRange(0, frameEnd);
            soiIndex = null;
            searchFrom = 0;

            if (mounted && !_disposed) {
              setState(() {
                _currentFrame = frameBytes;
                _hasError = false;
              });
            }
          }
        },
        onError: (_) {
          if (mounted && !_disposed) {
            setState(() => _hasError = true);
          }
        },
        onDone: () {
          if (mounted && !_disposed) {
            setState(() => _hasError = true);
          }
        },
        cancelOnError: true,
      );
    } catch (_) {
      if (mounted && !_disposed) {
        setState(() => _hasError = true);
      }
    }
  }

  int? _findMarker(List<int> data, int start, int b1, int b2) {
    final limit = data.length - 1;
    for (int i = start; i < limit; i++) {
      if (data[i] == b1 && data[i + 1] == b2) {
        return i;
      }
    }
    return null;
  }

  void _disconnect() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    _client?.close(force: true);
    _client = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentFrame != null) {
      return Image.memory(
        _currentFrame!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        width: double.infinity,
        height: double.infinity,
      );
    }

    if (_hasError && widget.streamUrl.trim().isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          widget.fallback,
          Positioned(
            right: AppSpacing.sm + 4,
            bottom: AppSpacing.xxl,
            child: InkWell(
              onTap: () {
                _disconnect();
                setState(() => _hasError = false);
                _connect();
              },
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: GlassContainer(
                radius: AppRadius.pill,
                blur: GlassTokens.blurSm,
                fill: AppColors.auroraCanvasTop.withValues(alpha: 0.72),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + 4,
                  vertical: AppSpacing.xs + 2,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      color: AppColors.auroraAccent,
                      size: 14,
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Text(
                      'Kết nối MJPEG',
                      style: TextStyle(
                        color: AppColors.onDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return widget.fallback;
  }
}
