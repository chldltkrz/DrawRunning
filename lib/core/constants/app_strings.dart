/// Korean UI strings for the entire app.
class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'Draw Running';

  // Home Screen
  static const String textInputLabel = '그릴 텍스트 입력';
  static const String textInputHint = '예: HELLO';
  static const String textPreviewPlaceholder = '위에 텍스트를 입력하면 미리보기가 표시됩니다';
  static const String routeSize = '경로 크기';
  static const String estimatedRoute = '예상 경로: {km} km';
  static const String generateRoute = '경로 생성';
  static const String runHistory = '러닝 기록';

  // Scale labels
  static const String scaleSmall = '소';
  static const String scaleMedium = '중';
  static const String scaleLarge = '대';
  static const String scaleXL = '특대';

  // Generation progress
  static const String generating = '생성 중...';
  static const String findingRoads = '도로 탐색 중...';
  static const String optimizingOrder = '순서 최적화 중...';
  static const String connectingRoute = '경로 연결 중...';
  static const String assembling = '조립 중...';

  // Route Preview Screen
  static const String routePreview = '경로 미리보기';
  static const String noRouteGenerated = '생성된 경로가 없습니다';
  static const String regenerate = '다시 생성';
  static const String startRun = '러닝 시작';
  static const String distance = '거리';
  static const String estimatedTime = '예상 시간';
  static const String textPath = '텍스트 경로';
  static const String goBack = '뒤로가기';

  // Navigation Screen
  static const String km = 'km';
  static const String time = '시간';
  static const String pace = '페이스';
  static const String minPerKm = '분/km';
  static const String start = '시작';
  static const String pause = '일시정지';
  static const String resume = '재개';
  static const String stop = '정지';
  static const String runComplete = '러닝 완료!';
  static const String done = '확인';

  // Run History Screen
  static const String runHistoryTitle = '러닝 기록';
  static const String noRunsYet = '아직 기록이 없습니다';
  static const String noRunsSubtitle = '첫 러닝을 완료하면 여기에 표시됩니다!';
  static const String startARun = '러닝 시작하기';

  // Run Detail Screen
  static const String runDetail = '러닝 상세';
  static const String deleteRun = '기록 삭제';
  static const String deleteRunConfirm = '이 러닝 기록을 삭제하시겠습니까?';
  static const String cancel = '취소';
  static const String delete = '삭제';
  static const String runNotFound = '기록을 찾을 수 없습니다';

  // Map markers
  static const String startMarker = '출발';
  static const String endMarker = '도착';

  // Error messages
  static const String errorGeneric = '오류가 발생했습니다';
  static const String errorRouteGeneration = '경로 생성에 실패했습니다. 다시 시도해 주세요.';
  static const String errorApiFailure = '서버 연결에 실패했습니다. 네트워크 상태를 확인해 주세요.';
  static const String errorTimeout = '요청 시간이 초과되었습니다. 다시 시도해 주세요.';
  static const String errorNoText = '경로를 생성할 텍스트가 없습니다';
  static const String retry = '다시 시도';
  static const String errorLoadingHistory = '기록 불러오기 실패';
  static const String errorFontLoading = '폰트 로딩 오류';

  // Location errors
  static const String locationUnavailable = '위치를 사용할 수 없습니다';
  static const String locationServiceDisabled = '위치 서비스가 꺼져 있습니다';
  static const String locationServiceDisabledMessage =
      '위치 서비스를 켜야 현재 위치를 확인할 수 있습니다.\n기기 설정에서 위치 서비스를 활성화해 주세요.';
  static const String locationPermissionDenied = '위치 권한이 거부되었습니다';
  static const String locationPermissionDeniedMessage =
      '경로를 생성하려면 위치 권한이 필요합니다.\n앱 설정에서 위치 권한을 허용해 주세요.';
  static const String locationPermissionPermanentlyDenied = '위치 권한이 영구 거부되었습니다';
  static const String locationPermissionPermanentlyDeniedMessage =
      '위치 권한이 영구적으로 거부되었습니다.\n설정 > 앱 > Draw Running에서 위치 권한을 허용해 주세요.';
  static const String openSettings = '설정 열기';

  // Network errors
  static const String networkOffline = '인터넷에 연결되어 있지 않습니다';
  static const String networkOfflineMessage = '경로 생성을 위해 인터넷 연결이 필요합니다.\nWi-Fi 또는 모바일 데이터를 확인해 주세요.';

  // Weekdays
  static const List<String> weekdays = ['월', '화', '수', '목', '금', '토', '일'];
}
