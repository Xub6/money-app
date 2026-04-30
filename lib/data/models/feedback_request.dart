import 'dart:io';

class FeedbackRequest {
  final String appName;
  final String appVersion;
  final String category;
  final String message;
  final String contactEmail;
  final String platform;
  final String osVersion;
  final String deviceModel;
  final String sourcePage;
  final String createdAt;
  final List<File> images;

  const FeedbackRequest({
    required this.appName,
    required this.appVersion,
    required this.category,
    required this.message,
    required this.contactEmail,
    required this.platform,
    required this.osVersion,
    required this.deviceModel,
    required this.sourcePage,
    required this.createdAt,
    required this.images,
  });

  Map<String, String> toTextFields() => {
        'appName': appName,
        'appVersion': appVersion,
        'category': category,
        'message': message,
        'contactEmail': contactEmail,
        'platform': platform,
        'osVersion': osVersion,
        'deviceModel': deviceModel,
        'sourcePage': sourcePage,
        'hasImages': images.isNotEmpty ? 'true' : 'false',
        'createdAt': createdAt,
      };
}
