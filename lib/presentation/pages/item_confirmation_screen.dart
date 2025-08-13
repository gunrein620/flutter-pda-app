import 'dart:async';
import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import '../../core/constants/app_colors.dart';
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
  Timer? _errorPollingTimer;

  @override
  void initState() {
    super.initState();
    _loadCurrentTask();
    _startErrorPolling();
  }

  @override
  void dispose() {
    _errorPollingTimer?.cancel();
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

  /// 에러 상태 폴링 시작
  void _startErrorPolling() {
    _errorPollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkErrorStatus();
    });
  }

  /// 에러 상태 확인
  Future<void> _checkErrorStatus() async {
    try {
      // 사용자 정보 가져오기
      final userInfo = await UserStorageService.getUserInfo();
      final workType = userInfo['workType'] ?? 'IB';
      final workerId = userInfo['workerId'] ?? '1234';

      // 에러 상태 확인 API 호출
      final errorStatus = await WorkerApiService.getErrorStatus(workType, workerId);

      if (errorStatus['hasError'] == true && mounted) {
        final locationId = errorStatus['location_id'] as String;
        final errorCode = errorStatus['code'] as String;

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
    } catch (e) {
      // 에러 상태 확인 실패는 로그만 출력 (사용자에게 알리지 않음)
      print('에러 상태 확인 실패: $e');
    }
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
      // 사용자 정보 가져오기
      final userInfo = await UserStorageService.getUserInfo();
      final workType = userInfo['workType'] ?? 'IB';
      final workerId = userInfo['workerId'] ?? '1234';

      print('작업 완료 보고 시작: $workType/$workerId');

      // 작업 완료 API 호출
      final success = await WorkerApiService.finishWork(workType, workerId);

      if (success && mounted) {
        print('작업 완료 보고 성공');

        // 현재 태스크 인덱스 증가
        final currentTaskIndex = await UserStorageService.getCurrentTaskIndex();
        final tasks = await UserStorageService.getTasks();

        if (currentTaskIndex < tasks.length - 1) {
          // 다음 태스크가 있는 경우
          final nextTaskIndex = currentTaskIndex + 1;
          final nextTask = tasks[nextTaskIndex];

          // 다음 태스크의 목표 위치가 현재와 다른지 확인
          final currentTargetLocation =
              await UserStorageService.getTargetLocation();

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
