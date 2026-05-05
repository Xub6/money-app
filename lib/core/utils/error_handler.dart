import 'package:flutter/material.dart';
import '../../config/localization.dart';
import 'app_exceptions.dart';
import 'logger.dart';

/// Handles errors and provides user-friendly messages
class ErrorHandler {
  /// Convert exception to user-friendly message (no context; may return Chinese fallback)
  static String getUserMessage(dynamic exception) {
    if (exception is String) return exception;
    if (exception is AppException) return exception.message;
    if (exception is Exception) {
      final msg = exception.toString();
      if (msg.contains('permission')) return 'error_permission';
      if (msg.contains('network') || msg.contains('socket')) return 'error_network';
      if (msg.contains('database')) return 'error_database';
      return 'error_generic';
    }
    return 'error_unknown';
  }

  /// Convert exception to localized user-friendly message
  static String getLocalizedMessage(BuildContext context, dynamic exception) {
    if (exception is String) return exception;
    if (exception is AppException) return exception.message;
    if (exception is Exception) {
      final msg = exception.toString();
      if (msg.contains('permission')) return AppLocalizations.of(context, 'error_permission');
      if (msg.contains('network') || msg.contains('socket')) return AppLocalizations.of(context, 'error_network');
      if (msg.contains('database')) return AppLocalizations.of(context, 'error_database');
      return AppLocalizations.of(context, 'error_generic');
    }
    return AppLocalizations.of(context, 'error_unknown');
  }

  /// Log exception and return AppException
  static AppException handle(
    dynamic exception, {
    String? customMessage,
    String? code,
    StackTrace? stackTrace,
  }) {
    AppLogger.error(
      customMessage ?? exception.toString(),
      error: exception,
      stackTrace: stackTrace,
    );

    if (exception is AppException) {
      return exception;
    }

    if (exception is ValidationException) {
      return exception;
    }

    return DataException(
      message: customMessage ?? getUserMessage(exception),
      code: code,
      originalException: exception,
      stackTrace: stackTrace,
    );
  }

  /// Show error snackbar
  static void showErrorSnack(BuildContext context, dynamic exception) {
    final message = getLocalizedMessage(context, exception);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show success snackbar
  static void showSuccessSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Show info snackbar
  static void showInfoSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Show undo snackbar with countdown progress bar, 復原 and X buttons
  static void showUndoSnack(
    BuildContext context,
    String message,
    VoidCallback onUndo,
  ) {
    const duration = Duration(seconds: 5);
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        content: _UndoSnackContent(
          message: message,
          duration: duration,
          onUndo: () {
            messenger.hideCurrentSnackBar();
            onUndo();
          },
          onClose: () => messenger.hideCurrentSnackBar(),
        ),
      ),
    );
  }
}

class _UndoSnackContent extends StatefulWidget {
  final String message;
  final Duration duration;
  final VoidCallback onUndo;
  final VoidCallback onClose;

  const _UndoSnackContent({
    required this.message,
    required this.duration,
    required this.onUndo,
    required this.onClose,
  });

  @override
  State<_UndoSnackContent> createState() => _UndoSnackContentState();
}

class _UndoSnackContentState extends State<_UndoSnackContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final closeColor = Theme.of(context).colorScheme.onInverseSurface;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(widget.message)),
            TextButton(
              onPressed: widget.onUndo,
              style: TextButton.styleFrom(
                foregroundColor: Colors.amber,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(AppLocalizations.of(context, 'undo'),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: widget.onClose,
              child: Icon(Icons.close, color: closeColor, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: 1.0 - _ctrl.value,
              minHeight: 3,
              backgroundColor: closeColor.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          ),
        ),
      ],
    );
  }
}
