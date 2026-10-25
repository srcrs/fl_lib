import 'dart:async';
import 'dart:convert';

import 'package:fl_lib/fl_lib.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RateLimitExceededException implements Exception {
  final String message;
  final int remaining;

  RateLimitExceededException(this.message, {required this.remaining});

  @override
  String toString() => message;
}

class _SlidingWindowRateLimiter {
  final int maxRequests;
  final Duration windowSize;
  final List<int> _timestamps = [];

  _SlidingWindowRateLimiter({
    required this.maxRequests,
    required this.windowSize,
  });

  bool allowRequest() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final windowStart = now - windowSize.inMilliseconds;

    _timestamps.removeWhere((ts) => ts < windowStart);

    if (_timestamps.length >= maxRequests) {
      return false;
    }

    _timestamps.add(now);
    return true;
  }

  int get remainingRequests => maxRequests - _timestamps.length;
}

final class _RateLimiter {
  static final _readLimiter = _SlidingWindowRateLimiter(
    maxRequests: 60,
    windowSize: const Duration(seconds: 30),
  );

  static final _writeLimiter = _SlidingWindowRateLimiter(
    maxRequests: 10,
    windowSize: const Duration(seconds: 30),
  );

  static bool canRead() => _readLimiter.allowRequest();
  static bool canWrite() => _writeLimiter.allowRequest();
  static int readRemaining() => _readLimiter.remainingRequests;
  static int writeRemaining() => _writeLimiter.remainingRequests;
}

/// Secure Store Properties
abstract final class SecureStoreProps {
  /// Password for the backup.
  static const bakPwd = SecureProp('bakPwd');

  /// Password of [HiveStore].
  static const hivePwd = SecureProp('hivePwd');

  /// Password used to authenticate to WebDAV.
  static const webdavPwd = SecureProp('webdavPwd');

  /// GitHub token used for Gist access.
  static const githubToken = SecureProp('githubToken');

  /// Moves secrets written by older builds out of SharedPreferences.
  static Future<void> migrateLegacyPrefs() async {
    // A local macOS build keeps its database key in a file and does not touch
    // the keychain until a feature actually needs a saved secret. Migrating
    // WebDAV and Gist credentials here would open the system keychain panel
    // before the first frame, which is exactly the invisible launch this mode
    // exists to avoid.
    if (SecureStore.usesLocalMacKeyFile) return;
    try {
      // ignore: deprecated_member_use_from_same_package
      await _migrateLegacyPref(PrefProps.webdavPwd, webdavPwd);
    } catch (e) {
      dprint('Failed to migrate WebDAV password: $e');
    }
    try {
      // ignore: deprecated_member_use_from_same_package
      await _migrateLegacyPref(PrefProps.githubToken, githubToken);
    } catch (e) {
      dprint('Failed to migrate GitHub token: $e');
    }
  }

  static Future<void> _migrateLegacyPref(
    PrefProp<String> legacy,
    SecureProp secure,
  ) async {
    final secured = await secure.read();
    if (secured != null) {
      await legacy.remove();
      return;
    }

    final value = legacy.get();
    if (value == null) return;
    await secure.write(value);
    if (await secure.read() != value) {
      throw StateError('Failed to verify migrated secret ${legacy.key}');
    }
    await legacy.remove();
  }
}

/// The secure store.
///
/// It uses system built-in vault to store the data.
abstract final class SecureStore {
  /// The name of default user account. Such as 'debug.user1' or 'release.user1'.
  ///
  /// - Only available on iOS and macOS.
  /// - Not [IOSOptions.groupId].
  static const defaultAccountName = 'fllib_secure_store';

  /// A local, ad-hoc signed macOS build cannot use the data protection
  /// keychain: it has no application identifier for macOS to authorise, and
  /// every write fails with `errSecMissingEntitlement` (-34018). The legacy
  /// login keychain does not need that entitlement. Only the local install
  /// recipe sets this define; a signed DMG or App Store build keeps the data
  /// protection keychain.
  static const _useLegacyMacKeychain = bool.fromEnvironment(
    'CODEHARBOR_LEGACY_MAC_KEYCHAIN',
  );

