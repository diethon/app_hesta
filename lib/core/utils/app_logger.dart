import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../app/config/providers.dart';

final appLoggerProvider = Provider<Logger>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  return Logger(
    level: environment.enableVerboseLogs ? Level.debug : Level.warning,
    printer: PrettyPrinter(methodCount: 0),
    filter: _EnvironmentLogFilter(environment.enableVerboseLogs),
  );
});

class _EnvironmentLogFilter extends LogFilter {
  _EnvironmentLogFilter(this.verbose);

  final bool verbose;

  @override
  bool shouldLog(LogEvent event) {
    if (verbose) {
      return true;
    }
    return event.level.index >= Level.warning.index;
  }
}
