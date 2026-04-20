import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/utils/logger.dart';
import '../core/utils/app_exceptions.dart';

/// Service for encrypting and decrypting sensitive data
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  late final encrypt_pkg.Key _key;
  late final encrypt_pkg.IV _iv;
  final _secureStorage = const FlutterSecureStorage();

  factory EncryptionService() => _instance;

  EncryptionService._internal() {
    _initializeKeys();
  }

  /// Initialize encryption keys from secure storage
  Future<void> _initializeKeys() async {
    try {
      // Try to load existing key
      String? keyString = await _secureStorage.read(key: 'encryption_key');
      String? ivString = await _secureStorage.read(key: 'encryption_iv');

      if (keyString == null || ivString == null) {
        // Generate new keys
        _key = encrypt_pkg.Key.fromSecureRandom(32); // 256-bit key
        _iv = encrypt_pkg.IV.fromSecureRandom(16);   // 128-bit IV

        // Store keys securely
        await _secureStorage.write(
          key: 'encryption_key',
          value: _key.base64,
        );
        await _secureStorage.write(
          key: 'encryption_iv',
          value: _iv.base64,
        );

        AppLogger.info('Encryption keys generated and stored');
      } else {
        // Load existing keys
        _key = encrypt_pkg.Key.fromBase64(keyString);
        _iv = encrypt_pkg.IV.fromBase64(ivString);
        AppLogger.info('Encryption keys loaded from secure storage');
      }
    } catch (e) {
      AppLogger.error('Failed to initialize encryption keys', error: e);
      rethrow;
    }
  }

  /// Encrypt a string
  String encrypt(String plaintext) {
    try {
      if (plaintext.isEmpty) return '';

      final encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(_key));
      final encrypted = encrypter.encrypt(plaintext, iv: _iv);

      AppLogger.debug('Data encrypted successfully');
      return encrypted.base64;
    } catch (e) {
      AppLogger.error('Encryption failed', error: e);
      throw DataException(
        message: '數據加密失敗',
        originalException: e,
      );
    }
  }

  /// Decrypt a string
  String decrypt(String encryptedBase64) {
    try {
      if (encryptedBase64.isEmpty) return '';

      final encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(_key));
      final encrypted = encrypt_pkg.Encrypted.fromBase64(encryptedBase64);
      final decrypted = encrypter.decrypt(encrypted, iv: _iv);

      AppLogger.debug('Data decrypted successfully');
      return decrypted;
    } catch (e) {
      AppLogger.error('Decryption failed', error: e);
      throw DataException(
        message: '數據解密失敗',
        originalException: e,
      );
    }
  }

  /// Encrypt an integer (useful for amounts)
  String encryptInt(int value) {
    return encrypt(value.toString());
  }

  /// Decrypt an integer
  int decryptInt(String encryptedBase64) {
    try {
      final decrypted = decrypt(encryptedBase64);
      return int.parse(decrypted);
    } catch (e) {
      AppLogger.error('Failed to decrypt integer', error: e);
      return 0;
    }
  }

  /// Encrypt a map to JSON string
  String encryptMap(Map<String, dynamic> data) {
    try {
      final json = jsonEncode(data);
      return encrypt(json);
    } catch (e) {
      AppLogger.error('Failed to encrypt map', error: e);
      rethrow;
    }
  }

  /// Decrypt JSON string to map
  Map<String, dynamic>? decryptMap(String encryptedBase64) {
    try {
      final decrypted = decrypt(encryptedBase64);
      return jsonDecode(decrypted) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Failed to decrypt map', error: e);
      return null;
    }
  }

  /// Store encrypted value in secure storage
  Future<void> storeSecure(String key, String value) async {
    try {
      final encrypted = encrypt(value);
      await _secureStorage.write(key: key, value: encrypted);
      AppLogger.debug('Secure storage write: $key');
    } catch (e) {
      AppLogger.error('Failed to store secure value', error: e);
      throw DataException(
        message: '無法存儲敏感數據',
        originalException: e,
      );
    }
  }

  /// Retrieve encrypted value from secure storage
  Future<String?> retrieveSecure(String key) async {
    try {
      final encrypted = await _secureStorage.read(key: key);
      if (encrypted == null) return null;

      final decrypted = decrypt(encrypted);
      AppLogger.debug('Secure storage read: $key');
      return decrypted;
    } catch (e) {
      AppLogger.error('Failed to retrieve secure value', error: e);
      return null;
    }
  }

  /// Delete secure value
  Future<void> deleteSecure(String key) async {
    try {
      await _secureStorage.delete(key: key);
      AppLogger.debug('Secure storage delete: $key');
    } catch (e) {
      AppLogger.error('Failed to delete secure value', error: e);
    }
  }

  /// Clear all secure storage
  Future<void> clearSecure() async {
    try {
      await _secureStorage.deleteAll();
      AppLogger.info('Secure storage cleared');
    } catch (e) {
      AppLogger.error('Failed to clear secure storage', error: e);
    }
  }

  /// Hash a string (one-way, for verification)
  static String hash(String data) {
    return sha256.convert(utf8.encode(data)).toString();
  }

  /// Verify a hash
  static bool verifyHash(String data, String hash) {
    return EncryptionService.hash(data) == hash;
  }
}
