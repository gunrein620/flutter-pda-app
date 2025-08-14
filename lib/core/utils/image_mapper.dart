/// 제품명과 이미지 파일을 매핑하는 유틸리티 클래스
class ImageMapper {
  /// 제품명과 이미지 파일명을 매핑하는 맵
  static const Map<String, String> _productImageMap = {
    // 정확한 제품명과 파일명 매핑
    '페브리즈': 'assets/images/products/febreze.jpg',
    '휴지 15롤': 'assets/images/products/tissue_15_rolls.jpg',
    '무선청소기': 'assets/images/products/cordless_vacuum.jpg',
    '세탁세제 리필': 'assets/images/products/detergent_refill.jpg',
    '비타민 세트': 'assets/images/products/vitamin_set.jpg',
    
    // 추가 매핑 (유사한 이름들도 처리)
    '휴지': 'assets/images/products/tissue_15_rolls.jpg',
    '청소기': 'assets/images/products/cordless_vacuum.jpg',
    '세제': 'assets/images/products/detergent_refill.jpg',
    '비타민': 'assets/images/products/vitamin_set.jpg',
    '페브리즈 방향제': 'assets/images/products/febreze.jpg',
    
    // 모든 제품들 추가
    'led스탠드조명': 'assets/images/products/led_lamp.jpg',
    'LED스탠드조명': 'assets/images/products/led_lamp.jpg',
    '휴대용가스버너': 'assets/images/products/portable_gas_burner.jpg',
    '휴대용 가스버너': 'assets/images/products/portable_gas_burner.jpg',
    '가스버너': 'assets/images/products/portable_gas_burner.jpg',
    '버너': 'assets/images/products/portable_gas_burner.jpg',
    '핸드크림3개': 'assets/images/products/hand_cream_3.jpg',
    '핸드크림': 'assets/images/products/hand_cream_3.jpg',
    // 영문 파일명 복사본(일부 단말의 한글 파일명 이슈 회피)
    '탄산음료 1.5L': 'assets/images/products/sparkling_1_5l.jpg',
    '탄산음료': 'assets/images/products/sparkling_1_5l.jpg',
    '컵라면15개': 'assets/images/products/cup_noodle_15.jpg',
    '컵라면': 'assets/images/products/cup_noodle_15.jpg',
    '전기포트': 'assets/images/products/electric_kettle.jpg',
    '전기토스터': 'assets/images/products/toaster.jpg',
    '토스터': 'assets/images/products/toaster.jpg',
    '전기장판': 'assets/images/products/electric_matt.jpg',
    '장판': 'assets/images/products/electric_matt.jpg',
    '손선풍기': 'assets/images/products/mini_fan.jpg',
    '세제500ml': 'assets/images/products/detergent_500ml.jpg',
    '세면타올3개': 'assets/images/products/towel_3.jpg',
    '세면타올': 'assets/images/products/towel_3.jpg',
    '타올': 'assets/images/products/towel_3.jpg',
    '선풍기': 'assets/images/products/fan.jpg',
    '샴푸1L': 'assets/images/products/shampoo_1l.jpg',
    '샴푸': 'assets/images/products/shampoo_1l.jpg',
    '생수4개': 'assets/images/products/water_4.png',
    '생수': 'assets/images/products/water_4.png',
    '물': 'assets/images/products/water_4.png',
    '보조배터리': 'assets/images/products/power_bank.jpg',
    '배터리': 'assets/images/products/power_bank.jpg',
    '물티슈100매': 'assets/images/products/wet_tissue_100.jpg',
    '물티슈': 'assets/images/products/wet_tissue_100.jpg',
    '티슈': 'assets/images/products/wet_tissue_100.jpg',
    '무선마우스': 'assets/images/products/wireless_mouse.jpg',
    '마우스': 'assets/images/products/wireless_mouse.jpg',
    '마스크팩10매': 'assets/images/products/mask_pack_10.jpg',
    '마스크팩': 'assets/images/products/mask_pack_10.jpg',
    '마스크': 'assets/images/products/mask_pack_10.jpg',
    '두유10팩': 'assets/images/products/soymilk_10.jpg',
    '두유': 'assets/images/products/soymilk_10.jpg',
    '노트북가방': 'assets/images/products/laptop_bag.jpg',
    '가방': 'assets/images/products/laptop_bag.jpg',
  };

  /// 제품명으로 이미지 경로를 반환
  /// [productName] 제품명
  /// Returns: 이미지 경로 또는 null (매핑되지 않은 경우)
  static String? getImagePath(String productName) {
    // 정확한 매칭 시도
    if (_productImageMap.containsKey(productName)) {
      return _productImageMap[productName];
    }
    
    // 부분 매칭 시도 (대소문자 구분 없이)
    final lowerProductName = productName.toLowerCase();
    for (final entry in _productImageMap.entries) {
      if (entry.key.toLowerCase().contains(lowerProductName) ||
          lowerProductName.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    
    return null;
  }

  /// 제품명으로 이미지 경로를 반환 (기본 이미지 포함)
  /// [productName] 제품명
  /// Returns: 이미지 경로 (매핑되지 않은 경우 기본 아이콘 사용)
  static String getImagePathWithDefault(String productName) {
    return getImagePath(productName) ?? '';
  }

  /// 사용 가능한 모든 제품 이미지 목록 반환
  static List<String> getAllImagePaths() {
    return _productImageMap.values.toSet().toList();
  }

  /// 매핑된 제품명 목록 반환
  static List<String> getAllProductNames() {
    return _productImageMap.keys.toList();
  }
}
