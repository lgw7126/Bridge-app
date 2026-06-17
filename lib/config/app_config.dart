class AppConfig {
  // 카카오 REST API 키 — 주소 변환(역지오코딩)에 사용됩니다.
  // 발급 방법 (무료, 카드 불필요, 약 5분 소요):
  //   1. https://developers.kakao.com 에서 카카오 계정으로 로그인
  //   2. [내 애플리케이션] → [애플리케이션 추가하기]
  //   3. 앱 이름 입력 후 저장 → [앱 키] 탭에서 REST API 키 복사
  //   4. 아래 'YOUR_KAKAO_REST_API_KEY' 자리에 붙여넣기
  static const String kakaoRestApiKey = 'YOUR_KAKAO_REST_API_KEY';

  static bool get hasKakaoKey =>
      kakaoRestApiKey != 'YOUR_KAKAO_REST_API_KEY' &&
      kakaoRestApiKey.isNotEmpty;
}
