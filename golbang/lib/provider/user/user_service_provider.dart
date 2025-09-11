import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repoisitory/secure_storage.dart';
import '../../services/user_service.dart';

// UserService를 제공하는 프로바이더
final userServiceProvider = Provider<UserService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return UserService(storage);
});
