import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_config.dart';
import '../../core/services/user_storage_service.dart';
import '../../core/services/worker_api_service.dart';
import '../../core/models/task_model.dart';
import '../../core/exceptions/api_exception.dart';
import '../../core/router/app_router.dart';
import '../widgets/error_confirmation_dialog.dart';

/// Item Confirmation Screen - 물품 확인 화면
/// 스캔된 물품의 정보를 확인하고 작업을 진행하는 화면
@RoutePage()
class ItemConfirmationScreen extends StatefulWidget {
  const ItemConfirmationScreen({super.key});

  @override
  State<ItemConfirmationScreen> createState() => _ItemConfirmationScreenState();
}

class _ItemConfirmationScreenState extends State<ItemConfirmationScreen> {
  Task? _currentTask;
  bool _isLoading = false;
  WebSocketChannel? _webSocketChannel;
  StreamSubscription? _webSocketSubscription;
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  @override
  void initState() {
    super.initState();
    _loadCurrentTask();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _disconnectWebSocket();
    super.dispose();
  }

  /// 현재 태스크 로드
  Future<void> _loadCurrentTask() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 태스크 리스트와 현재 인덱스 가져오기
      final tasks = await UserStorageService.getTasks();
      final currentTaskIndex = await UserStorageService.getCurrentTaskIndex();

      if (tasks.isNotEmpty && currentTaskIndex < tasks.length) {
        setState(() {
          _currentTask = tasks[currentTaskIndex];
          _isLoading = false;
        });
        print('현재 태스크: ${_currentTask!.name} (${_currentTask!.quantity}개)');
      } else {
        setState(() {
          _isLoading = false;
        });
        print('진행할 태스크가 없습니다.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('태스크 로드 오류: $e');
    }
  }

  /// WebSocket 연결
  Future<void> _connectWebSocket() async {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('[WebSocket] 최대 재연결 시도 횟수 초과. 연결 포기.');
      return;
    }
    
