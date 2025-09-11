import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repoisitory/secure_storage.dart';
import '../../services/club_service.dart';

final clubServiceProvider = Provider<ClubService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ClubService(storage);
});
