import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/feedback_config.dart';
import '../data/models/feedback_request.dart';

class FeedbackService {
  Future<void> submit(FeedbackRequest request) async {
    final uri = Uri.parse(kFeedbackEndpoint);
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json; charset=utf-8'},
          body: jsonEncode(request.toTextFields()),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FeedbackSubmitException(
        'Webhook returned ${response.statusCode}',
      );
    }
  }
}

class FeedbackSubmitException implements Exception {
  final String message;
  const FeedbackSubmitException(this.message);
  @override
  String toString() => 'FeedbackSubmitException: $message';
}