  /// Whether this build keeps the database key in the app's data folder.
  ///
  /// Set only by `scripts/macos/build-local.sh`. It keeps an ad-hoc build from
  /// asking for the same keychain item after every re-sign.
  static const usesLocalMacKeyFile = bool.fromEnvironment(
    'CODEHARBOR_LOCAL_MAC_KEY_FILE',
  );

  /// The secure storage instance.
  ///
  /// With [defaultAccountName], [KeychainAccessibility.first_unlock_this_device],
  static const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      accountName: defaultAccountName,
      synchronizable: false,
      groupId: null,
    ),
    mOptions: MacOsOptions(
      accountName: defaultAccountName,
      synchronizable: false,
      accessibility: KeychainAccessibility.first_unlock_this_device,
      groupId: null,
      usesDataProtectionKeychain: !_useLegacyMacKeychain,
    ),
  );

  static Future<T?> readJson<T>(String key, JsonFromJson<T> fromJson) {
    return storage.readJson<T>(key, fromJson);
  }

  static Future<bool> writeJson<T>(String key, T value, JsonToJson<T> toJson) {
    return storage.writeJson<T>(key, value, toJson);
  }
}

/// Includes [readJson] and [writeJson].
extension SecureStoreExt on FlutterSecureStorage {
  /// Read a JSON object from secure storage.
  Future<T?> readJson<T>(String key, JsonFromJson<T> fromJson) async {
    try {
      final jsonStr = await read(key: key);
      if (jsonStr == null) return null;
      final obj = fromJson(json.decode(jsonStr));
      return obj;
    } catch (e) {
      dprint('Error reading JSON from secure storage: $e');
      return null;
    }
  }

  /// Write a JSON object to secure storage.
  Future<bool> writeJson<T>(String key, T value, JsonToJson<T> toJson) async {
    try {
      final jsonStr = json.encode(toJson(value));
      await write(key: key, value: jsonStr);
      return true;
    } catch (e) {
      dprint('Error writing JSON to secure storage: $e');
    }
    return false;
  }

  Future<int?> readInt(String key) async {
    final value = await read(key: key);
    if (value == null) return null;
    return int.tryParse(value);
  }

  Future<void> writeInt(String key, int? value) {
    if (value == null) {
      return write(key: key, value: null);
    }
    return write(key: key, value: value.toString());
  }

  Future<bool?> readBool(String key) async {
    final value = await read(key: key);
    if (value == null) return null;
    return value == '1';
  }

  Future<void> writeBool(String key, bool? value) {
    if (value == null) {
      return write(key: key, value: null);
    }
    return write(key: key, value: value ? '1' : '0');
  }
}

/// A property that stored in [FlutterSecureStorage].
final class SecureProp {
  /// The secure storage instance.
  ///
  /// Default is [SecureStore.storage].
  final FlutterSecureStorage storage;

  /// The key of the property.
  final String key;

  /// Creates a [SecureProp] with the given [key] and optional [storage].
  const SecureProp(this.key, {this.storage = SecureStore.storage});

  /// Reads the value of the property.
  /// Throws [RateLimitExceededException] if rate limit is exceeded.
  Future<String?> read() async {
    if (!_RateLimiter.canRead()) {
      dprint('SecureProp read rate limit exceeded');
      throw RateLimitExceededException(
        'Read rate limit exceeded. Try again later.',
        remaining: _RateLimiter.readRemaining(),
      );
    }
    return storage.read(key: key);
  }

  /// Writes the value of the property.
  /// Throws [RateLimitExceededException] if rate limit is exceeded.
  Future<void> write(String? value) {
    if (!_RateLimiter.canWrite()) {
      dprint('SecureProp write rate limit exceeded');
      throw RateLimitExceededException(
        'Write rate limit exceeded. Try again later.',
        remaining: _RateLimiter.writeRemaining(),
      );
    }
    return storage.write(key: key, value: value);
  }
}
