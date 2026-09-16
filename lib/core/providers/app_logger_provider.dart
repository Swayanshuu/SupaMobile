import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AppLogEntry {
  final DateTime timestamp;
  final String message;
  final String level;
  
  AppLogEntry({
    required this.timestamp,
    required this.message,
    this.level = 'info',
  });

  String get formattedTime => DateFormat('HH:mm:ss.SSS').format(timestamp);
}

class AppLoggerState {
  final List<AppLogEntry> logs;
  final bool hasUnreadError;

  AppLoggerState({
    this.logs = const [],
    this.hasUnreadError = false,
  });

  AppLoggerState copyWith({
    List<AppLogEntry>? logs,
    bool? hasUnreadError,
  }) {
    return AppLoggerState(
      logs: logs ?? this.logs,
      hasUnreadError: hasUnreadError ?? this.hasUnreadError,
    );
  }
}

class AppLoggerNotifier extends Notifier<AppLoggerState> {
  @override
  AppLoggerState build() {
    return AppLoggerState();
  }

  void log(String message) {
    _addLog(message, 'info');
  }

  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    final fullMessage = '$message\n${error != null ? error.toString() : ''}';
    _addLog(fullMessage, 'error');
  }

  void warning(String message) {
    _addLog(message, 'warning');
  }

  void _addLog(String message, String level) {
    final entry = AppLogEntry(
      timestamp: DateTime.now(),
      message: message,
      level: level,
    );
    
    final currentLogs = List<AppLogEntry>.from(state.logs);
    if (currentLogs.length >= 500) {
      currentLogs.removeAt(0);
    }
    currentLogs.add(entry);

    state = state.copyWith(
      logs: currentLogs,
      hasUnreadError: level == 'error' ? true : state.hasUnreadError,
    );
  }

  void markAsRead() {
    state = state.copyWith(hasUnreadError: false);
  }
  
  void clear() {
    state = AppLoggerState();
  }
}

final appLoggerProvider = NotifierProvider<AppLoggerNotifier, AppLoggerState>(() {
  return AppLoggerNotifier();
});
