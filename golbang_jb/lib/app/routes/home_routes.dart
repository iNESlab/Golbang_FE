import 'package:go_router/go_router.dart';
import '../../pages/home/home_page.dart';

final List<GoRoute> homeRoutes = [
  GoRoute(
    path: '/home',
    builder: (context, state)  {
      return const HomePage();
    },
  ),
];
