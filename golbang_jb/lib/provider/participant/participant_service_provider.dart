import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repoisitory/secure_storage.dart';
import '../../services/participant_service.dart';


// ParticipantService를 제공하는 provider
final participantServiceProvider = Provider<ParticipantService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ParticipantService(storage);
});
