import '../utils/image_mapper.dart';

/// 작업 태스크 모델
class Task {
  final String productId;
  final String name;
  final String img;
  final int quantity;
  final String targetLocationId;

  Task({
    required this.productId,
    required this.name,
    required this.img,
    required this.quantity,
    required this.targetLocationId,
  });

  /// 로컬 이미지 경로 반환 (assets 이미지 우선)
  String get localImagePath {
    final localPath = ImageMapper.getImagePath(name);
    return localPath ?? img; // 로컬 이미지가 없으면 서버 이미지 URL 사용
  }

  /// 이미지가 로컬 assets인지 확인
  bool get hasLocalImage {
    return ImageMapper.getImagePath(name) != null;
  }

  /// JSON에서 Task 객체 생성
  factory Task.fromJson(Map<String, dynamic> json) {
    try {
      return Task(
        productId: json['product_id'].toString(), // int를 String으로 변환
        name: json['product_name'] as String? ?? json['name'] as String? ?? '', // 서버의 product_name 또는 name 필드 사용
        img: json['img'] as String? ?? '', // null일 경우 빈 문자열
        quantity: json['quantity'] as int,
        targetLocationId: json['location_id'] as String? ?? json['target_location_id'] as String? ?? '', // 서버의 location_id 필드 사용
      );
    } catch (e) {
      print('[Task.fromJson] ⚠️ 파싱 오류 발생: $e');
      print('[Task.fromJson] 📋 JSON 데이터: $json');
      print('[Task.fromJson] 🔍 개별 필드 분석:');
      print('  - product_id: ${json['product_id']} (타입: ${json['product_id']?.runtimeType})');
      print('  - product_name: ${json['product_name']} (타입: ${json['product_name']?.runtimeType})');
      print('  - name: ${json['name']} (타입: ${json['name']?.runtimeType})');
      print('  - quantity: ${json['quantity']} (타입: ${json['quantity']?.runtimeType})');
      print('  - location_id: ${json['location_id']} (타입: ${json['location_id']?.runtimeType})');
      print('  - target_location_id: ${json['target_location_id']} (타입: ${json['target_location_id']?.runtimeType})');
      print('  - img: ${json['img']} (타입: ${json['img']?.runtimeType})');
      rethrow;
    }
  }

  /// Task 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'name': name,
      'img': img,
      'quantity': quantity,
      'target_location_id': targetLocationId,
    };
  }
}

/// 토트박스 스캔 응답 모델
class ToteBoxScanResponse {
  final List<Task> tasks;

  ToteBoxScanResponse({required this.tasks});

  /// JSON에서 ToteBoxScanResponse 객체 생성
  factory ToteBoxScanResponse.fromJson(Map<String, dynamic> json) {
    try {
      print('[ToteBoxScanResponse] 📥 파싱 시작: $json');
      
      List<Task> tasks = [];
      
      // Case 1: 배열 형태 응답 - {"tasks": [...]}
      if (json.containsKey('tasks') && json['tasks'] is List) {
        print('[ToteBoxScanResponse] 🔄 배열 형태 응답 처리');
        final tasksList = json['tasks'] as List<dynamic>;
        print('[ToteBoxScanResponse] 📊 태스크 개수: ${tasksList.length}');
        
        tasks = tasksList
            .map((taskJson) {
              print('[ToteBoxScanResponse] 🔍 개별 태스크 파싱: $taskJson');
              return Task.fromJson(taskJson as Map<String, dynamic>);
            })
            .toList();
      }
      // Case 2: 단일 객체 응답 - 직접 Task 필드들이 포함된 경우
      else if (json.containsKey('product_id') || json.containsKey('product_name')) {
        print('[ToteBoxScanResponse] 🎯 단일 객체 응답 처리');
        final task = Task.fromJson(json);
        tasks = [task];
      }
      // Case 3: 알 수 없는 구조
      else {
        print('[ToteBoxScanResponse] ❓ 알 수 없는 응답 구조');
        throw FormatException('알 수 없는 서버 응답 구조: $json');
      }

      print('[ToteBoxScanResponse] ✅ 파싱 완료: ${tasks.length}개 태스크');
      return ToteBoxScanResponse(tasks: tasks);
    } catch (e) {
      print('[ToteBoxScanResponse] ⚠️ 파싱 오류: $e');
      print('[ToteBoxScanResponse] 📋 JSON 데이터: $json');
      rethrow;
    }
  }

  /// ToteBoxScanResponse 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {'tasks': tasks.map((task) => task.toJson()).toList()};
  }
}
