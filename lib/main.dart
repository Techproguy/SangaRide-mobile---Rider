import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanga_ride/core/constants.dart';
import 'package:sanga_ride/core/router/router.dart';
import 'package:sanga_ride/initialize.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await initializeSanga();
  runApp(const SangaRide());
}

class SangaRide extends StatelessWidget {
  const SangaRide({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: SangaConstants.appName,
      routerConfig: SangaRouter.router,
      theme: SangaTheme.light,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => SangaFrame(config: SangaConstants.frame, child: child!),
    );
  }
}
