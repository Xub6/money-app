import 'package:flutter/foundation.dart';

/// Log levels
enum LogLevel { verbose, debug, info, warning, error, wtf }

/// Simple logger for the app
class AppLogger {
  static final _buffer = <String>[];
  static const int _maxLogSize = 1000; // Keep last 1000 logs

  static void _addLog(String level, String message, {dynamic error, StackTrace? stackTrace}) {
    final timestamp = DateTime.now().toString();
    final logMessage = '[$timestamp][$level] $message';

    if (kDebugMode) {
      // ignore: avoid_print
      print(logMessage);
    }

    _buffer.add(logMessage);
    if (error != null) {
      _buffer.add('  Error: $error');
    }
    if (stackTrace != null) {
      _buffer.add('  StackTrace: $stackTrace');
    }

    // Keep buffer size manageable
    if (_buffer.length > _maxLogSize) {
      _buffer.removeRange(0, _buffer.length - _maxLogSize);
    }
  }

  static void verbose(String message, {dynamic error, StackTrace? stackTrace}) {
    _addLog('V', message, error: error, stackTrace: stackTrace);
  }

  static void debug(String message, {dynamic error, StackTrace? stackTrace}) {
    _addLog('D', message, error: error, stackTrace: stackTrace);
  }

  static void info(String message, {dynamic error, StackTrace? stackTrace}) {
    _addLog('I', message, error: error, stackTrace: stackTrace);
  }

  static void warning(String message, {dynamic error, StackTrace? stackTrace}) {
    _addLog('W', message, error: error, stackTrace: stackTrace);
  }

  static void error(String message, {dynamic error, StackTrace? stackTrace}) {
    _addLog('E', message, error: error, stackTrace: stackTrace);
  }

  static void wtf(String message, {dynamic error, StackTrace? stackTrace}) {
    _addLog('WTF', message, error: error, stackTrace: stackTrace);
  }

  /// Get all logs as string
  static String getLogs() => _buffer.join('\n');

  /// Get recent N logs
  static String getRecentLogs({int count = 50}) {
    final start = (_buffer.length - count).clamp(0, _buffer.length);
    return _buffer.sublist(start).join('\n');
  }

  /// Clear logs
  static void clearLogs() {
    _buffer.clear();
  }

  /// Export logs to string (for file export)
  static String exportLogs() {
    final buffer = StringBuffer();
    buffer.writeln('=== Money App Logs ===');
    buffer.writeln('Exported at: ${DateTime.now()}');
    buffer.writeln('');
    buffer.writeAll(_buffer, '\n');
    return buffer.toString();
  }
}
