import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/router/app_router.dart';
import '../../core/services/user_storage_service.dart';
import '../../core/models/task_model.dart';

/// Mission Briefing Screen - 진열 물품 리스트 화면
/// 작업 시작 전 물품 목록을 확인하는 화면
@RoutePage()
class MissionBriefingScreen extends StatefulWidget {
  const MissionBriefingScreen({super.key});

  @override
  State<MissionBriefingScreen> createState() => _MissionBriefingScreenState();
}

class _MissionBriefingScreenState extends State<MissionBriefingScreen> {
  List<Task> _tasks = [];
  bool _isLoading = false;
  String _workType = '';

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _loadWorkType();
  }

  /// 저장된 태스크 데이터 로드
  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tasks = await UserStorageService.getTasks();
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('태스크 로드 오류: $e');
    }
  }

  /// 작업 타입 로드
  Future<void> _loadWorkType() async {
    final workType = await UserStorageService.getWorkType();
    setState(() {
      _workType = workType ?? '';
    });
  }

  /// 작업 타입에 따른 제목 반환
  String get _getTitle {
    switch (_workType) {
      case 'IB':
        return '진열 물품 리스트';
      case 'OB':
        return '집품 물품 리스트';
      default:
        return '물품 리스트';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20.0),

              // 헤더 제목
              Text(_getTitle, style: Theme.of(context).textTheme.headlineLarge),

              const SizedBox(height: 20.0),

              // 물품 리스트 컨테이너
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      return _buildItemCard(task);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20.0),

              // 작업 시작 버튼
              SizedBox(
                width: double.infinity,
                height: 56.0,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleStartMission,
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
                          width: 20.0,
                          height: 20.0,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          '작업 시작',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
    );
  }

  /// 물품 카드 위젯
  Widget _buildItemCard(Task task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // 물품 이미지
          Container(
            width: 80.0,
            height: 80.0,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: task.hasLocalImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.asset(
                      task.localImagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.textSecondary,
                          size: 32.0,
                        );
                      },
                    ),
                  )
                : task.img.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          task.img,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.inventory_2_outlined,
                              color: AppColors.textSecondary,
                              size: 32.0,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.textSecondary,
                        size: 32.0,
                      ),
          ),

          const SizedBox(width: 16.0),

          // 물품 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.name,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  '수량: ${task.quantity}개',
                  style: const TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  '위치: ${task.targetLocationId}',
                  style: const TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 작업 시작 처리 메서드
  Future<void> _handleStartMission() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 첫 번째 태스크가 있는지 확인
      if (_tasks.isEmpty) {
        throw Exception('진행할 태스크가 없습니다.');
      }

      // 첫 번째 태스크의 위치를 목표 위치로 설정
      final firstTask = _tasks[0];
      await UserStorageService.saveCurrentProgress(
        taskIndex: 0,
        targetLocation: firstTask.targetLocationId,
      );

      if (mounted) {
        print('작업이 시작되었습니다. 목표 위치: ${firstTask.targetLocationId}');
        context.router.push(BasicRoute(reqType: 'navigate'));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('작업 시작 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
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
