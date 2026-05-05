import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../config/localization.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/feedback_request.dart';
import '../../services/feedback_service.dart';
import '../../widgets/feedback/feedback_image_picker.dart';

const _kCategoryKeys = [
  'feedback_cat_usage',
  'feedback_cat_feature',
  'feedback_cat_data',
  'feedback_cat_invest',
  'feedback_cat_backup',
  'feedback_cat_other',
];

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  final _messageCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _service = FeedbackService();

  String? _category;
  List<File> _images = [];
  bool _submitting = false;

  // Collected in initState — non-critical; empty strings are fine if loading fails
  String _appVersion = '';
  String _platform = '';
  String _osVersion = '';
  String _deviceModel = '';

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceInfo() async {
    try {
      final pkg = await PackageInfo.fromPlatform();
      final version = '${pkg.version}+${pkg.buildNumber}';

      final devicePlugin = DeviceInfoPlugin();
      String platform, osVersion, deviceModel;

      if (Platform.isAndroid) {
        final a = await devicePlugin.androidInfo;
        platform = 'Android';
        osVersion = 'Android ${a.version.release} (API ${a.version.sdkInt})';
        deviceModel = '${a.manufacturer} ${a.model}'.trim();
      } else if (Platform.isIOS) {
        final i = await devicePlugin.iosInfo;
        platform = 'iOS';
        osVersion = 'iOS ${i.systemVersion}';
        deviceModel = i.model;
      } else {
        platform = Platform.operatingSystem;
        osVersion = Platform.operatingSystemVersion;
        deviceModel = 'Unknown';
      }

      if (mounted) {
        setState(() {
          _appVersion = version;
          _platform = platform;
          _osVersion = osVersion;
          _deviceModel = deviceModel;
        });
      }
    } catch (_) {
      // Device info is best-effort; submission proceeds with empty strings
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Capture context-dependent objects before any async gap
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (_images.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppLocalizations.of(ctx, 'confirm_image')),
          content: Text(AppLocalizations.of(ctx, 'confirm_image_content')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppLocalizations.of(ctx, 'cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                AppLocalizations.of(ctx, 'confirm_submit'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() => _submitting = true);

    try {
      final createdAt =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      final request = FeedbackRequest(
        appName: '錢錢管家',
        appVersion: _appVersion,
        category: _category!,
        message: _messageCtrl.text.trim(),
        contactEmail: _emailCtrl.text.trim(),
        platform: _platform,
        osVersion: _osVersion,
        deviceModel: _deviceModel,
        sourcePage: 'ManagePage',
        createdAt: createdAt,
        images: List.unmodifiable(_images),
      );
      await _service.submit(request);
      messenger.showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context, 'feedback_sent')),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
      navigator.pop();
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context, 'feedback_failed')),
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context, 'report_issue'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context, 'feedback_intro'),
                style: TextStyle(
                    fontSize: 14, color: cs.onSurfaceVariant, height: 1.5),
              ),
              const SizedBox(height: 20),

              // ── 回饋類型 ──
              _Label(AppLocalizations.of(context, 'feedback_type'), required: true),
              const SizedBox(height: 6),
              _Card(
                child: DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  hint: Text(AppLocalizations.of(context, 'select_feedback_type')),
                  items: _kCategoryKeys
                      .map((k) => DropdownMenuItem(value: k, child: Text(AppLocalizations.of(context, k))))
                      .toList(),
                  onChanged:
                      _submitting ? null : (v) => setState(() => _category = v),
                  validator: (v) => v == null ? AppLocalizations.of(context, 'select_feedback_type') : null,
                ),
              ),
              const SizedBox(height: 16),

              // ── 問題描述 ──
              _Label(AppLocalizations.of(context, 'issue_description'), required: true),
              const SizedBox(height: 6),
              _Card(
                child: TextFormField(
                  controller: _messageCtrl,
                  enabled: !_submitting,
                  minLines: 4,
                  maxLines: 10,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: AppLocalizations.of(context, 'issue_description_hint'),
                    hintMaxLines: 3,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return AppLocalizations.of(context, 'please_fill_issue');
                    if (v.trim().length < 10) return AppLocalizations.of(context, 'please_enter_min_10');
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),

              // ── 聯絡 Email ──
              _Label(AppLocalizations.of(context, 'contact_email'), required: false),
              const SizedBox(height: 6),
              _Card(
                child: TextFormField(
                  controller: _emailCtrl,
                  enabled: !_submitting,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: AppLocalizations.of(context, 'contact_email_hint'),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final re = RegExp(
                        r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
                    if (!re.hasMatch(v.trim())) return AppLocalizations.of(context, 'invalid_email');
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),

              // ── 附加圖片 ──
              _Label(AppLocalizations.of(context, 'attach_images'), required: false),
              const SizedBox(height: 6),
              _Card(
                child: AbsorbPointer(
                  absorbing: _submitting,
                  child: FeedbackImagePicker(
                    images: _images,
                    onAdd: (f) => setState(() => _images = [..._images, f]),
                    onRemove: (i) => setState(() {
                      final list = List<File>.from(_images)..removeAt(i);
                      _images = list;
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── 送出按鈕 ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.gold.withAlpha(120),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          AppLocalizations.of(context, 'submit'),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // ── 法務提示 ──
              Text(
                AppLocalizations.of(context, 'feedback_legal_note'),
                style: TextStyle(
                    fontSize: 11, color: cs.onSurfaceVariant, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final bool required;
  const _Label(this.text, {required this.required});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(text,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          if (required)
            Text(' *',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
        ],
      );
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: child,
        ),
      );
}
