import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// 토트 ID 입력 다이얼로그
/// QR 스캔 대신 사용자가 토트 ID를 직접 입력할 수 있는 다이얼로그
class ToteIdInputDialog extends StatefulWidget {
  final Function(String toteId) onConfirm;

  const ToteIdInputDialog({
    super.key,
    required this.onConfirm,
  });

  @override
  State<ToteIdInputDialog> createState() => _ToteIdInputDialogState();
}

class _ToteIdInputDialogState extends State<ToteIdInputDialog> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 다이얼로그가 열리면 자동으로 키보드 표시
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: screenSize.width * 0.9,
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
              // QR 코드 아이콘
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.qr_code_scanner,
                  color: AppColors.primary,
                  size: 40,
                ),
              ),

              const SizedBox(height: 20),

              // 제목
              Text(
                '토트 ID 입력',
                style: TextStyle(
                  fontSize: screenSize.width * 0.055,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // 설명 메시지
              Text(
                '토트박스의 ID를 입력해주세요\n(예: TOTE-100)',
                style: TextStyle(
                  fontSize: screenSize.width * 0.04,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // 토트 ID 입력 필드
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: !_isLoading,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: screenSize.width * 0.045,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'TOTE-XXX',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.6),
                    fontWeight: FontWeight.w400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: AppColors.primary, width: 2.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 16.0,
                  ),
                ),
                textCapitalization: TextCapitalization.characters,
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    _handleConfirm();
                  }
                },
              ),

              // 에러 메시지
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: screenSize.width * 0.035,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

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
  void _handleConfirm() {
    final toteId = _controller.text.trim();

    // 입력값 검증
    if (toteId.isEmpty) {
      setState(() {
        _errorMessage = '토트 ID를 입력해주세요.';
      });
      return;
    }

    // 기본적인 형식 검증 (선택사항)
    if (toteId.length < 3) {
      setState(() {
        _errorMessage = '토트 ID가 너무 짧습니다.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // 다이얼로그 닫기 및 콜백 실행
    Navigator.of(context).pop();
    widget.onConfirm(toteId);
  }
}

/// 토트 ID 입력 다이얼로그 표시 헬퍼 함수
Future<void> showToteIdInputDialog(
  BuildContext context, {
  required Function(String toteId) onConfirm,
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // 외부 터치로 닫기 방지
    builder: (BuildContext context) {
      return ToteIdInputDialog(
        onConfirm: onConfirm,
      );
    },
  );
}