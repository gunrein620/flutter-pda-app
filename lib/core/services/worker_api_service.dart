import 'dart:io';
import 'dart:convert';
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

      final response = await http
          .put(url, headers: {'Content-Type': 'application/json'})
          .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      if (response.statusCode == 200) {
        return true;
      } else {
        throw ServerException(
          message: '작업자 등록에 실패했습니다.',
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

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: requestBody,
          )
          .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw ServerException(
          message: '토트박스 스캔에 실패했습니다.',
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
