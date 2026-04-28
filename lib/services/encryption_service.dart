import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/utils/logger.dart';
import '../core/utils/app_exceptions.dart';

/// AES-256 encryption service backed by Android Keystore via FlutterSecureStorage.
///
/// Call [init] once before any [encrypt]/[decrypt] usage (e.g. during AppState._load).
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();

  enc.Key? _key;
  enc.IV? _iv;
  bool _initialized = false;
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  factory EncryptionService() => _instance;
  EncryptionService._internal();

  bool get isInitialized => _initialized;

  /// Must be awaited once before using [encrypt] / [decrypt].
  Future<void> init() async {
    if (_initialized) return;
    try {
      String? keyB64 = await _storage.read(key: 'enc_key_v1');
      String? ivB64 = await _storage.read(key: 'enc_iv_v1');

      if (keyB64 == null || ivB64 == null) {
        _key = enc.Key.fromSecureRandom(32);
        _iv = enc.IV.fromSecureRandom(16);
        await _storage.write(key: 'enc_key_v1', value: _key!.base64);
        await _storage.write(key: 'enc_iv_v1', value: _iv!.base64);
        AppLogger.info('✓ Encryption keys generated');
      } else {
        _key = enc.Key.fromBase64(keyB64);
        _iv = enc.IV.fromBase64(ivB64);
        AppLogger.info('✓ Encryption keys loaded');
      }
      _initialized = true;
    } catch (e) {
      AppLogger.error('✗ EncryptionService init failed', error: e);
      // Service degrades gracefully: encrypt/decrypt return passthrough
    }
  }

  /// Encrypt [plaintext] with AES-CBC. Returns base64 ciphertext.
  /// If not initialized, returns [plaintext] unchanged (graceful degradation).
  String encrypt(String plaintext) {
    if (!_initialized || plaintext.isEmpty) return plaintext;
    try {
      final encrypter = enc.Encrypter(enc.AES(_key!));
      return encrypter.encrypt(plaintext, iv: _iv!).base64;
    } catch (e) {
      AppLogger.error('Encryption failed', error: e);
      throw DataException(message: '數據加密失敗', originalException: e);
    }
  }

  /// Decrypt base64 [ciphertext]. Returns plaintext.
  /// If not initialized or decryption fails, returns [ciphertext] unchanged.
  String decrypt(String ciphertext) {
    if (!_initialized || ciphertext.isEmpty) return ciphertext;
    try {
      final encrypter = enc.Encrypter(enc.AES(_key!));
      return encrypter.decrypt(enc.Encrypted.fromBase64(ciphertext), iv: _iv!);
    } catch (e) {
      AppLogger.error('Decryption failed', error: e);
      return ciphertext;
    }
  }

  /// Encrypt a JSON-serialisable [map] to a base64 string.
  String encryptMap(Map<String, dynamic> map) => encrypt(jsonEncode(map));

  /// Decrypt a base64 string back to a map. Returns null on failure.
  Map<String, dynamic>? decryptMap(String ciphertext) {
    try {
      return jsonDecode(decrypt(ciphertext)) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('decryptMap failed', error: e);
      return null;
    }
  }

  /// Encrypt [value] and write to Keystore-backed secure storage.
  Future<void> storeSecure(String key, String value) async {
    try {
      await _storage.write(key: key, value: encrypt(value));
    } catch (e) {
      AppLogger.error('storeSecure failed', error: e);
      throw DataException(message: '無法存儲敏感數據', originalException: e);
    }
  }

  /// Read and decrypt from secure storage. Returns null if key missing.
  Future<String?> retrieveSecure(String key) async {
    try {
      final val = await _storage.read(key: key);
      return val == null ? null : decrypt(val);
    } catch (e) {
      AppLogger.error('retrieveSecure failed', error: e);
      return null;
    }
  }

  /// Delete a key from secure storage.
  Future<void> deleteSecure(String key) =>
      _storage.delete(key: key).catchError((e) {
        AppLogger.error('deleteSecure failed', error: e);
      });

  /// Clear all secure storage (use with caution — also removes enc keys).
  Future<void> clearSecure() =>
      _storage.deleteAll().catchError((e) {
        AppLogger.error('clearSecure failed', error: e);
      });

  /// One-way SHA-256 hash.
  static String hash(String data) =>
      sha256.convert(utf8.encode(data)).toString();

  static bool verifyHash(String data, String expectedHash) =>
      hash(data) == expectedHash;
}
