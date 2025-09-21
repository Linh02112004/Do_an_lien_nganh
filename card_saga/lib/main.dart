import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/lang_provider.dart';
import 'services/game_service.dart';
import 'screens/map_screen.dart';
import 'utils/constants.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LangProvider()),
        ChangeNotifierProvider(create: (_) => GameService()),
      ],
      child: const CardSagaApp(),
    ),
  );
}

class CardSagaApp extends StatelessWidget {
  const CardSagaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LangProvider>().locale;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Card Saga',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: AppColors.bg,
      ),
      home: const MapScreen(),
      locale: lang,
    );
  }
}
