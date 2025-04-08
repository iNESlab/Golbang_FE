import 'dart:developer';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_storage.g.dart';

@Riverpod(keepAlive: true)
FlutterSecureStorage storage(StorageRef ref) {
  return const FlutterSecureStorage();
}

@Riverpod(keepAlive: true)
SecureStorage secureStorage(SecureStorageRef ref) {
  final FlutterSecureStorage storage = ref.read(storageProvider);
  return SecureStorage(storage: storage);
}

class SecureStorage {
  final FlutterSecureStorage storage;
  SecureStorage({
    required this.storage,
  });

  //  리프레시 토큰 저장
  // Future<void> saveRefreshToken(String refreshToken) async {
  //   try {
  //     print('[SECURE_STORAGE] saveRefreshToken: $refreshToken');
  //     await storage.write(key: REFRESH_TOKEN, value: refreshToken);
  //   } catch (e) {
  //     print("[ERR] RefreshToken 저장 실패: $e");
  //   }
  // }

  // 리프레시 토큰 불러오기
  // Future<String?> readRefreshToken() async {
  //   try {
  //     final refreshToken = await storage.read(key: REFRESH_TOKEN);
  //     print('[SECURE_STORAGE] readRefreshToken: $refreshToken');
  //     return refreshToken;
  //   } catch (e) {
  //     print("[ERR] RefreshToken 불러오기 실패: $e");
  //     return null;
  //   }
  // }

  // 에세스 토큰 저장
  Future<void> saveAccessToken(String accessToken) async {
    try {
      log('[SECURE_STORAGE] saveAccessToken: $accessToken');
      await storage.write(key: 'ACCESS_TOKEN', value: accessToken);
    } catch (e) {
      log("[ERR] AccessToken 저장 실패: $e");
    }
  }

  // 에세스 토큰 불러오기
  Future<String> readAccessToken() async {
    try {
      final accessToken = await storage.read(key: 'ACCESS_TOKEN');
      log('[SECURE_STORAGE] readAccessToken: $accessToken');
      //final refreshToken = await storage.read(key: REFRESH_TOKEN);
      //print('[SECURE_STORAGE] readRefreshToken: $refreshToken');

      if(accessToken == null) {
        throw StateError('Access token is not available');
      }

      return accessToken;
    } catch (e) {
      log("[ERR] AccessToken 불러오기 실패: $e");
      throw StateError('Failed to retrieve access token: $e');
    }
  }

  Future<void> saveLoginId(String loginId) async {
    try {
      log('[LOGIN] saveLoginId: $loginId');
      await storage.write(key: 'LOGIN_ID', value: loginId);
    } catch (e) {
      log("[ERR] LoginId 저장 실패: $e");
    }
  }

  Future<String> readLoginId() async {
    try {
      final loginId = await storage.read(key: 'LOGIN_ID');
      log('[LOGIN] readLoginId: $loginId');
      //final refreshToken = await storage.read(key: REFRESH_TOKEN);
      //print('[SECURE_STORAGE] readRefreshToken: $refreshToken');

      if(loginId == null) {
        throw StateError('loginId is not available');
      }

      return loginId;
    } catch (e) {
      log("[ERR] loginId 불러오기 실패: $e");
      throw StateError('Failed to retrieve loginId: $e');
    }
  }

  Future<void> savePassword(String password) async {
    try {
      log('[SECURE_STORAGE] savePassword: [HIDDEN]');
      await storage.write(key: 'PASSWORD', value: password);
    } catch (e) {
      log("[ERR] Password 저장 실패: $e");
    }
  }

  Future<String> readPassword() async {
    try {
      final password = await storage.read(key: 'PASSWORD');
      log('[SECURE_STORAGE] readPassword: [HIDDEN]');

      if (password == null) {
        throw StateError('Password is not available');
      }

      return password;
    } catch (e) {
      log("[ERR] Password 불러오기 실패: $e");
      throw StateError('Failed to retrieve password: $e');
    }
  }



}

