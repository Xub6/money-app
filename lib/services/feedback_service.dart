import 'package:http/http.dart' as http;
import '../config/feedback_config.dart';
import '../data/models/feedback_request.dart';

class FeedbackService {
  Future<void> submit(FeedbackRequest request) async {
    final uri = Uri.parse(kFeedbackEndpoint);
    final multipart = http.MultipartRequest('POST', uri);

    request.toTextFields().forEach((key, value) {
      multipart.fields[key] = value;
    });

    for (final file in request.images) {
      multipart.files
          .add(await http.MultipartFile.fromPath('images', file.path));
    }

    final streamed =
        await multipart.send().timeout(const Duration(seconds: 30));

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw FeedbackSubmitException(
        'Webhook returned ${streamed.statusCode}',
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
