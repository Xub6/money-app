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
}
