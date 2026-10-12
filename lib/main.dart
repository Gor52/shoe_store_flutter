import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_web_plugins/url_strategy.dart'; 

import 'repositories/shoe_repository.dart';
import 'state/shoe_list_notifier.dart';
import 'state/auth_notifier.dart';
import 'state/cart_notifier.dart';
import 'core/router.dart';

void main() {
  usePathUrlStrategy();

  runApp(
    MultiProvider(
      providers: [
        Provider<ShoeRepository>(
          create: (_) => ShoeRepository(),
        ),
        ChangeNotifierProvider<AuthNotifier>(
          create: (_) => AuthNotifier(),
        ),
        ChangeNotifierProvider<ShoeListNotifier>(
          create: (context) => ShoeListNotifier(
            context.read<ShoeRepository>(),
          )..load(), 
        ),
        ChangeNotifierProvider(create: (_) => CartNotifier()),
      ],
      child: const ShoeStoreApp(),
    ),
  );
}

class ShoeStoreApp extends StatelessWidget {
  const ShoeStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Shoe Store',
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}