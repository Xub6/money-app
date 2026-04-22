import 'package:flutter/material.dart';
import 'app_exceptions.dart';
import 'logger.dart';

/// Handles errors and provides user-friendly messages
class ErrorHandler {
  /// Convert exception to user-friendly message
  static String getUserMessage(dynamic exception) {
    if (exception is AppException) {
      return exception.message;
    }

    if (exception is Exception) {
      final msg = exception.toString();
      if (msg.contains('permission')) {
        return '沒有權限執行此操作';
      }
      if (msg.contains('network') || msg.contains('socket')) {
        return '網絡連接失敗，請檢查網絡';
      }
      if (msg.contains('database')) {
        return '數據庫錯誤，請稍後重試';
      }
      return '發生錯誤，請稍後重試';
    }

    return '未知錯誤';
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
    final message = getUserMessage(exception);
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

  /// Show undo snackbar with X close button and 5-second auto-dismiss
  static void showUndoSnack(
    BuildContext context,
    String message,
    VoidCallback onUndo,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        content: Row(
          children: [
            Expanded(child: Text(message)),
            GestureDetector(
              onTap: () => messenger.hideCurrentSnackBar(),
              child: const Icon(Icons.close, color: Colors.white70, size: 18),
            ),
          ],
        ),
        action: SnackBarAction(
          label: '復原',
          textColor: Colors.amber,
          onPressed: onUndo,
        ),
      ),
    );
  }
}
