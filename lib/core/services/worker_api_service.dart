import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_config.dart';
import '../exceptions/api_exception.dart';

class WorkerApiService {
  /// 작업자 등록 API 호출
  ///
  /// [workType] - 작업 유형 (IB 또는 OB)
  /// [workerId] - 작업자 ID (전화번호 뒷자리)
  ///
  /// Returns: 성공 시 true, 실패 시 ApiException 발생
  static Future<bool> registerWorker(String workType, String workerId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/$workType/$workerId/login');

      // 디버깅용 로그
      if (kDebugMode) {
        print('[API] 🔑 작업자 등록 요청: $url');
        print('[API] 📤 workType: $workType, workerId: $workerId');
      }

      final response = await http
          .put(url, headers: {'Content-Type': 'application/json'})
          .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      // 디버깅용 로그
      if (kDebugMode) {
        print('[API] 📥 등록 응답 상태: ${response.statusCode}');
        print('[API] 📄 등록 응답 바디: ${response.body}');
      }

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('[API] ✅ 작업자 등록 성공');
        }
        return true;
      } else {
        // 상태 코드별 구체적인 에러 메시지
        String errorMessage;
        switch (response.statusCode) {
          case 404:
            errorMessage = '등록 엔드포인트를 찾을 수 없습니다.\\n서버 상태를 확인해주세요.';
            break;
          case 400:
            errorMessage = '잘못된 작업자 정보입니다.\\n작업 유형과 ID를 확인해주세요.';
            break;
          case 500:
            errorMessage = '서버 오류가 발생했습니다.\\n잠시 후 다시 시도해주세요.';
            break;
          default:
            errorMessage = '작업자 등록에 실패했습니다.\\n(오류 코드: ${response.statusCode})';
        }
        
        throw ServerException(
          message: errorMessage,
          statusCode: response.statusCode,
          responseBody: response.body,
        );
      }
    } on TimeoutException {
      throw NetworkException(message: '요청 시간이 초과되었습니다.\\n네트워크 연결을 확인해주세요.');
    } on http.ClientException {
      throw NetworkException(message: '네트워크 연결을 확인해주세요.');
    } on SocketException {
      throw NetworkException(message: '인터넷 연결을 확인해주세요.');
    } on ServerException {
      // ServerException은 그대로 전달
      rethrow;
    } on NetworkException {
      // NetworkException은 그대로 전달
      rethrow;
    } catch (e) {
      // 디버깅용 로그
      if (kDebugMode) {
        print('[API] ❌ 작업자 등록 예상치 못한 오류: $e');
      }
      throw ApiException(message: '작업자 등록 중 예상치 못한 오류가 발생했습니다.\\n$e');
    }
  }

  /// 토트박스 스캔 API 호출
  ///
  /// [workType] - 작업 유형 (IB 또는 OB)
  /// [workerId] - 작업자 ID
  /// [toteId] - 토트박스 ID
  ///
  /// Returns: 성공 시 응답 데이터, 실패 시 ApiException 발생
  static Future<Map<String, dynamic>> scanToteBox(
    String workType,
    String workerId,
    String toteId,
  ) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/$workType/$workerId/scan');
      final requestBody = json.encode({'tote_id': toteId});

      // 디버깅용 로그
      if (kDebugMode) {
        print('[API] 📦 토트박스 스캔 요청: $url');
        print('[API] 📤 요청 바디: $requestBody');
      }

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: requestBody,
          )
          .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      // 디버깅용 로그
      if (kDebugMode) {
        print('[API] 📥 스캔 응답 상태: ${response.statusCode}');
        print('[API] 📄 스캔 응답 바디: ${response.body}');
      }

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        if (kDebugMode) {
          print('[API] ✅ 토트박스 스캔 성공');
        }
        return responseData;
      } else {
        // 상태 코드별 구체적인 에러 메시지
        String errorMessage;
        switch (response.statusCode) {
          case 404:
            errorMessage = '해당 토트박스를 찾을 수 없거나\\n사용 가능한 작업이 없습니다.';
            break;
          case 400:
            errorMessage = '잘못된 요청입니다.\\n토트 ID를 확인해주세요.';
            break;
          case 500:
            errorMessage = '서버 오류가 발생했습니다.\\n잠시 후 다시 시도해주세요.';
            break;
          default:
            errorMessage = '토트박스 스캔에 실패했습니다.\\n(오류 코드: ${response.statusCode})';
        }
        
        throw ServerException(
          message: errorMessage,
          statusCode: response.statusCode,
          responseBody: response.body,
        );
      }
    } on TimeoutException {
      throw NetworkException(message: '요청 시간이 초과되었습니다.\\n네트워크 연결을 확인해주세요.');
    } on http.ClientException {
      throw NetworkException(message: '네트워크 연결을 확인해주세요.');
    } on SocketException {
      throw NetworkException(message: '인터넷 연결을 확인해주세요.');
    } on ServerException {
      // ServerException은 그대로 전달
      rethrow;
    } on NetworkException {
      // NetworkException은 그대로 전달
      rethrow;
    } catch (e) {
      // 디버깅용 로그
      if (kDebugMode) {
        print('[API] ❌ 토트박스 스캔 예상치 못한 오류: $e');
      }
      throw ApiException(message: '토트박스 스캔 중 예상치 못한 오류가 발생했습니다.\\n$e');
    }
  }

  /// 작업 완료 보고 API 호출
  ///
  /// [workType] - 작업 유형 (IB 또는 OB)
  /// [workerId] - 작업자 ID
  /// [locationId] - 위치 ID (에러 처리 시 필수)
  ///
  /// Returns: 성공 시 true, 실패 시 ApiException 발생
  static Future<bool> finishWork(String workType, String workerId, [String? locationId]) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/$workType/$workerId/finish');
      
      Map<String, String> requestBody = {};
      if (locationId != null) {
        requestBody['location_id'] = locationId;
      }

      final response = await http
          .post(
            url, 
            headers: {'Content-Type': 'application/json'},
            body: requestBody.isNotEmpty ? json.encode(requestBody) : null,
          )
          .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      if (response.statusCode == 200) {
        return true;
      } else {
        throw ServerException(
          message: '작업 완료 보고에 실패했습니다.',
          statusCode: response.statusCode,
          responseBody: response.body,
        );
      }
    } on http.ClientException {
      throw NetworkException(message: '네트워크 연결을 확인해주세요.');
    } on SocketException {
      throw NetworkException(message: '인터넷 연결을 확인해주세요.');
    } catch (e) {
      throw ApiException(message: '알 수 없는 오류가 발생했습니다.');
    }
  }

  /// 에러 상태 확인 API 호출
  ///
  /// [workType] - 작업 유형 (IB 또는 OB)
  /// [workerId] - 작업자 ID
  ///
  /// Returns: 에러 상태 정보, 실패 시 ApiException 발생
  static Future<Map<String, dynamic>> getErrorStatus(String workType, String workerId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/$workType/$workerId/error-status');

      final response = await http
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw ServerException(
          message: '에러 상태 확인에 실패했습니다.',
          statusCode: response.statusCode,
          responseBody: response.body,
        );
      }
    } on http.ClientException {
      throw NetworkException(message: '네트워크 연결을 확인해주세요.');
    } on SocketException {
      throw NetworkException(message: '인터넷 연결을 확인해주세요.');
    } catch (e) {
      throw ApiException(message: '알 수 없는 오류가 발생했습니다.');
    }
  }
}
