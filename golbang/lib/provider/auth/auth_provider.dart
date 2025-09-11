import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repoisitory/secure_storage.dart';
import '../../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return AuthService(storage);
});
