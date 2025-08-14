import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_config.dart';
import '../../core/router/app_router.dart';
import 'basic_screen.dart';
import '../../core/constants/app_sizes.dart';
import '../widgets/rescue_pang_logo.dart';
import '../widgets/custom_input_field.dart';
import '../widgets/work_type_dropdown.dart';
import '../widgets/login_button.dart';
import '../../core/services/worker_api_service.dart';
import '../../core/services/user_storage_service.dart';
import '../../core/exceptions/api_exception.dart';

/// 로그인 페이지
/// 사용자 ID와 작업 유형을 입력받아 로그인 처리
@RoutePage()
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _userIdController = TextEditingController();
  WorkType? _selectedWorkType;
  bool _isLoading = false;

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_userIdController.text.isEmpty || _selectedWorkType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('사용자 ID와 작업 유형을 모두 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // API 호출
      final workType = _selectedWorkType!.value; // IB 또는 OB
      final workerId = _userIdController.text.trim();

      print('🔑 로그인 시도: workType=$workType, workerId=$workerId');
      print('🌐 API URL: ${ApiConfig.baseUrl}');

      await WorkerApiService.registerWorker(workType, workerId);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        print('✅ 로그인 성공!');

        // 로그인 성공 시 사용자 정보 저장
        await UserStorageService.saveUserInfo(workType, workerId);

        // 스캔 화면으로 이동
        context.router.replace(BasicRoute(reqType: 'scan'));
      }
    } on NetworkException catch (e) {
      print('🌐 네트워크 오류: ${e.message}');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('네트워크 연결 오류\\n${e.message}\\n\\n현재 서버 주소: ${ApiConfig.baseUrl}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } on ServerException catch (e) {
      print('🛠️ 서버 오류: ${e.message} (상태코드: ${e.statusCode})');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('서버 오류\\n${e.message}\\n\\n상태 코드: ${e.statusCode}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } on ApiException catch (e) {
      print('⚠️ API 오류: ${e.message}');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인 실패\\n${e.message}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('❌ 예상치 못한 오류: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('예상치 못한 오류가 발생했습니다\\n$e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.horizontalPadding,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 80),

                  // 로고
                  const Center(child: RescuePangLogo()),

                  const SizedBox(height: AppSizes.verticalSpacing),

                  // 로그인 폼 컨테이너
                  Container(
                    width: AppSizes.formContainerWidth,
                    constraints: const BoxConstraints(
                      minHeight: AppSizes.formContainerHeight,
                      maxHeight: 450,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(
                        AppSizes.formContainerRadius,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 사용자 ID 입력 필드
                          CustomInputField(
                            label: '사용자 ID 입력',
                            hintText: '사용자 ID를 입력하세요',
                            controller: _userIdController,
                          ),

                          const SizedBox(height: AppSizes.verticalSpacing),

                          // 작업 유형 선택
                          WorkTypeDropdown(
                            selectedValue: _selectedWorkType,
                            onChanged: (WorkType? value) {
                              setState(() {
                                _selectedWorkType = value;
                              });
                            },
                          ),

                          const SizedBox(height: AppSizes.verticalSpacing),

                          // 로그인 버튼
                          LoginButton(
                            onPressed: _handleLogin,
                            isLoading: _isLoading,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
