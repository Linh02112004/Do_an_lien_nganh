import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/lang_provider.dart';
import '../services/game_service.dart';
import '../utils/constants.dart';
import '../widgets/top_status_bar.dart';
import 'map_screen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  double _loadingProgress = 0.0;
  bool _isLoadingComplete = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startLoading();
    });
  }

  void _startLoading() {
    final gameService = context.read<GameService>();

    if (!gameService.isLoading) {
      setState(() {
        _loadingProgress = 1.0;
        _isLoadingComplete = true;
      });
      return;
    }

    _timer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (gameService.isLoading) {
        setState(() {
          _loadingProgress = (_loadingProgress + 0.01).clamp(0.0, 0.95);
        });
      } else {
        setState(() {
          _loadingProgress = 1.0;
          _isLoadingComplete = true;
        });
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _navigateToMapScreen() async {
    final gameService = context.read<GameService>();

    // ✅ BẮT ĐẦU BGM khi user tap nút PLAY
    debugPrint(">>> [IntroScreen] User tapped PLAY button");
    await gameService.playTapSound();

    // ✅ Trigger BGM start (sau user interaction)
    await gameService.ensureBgmStarted();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MapScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LangProvider>();
    final t = lang.locale.languageCode == 'en' ? Strings.en : Strings.vi;

    final introDesc1 = t['intro_desc_1'] ??
        'Chào mừng đến với Card Saga – thế giới của những thẻ bài kỳ diệu và mảnh ghép đầy sắc màu!';
    final introDesc2 = t['intro_desc_2'] ??
        'Hãy sẵn sàng cho hành trình khám phá, rèn luyện trí nhớ và hoàn thành những bức tranh đáng yêu nhé!';

    final loadingText = t['loading'] ?? 'Loading...';
    final playButtonText = t['play'] ?? 'PLAY!';

    return Scaffold(
      appBar: TopStatusBar(
        title: '',
        showShopButton: false,
        showGalleryButton: false,
        showCoinsAndStars: false,
        showBack: false,
        showSettings: true,
      ),
      backgroundColor: AppColors.bg,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            // Logo chiếm 50% không gian
            Flexible(
              flex: 4,
              child: Center(
                child: FractionallySizedBox(
                  widthFactor: 0.8,
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // Nội dung text chiếm 40% không gian
            Flexible(
              flex: 4,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      introDesc1,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.pink.shade800,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      introDesc2,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.pink.shade800,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Thanh progress bar và button chiếm 10% không gian
            Flexible(
              flex: 2,
              child: Center(
                child: _isLoadingComplete
                    ? AnimatedScale(
                        scale: 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pinkAccent,
                            padding: const EdgeInsets.symmetric(
                                vertical: 18, horizontal: 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 8,
                            shadowColor: Colors.pink.withOpacity(0.5),
                          ),
                          onPressed: _navigateToMapScreen,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                playButtonText,
                                style: const TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '$loadingText ${(_loadingProgress * 100).toStringAsFixed(0)}%',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.pinkAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.6,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: _loadingProgress,
                                minHeight: 16,
                                backgroundColor:
                                    Colors.pink.shade100.withOpacity(0.5),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    Colors.pinkAccent),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
