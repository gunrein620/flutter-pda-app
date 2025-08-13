import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/worker_api_service.dart';
import '../../core/services/user_storage_service.dart';
import '../../core/exceptions/api_exception.dart';

/// 에러 확인 다이얼로그
/// 하드웨어에서 에러 신호를 받았을 때 표시되는 팝업
class ErrorConfirmationDialog extends StatefulWidget {
  final String locationId;
  final String errorCode;
  final VoidCallback? onConfirmed;

  const ErrorConfirmationDialog({
    super.key,
    required this.locationId,
    required this.errorCode,
    this.onConfirmed,
  });

  @override
  State<ErrorConfirmationDialog> createState() => _ErrorConfirmationDialogState();
}

class _ErrorConfirmationDialogState extends State<ErrorConfirmationDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: screenSize.width * 0.85,
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15.0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 에러 아이콘
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 40,
                ),
              ),

              const SizedBox(height: 20),

              // 제목
              Text(
                '문제가 발생했습니다',
                style: TextStyle(
                  fontSize: screenSize.width * 0.055,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // 위치 정보
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  '위치: ${widget.locationId}',
                  style: TextStyle(
                    fontSize: screenSize.width * 0.04,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 설명 메시지
              Text(
                '해당 위치에서 문제를 해결한 후\n확인 버튼을 눌러주세요.',
                style: TextStyle(
                  fontSize: screenSize.width * 0.04,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // 버튼들
              Row(
                children: [
                  // 취소 버튼
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.textSecondary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                        ),
                        child: Text(
                          '취소',
                          style: TextStyle(
                            fontSize: screenSize.width * 0.04,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // 확인 버튼
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.textWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                '확인',
                                style: TextStyle(
                                  fontSize: screenSize.width * 0.04,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 확인 버튼 처리
  Future<void> _handleConfirm() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 사용자 정보 가져오기
      final userInfo = await UserStorageService.getUserInfo();
      final workType = userInfo['workType'] ?? 'IB';
      final workerId = userInfo['workerId'] ?? '1234';

      print('에러 수동 처리 시작: $workType/$workerId, location: ${widget.locationId}');

      // 작업 완료 API 호출 (location_id 포함)
      final success = await WorkerApiService.finishWork(workType, workerId, widget.locationId);

      if (success && mounted) {
        print('에러 수동 처리 성공');

        // 다이얼로그 닫기
        Navigator.of(context).pop();

        // 콜백 실행
        widget.onConfirmed?.call();

        // 성공 메시지 표시
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('문제가 해결되었습니다.'),
              backgroundColor: AppColors.primary,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = '처리 중 오류가 발생했습니다.';

        if (e is ApiException) {
          errorMessage = e.message;
        } else if (e is NetworkException) {
          errorMessage = e.message;
        } else if (e is ServerException) {
          errorMessage = e.message;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
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

/// 에러 확인 다이얼로그 표시 헬퍼 함수
Future<void> showErrorConfirmationDialog(
  BuildContext context, {
  required String locationId,
  required String errorCode,
  VoidCallback? onConfirmed,
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // 외부 터치로 닫기 방지
    builder: (BuildContext context) {
      return ErrorConfirmationDialog(
        locationId: locationId,
        errorCode: errorCode,
        onConfirmed: onConfirmed,
      );
    },
  );
}