    try {
      final userInfo = await UserStorageService.getUserInfo();
      final workType = userInfo['workType'] ?? 'IB';
      final workerId = userInfo['workerId'] ?? '1234';
      
      final wsUrl = ApiConfig.baseUrl.replaceFirst('http', 'ws');
      final uri = Uri.parse('$wsUrl/ws/$workType/$workerId');
      
      print('[WebSocket] 연결 시도 (${_reconnectAttempts + 1}/${_maxReconnectAttempts}): $uri');
      
      _webSocketChannel = WebSocketChannel.connect(uri);
      
      _webSocketSubscription = _webSocketChannel!.stream.listen(
        (message) {
          _handleWebSocketMessage(message);
        },
        onError: (error) {
          print('[WebSocket] 오류: $error');
          if (mounted) {
            setState(() {
              _isConnected = false;
            });
          }
          _reconnectWebSocket();
        },
        onDone: () {
          print('[WebSocket] 연결 종료');
          if (mounted) {
            setState(() {
              _isConnected = false;
            });
          }
          _reconnectWebSocket();
        },
      );
      
    } catch (e) {
      print('[WebSocket] 연결 실패: $e');
      if (mounted) {
        setState(() {
          _isConnected = false;
        });
      }
      _reconnectWebSocket();
    }
  }
  
  /// WebSocket 메시지 처리
  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message.toString());
      print('[WebSocket] 메시지 수신: $data');
      
      final type = data['type'];
      
      if (type == 'connected') {
        print('[WebSocket] 연결 확인됨');
        if (mounted) {
          setState(() {
            _isConnected = true;
            _reconnectAttempts = 0; // 연결 성공 시 재연결 시도 카운터 리셋
          });
        }
      } else if (type == 'task_completed') {
        print('[WebSocket] 작업 완료 알림 수신');
        _handleTaskCompleted();
      } else if (type == 'task_error') {
        final locationId = data['location_id'] as String;
        final errorCode = data['code'] as String;
        print('[WebSocket] 에러 알림 수신: $locationId, code: $errorCode');
        _handleTaskError(locationId, errorCode);
      }
    } catch (e) {
      print('[WebSocket] 메시지 파싱 오류: $e');
    }
  }
  
  /// 작업 완료 처리
  Future<void> _handleTaskCompleted() async {
    if (!mounted) return;
    
    try {
      // 현재 태스크 인덱스 증가
      final currentTaskIndex = await UserStorageService.getCurrentTaskIndex();
      final tasks = await UserStorageService.getTasks();

      if (currentTaskIndex < tasks.length - 1) {
        // 다음 태스크가 있는 경우
        final nextTaskIndex = currentTaskIndex + 1;
        final nextTask = tasks[nextTaskIndex];

        // 다음 태스크의 목표 위치가 현재와 다른지 확인
        final currentTargetLocation = await UserStorageService.getTargetLocation();

        if (nextTask.targetLocationId != currentTargetLocation) {
          // 다른 위치로 이동해야 하는 경우
          await UserStorageService.saveCurrentProgress(
            taskIndex: nextTaskIndex,
            targetLocation: nextTask.targetLocationId,
          );

          // Basic Screen으로 이동 (새로운 목표 위치 표시)
          context.router.replace(BasicRoute(reqType: 'navigate'));
        } else {
          // 같은 위치에서 다음 태스크 처리
          await UserStorageService.saveCurrentProgress(
            taskIndex: nextTaskIndex,
            targetLocation: nextTask.targetLocationId,
          );

          // 같은 화면에서 다음 태스크 로드
          await _loadCurrentTask();
        }
      } else {
        // 모든 태스크 완료
        print('모든 태스크가 완료되었습니다.');
        context.router.replace(BasicRoute(reqType: 'scan'));
      }

      // 성공 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('물품이 성공적으로 확인되었습니다.'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      print('작업 완료 처리 오류: $e');
    }
  }
  
  /// 작업 에러 처리
  Future<void> _handleTaskError(String locationId, String errorCode) async {
    if (!mounted) return;
    
    print('에러 상태 감지: $locationId, code: $errorCode');

    // 에러 확인 다이얼로그 표시
    await showErrorConfirmationDialog(
      context,
      locationId: locationId,
      errorCode: errorCode,
      onConfirmed: () {
        // 에러 처리 완료 후 태스크 다시 로드
        _loadCurrentTask();
      },
    );
  }
  
  /// WebSocket 재연결
  Future<void> _reconnectWebSocket() async {
    if (!mounted || _reconnectAttempts >= _maxReconnectAttempts) {
      return;
    }
    
    _disconnectWebSocket();
    _reconnectAttempts++;
    
    // 지수 백오프: 2^attempts초 대기 (최대 30초)
    final delaySeconds = (2 * _reconnectAttempts).clamp(1, 30);
    print('[WebSocket] ${delaySeconds}초 후 재연결 시도...');
    
    await Future.delayed(Duration(seconds: delaySeconds));
    
    if (mounted) {
      _connectWebSocket();
    }
  }
  
  /// WebSocket 연결 해제
  void _disconnectWebSocket() {
    _webSocketSubscription?.cancel();
    _webSocketChannel?.sink.close();
    _webSocketSubscription = null;
    _webSocketChannel = null;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final availableHeight = screenSize.height - padding.top - padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 20.0),

              // WebSocket 연결 상태 표시
              if (!_isConnected)
                Container(
                  margin: const EdgeInsets.only(bottom: 10.0),
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 12.0,
                        height: 12.0,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        '실시간 연결 중...',
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              // 제품 이미지 카드
              Center(
                child: Container(
                  width: screenSize.width * 0.75, // 화면 너비의 75%
                  height: screenSize.width * 0.75, // 정사각형 유지
                  constraints: const BoxConstraints(
                    maxWidth: 280.0,
                    maxHeight: 280.0,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10.0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.0),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: const Color(0xFFF2F2F2),
                      child: _currentTask?.img.isNotEmpty == true
                          ? Image.network(_currentTask!.img, fit: BoxFit.cover)
                          : const Icon(
                              Icons.laptop_mac_outlined,
                              color: AppColors.textSecondary,
                              size: 64.0,
                            ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20.0),

              // 제품 이름 배경
              Center(
                child: Container(
                  width: screenSize.width * 0.6, // 화면 너비의 60%
                  constraints: const BoxConstraints(
                    maxWidth: 200.0,
                    minHeight: 60.0,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        _currentTask?.name ?? '로딩 중...',
                        style: TextStyle(
                          fontSize: screenSize.width * 0.06, // 반응형 폰트 크기
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10.0),

              // 수량 정보 배경
              Center(
                child: Container(
                  width: screenSize.width * 0.6, // 화면 너비의 60%
                  constraints: const BoxConstraints(
                    maxWidth: 200.0,
                    minHeight: 50.0,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Text(
                        '수량: ${_currentTask?.quantity ?? 0}개',
                        style: TextStyle(
                          fontSize: screenSize.width * 0.045, // 반응형 폰트 크기
                          fontWeight: FontWeight.w600,
                          color: AppColors.textWhite,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // 확인 버튼
              Center(
                child: SizedBox(
                  width: screenSize.width * 0.8, // 화면 너비의 80%
                  height: 64.0,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.textWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28.0),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24.0,
                            height: 24.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            '확인',
                            style: TextStyle(
                              fontSize: screenSize.width * 0.045, // 반응형 폰트 크기
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),

              SizedBox(height: availableHeight * 0.05), // 화면 높이의 5%
            ],
          ),
        ),
      ),
    );
  }

  /// 확인 버튼 처리 메서드
  Future<void> _handleConfirm() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 현재 태스크가 없으면 처리 불가
      if (_currentTask == null) {
        throw Exception('현재 확인할 태스크가 없습니다.');
      }
      // 사용자 정보 가져오기
      final userInfo = await UserStorageService.getUserInfo();
      final workType = userInfo['workType'] ?? 'IB';
      final workerId = userInfo['workerId'] ?? '1234';

      print('작업 완료 보고 시작: $workType/$workerId');

      // 작업 완료 API 호출
      // 서버는 location_id를 필수로 요구하므로 현재 태스크의 위치를 함께 전달
      final success = await WorkerApiService.finishWork(
        workType,
        workerId,
        _currentTask!.targetLocationId,
      );

      if (success && mounted) {
        print('작업 완료 보고 성공 - WebSocket 응답 대기 중...');
        
        // WebSocket이 응답을 처리하므로 여기서는 성공 메시지만 표시
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('작업 완료 요청이 전송되었습니다. 하드웨어 응답을 기다리는 중...'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = '확인 중 오류가 발생했습니다.';

        if (e is ApiException) {
          errorMessage = e.message;
        } else if (e is NetworkException) {
          errorMessage = e.message;
        } else if (e is ServerException) {
          errorMessage = e.message;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
