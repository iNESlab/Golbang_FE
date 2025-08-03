import 'package:go_router/go_router.dart';
import '../../pages/home/home_page.dart';

final List<GoRoute> homeRoutes = [
  GoRoute(
    path: '/home',
    builder: (context, state)  {
      final extra = state.extra;
      final initialIndex = extra is Map<String, dynamic> ? extra['initialIndex'] ?? 0 : 0;

      return HomePage(initialIndex: initialIndex);
    },
  ),
];
