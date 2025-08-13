import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/api_config.dart';

void main() {
  // API 설정 디버그 정보 출력
  ApiConfig.printCurrentApiUrl();
  
  runApp(RescuePangApp());
}

class RescuePangApp extends StatelessWidget {
  RescuePangApp({super.key});

  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RescuePang',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _appRouter.config(),
    );
  }
}
