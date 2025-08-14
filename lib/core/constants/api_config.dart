import 'package:flutter/foundation.dart';

/// API 설정 상수
class ApiConfig {
  /// API 기본 URL - 환경별 설정
  static String get baseUrl {
    if (kDebugMode) {
      // 개발 환경: 현재 컴퓨터 IP 사용
      return 'http://10.221.251.53:3000';
    } else {
      // 프로덕션 환경: 실제 서버 URL 사용
      return 'https://your-production-server.com';
    }
  }

  /// API 타임아웃 (초)
  static const int timeoutSeconds = 30;

  /// 작업자 등록 엔드포인트
  static const String workerLoginEndpoint = '/{work_type}/{worker_id}/login';
  
  /// 개발용 로컬 IP 주소 (참고용)
  static const String _localIP = '10.221.251.53';
  
  /// 현재 사용 중인 API URL 출력 (디버깅용)
  static void printCurrentApiUrl() {
    if (kDebugMode) {
      print('[API Config] 현재 API URL: $baseUrl');
      print('[API Config] 환경: ${kDebugMode ? "개발" : "프로덕션"}');
    }
  }
}
