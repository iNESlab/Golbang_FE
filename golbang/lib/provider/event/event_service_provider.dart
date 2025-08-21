import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repoisitory/secure_storage.dart';
import '../../services/event_service.dart';


// EventService를 제공하는 provider
final eventServiceProvider = Provider<EventService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return EventService(storage);
});
