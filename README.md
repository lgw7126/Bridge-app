# 🚕 안심 귀가 — Senior Mobility Bridge App

> "부모님은 버튼 하나만 누르세요. 나머지는 자녀가 합니다."

---

## 기획 의도

고령의 부모님이 늦은 밤 혼자 귀가해야 할 때, 스마트폰으로 직접 택시 앱을 조작하는 것은 쉽지 않습니다.  
작은 글씨, 복잡한 UI, 여러 단계의 입력 과정이 시니어에게 큰 장벽이 됩니다.

**안심 귀가**는 이 문제를 해결하기 위한 앱입니다.

- **부모님(시니어)** 은 큰 버튼 하나만 누릅니다 → 현재 위치가 자녀에게 전달됩니다.
- **자녀(보호자)** 는 알림을 받고 → 부모님의 위치를 확인한 뒤 → 대신 택시를 호출합니다.

타이핑 없이, 검색 없이, 복잡한 조작 없이. 버튼 하나로 끝납니다.

---

## 주요 기능

| 기능 | 설명 |
|------|------|
| **역할 선택** | 부모님 / 자녀 중 선택 |
| **6자리 코드 연결** | 부모님 폰에서 코드 생성 → 자녀가 입력 → 자동 연결 |
| **GPS 위치 전송** | 부모님이 버튼 누르면 현재 위치를 Firestore에 저장 |
| **실시간 알림** | 자녀 앱에 즉시 알림 도착 (앱 종료 시 FCM 푸시) |
| **주소 표시** | 카카오 API로 위도/경도 → 한국어 주소 변환 |
| **카카오맵 연동** | 버튼 하나로 카카오맵에서 부모님 위치 확인 |
| **주소 복사** | 클립보드 복사 → 카카오택시 등에 붙여넣기 |
| **처리 완료** | 자녀가 확인 완료 → 부모님 폰에 "자녀가 확인했어요" 표시 |

---

## 화면 구성

```
앱 실행
 │
 ├── [처음 실행] 역할 선택 화면
 │       ├── 나는 부모님입니다 (주황)
 │       └── 나는 자녀입니다   (파랑)
 │
 ├── [부모님 선택]
 │       ├── 6자리 코드 화면 → 자녀가 입력할 때까지 대기
 │       └── 부모님 홈 화면
 │               ├── 화면 50% 크기의 "택시 호출 요청" 버튼
 │               ├── 전송 완료 시간 표시
 │               └── "자녀가 확인했어요 🚕" 표시
 │
 └── [자녀 선택]
         ├── 6자리 코드 입력 화면
         └── 자녀 홈 화면
                 ├── 대기 중 화면
                 ├── 요청 수신 화면 (주소 + 카카오맵 + 복사 버튼)
                 └── 처리 완료 화면
```

---

## 기술 스택

| 구분 | 기술 |
|------|------|
| **프레임워크** | Flutter 3.32 (Dart 3.8) |
| **인증** | Firebase Anonymous Auth |
| **데이터베이스** | Cloud Firestore (실시간 구독) |
| **푸시 알림** | Firebase Cloud Messaging (FCM) |
| **위치** | geolocator (GPS 고정밀) |
| **주소 변환** | 카카오 로컬 API (무료) |
| **지도 연동** | url_launcher → kakaomap:// 딥링크 |
| **세션 유지** | shared_preferences |

---

## 구현 절차

### 1단계 — 프로젝트 초기 설정
- Flutter + Firebase 연동 (`firebase_core`, `firebase_auth`)
- 익명 로그인으로 별도 회원가입 없이 UID 발급
- SharedPreferences로 역할·UID·연결 상태 로컬 저장
- 앱 재실행 시 저장된 상태에 따라 화면 자동 복원

### 2단계 — 계정 연결 (6자리 코드)
- 부모님 앱: 중복 없는 6자리 랜덤 코드 생성 → Firestore `linking_codes` 컬렉션에 저장
- 자녀 앱: 코드 입력 → Firestore 조회 → 트랜잭션으로 양쪽 계정 동시 업데이트
- 실시간 리스너로 연결 완료 감지 → 자동으로 홈 화면 전환

### 3단계 — 부모님 홈 화면 (GPS 전송)
- 화면 세로 50% 크기의 대형 버튼 (시니어 친화 UI)
- 버튼 탭 → 위치 권한 확인 (한국어 커스텀 다이얼로그)
- `geolocator`로 고정밀 GPS 좌표 획득 → Firestore `requests` 컬렉션에 저장
- 자녀가 확인하면 "자녀가 확인했어요 🚕" 실시간 표시

### 4단계 — 자녀 홈 화면 (요청 수신)
- Firestore 실시간 리스너로 부모님 요청 즉시 수신
- 카카오 로컬 API로 위도/경도 → 한국어 주소 변환
- 카카오맵 딥링크(`kakaomap://`) 또는 웹 지도로 위치 확인
- "처리 완료" 버튼 → 부모님 앱에 확인 상태 전달

### 5단계 — FCM 푸시 알림
- `firebase_messaging`으로 앱 종료 시에도 알림 수신
- 자녀 FCM 토큰을 Firestore `users/{uid}.fcmToken`에 저장
- 부모님이 요청 전송 시 FCM 레거시 API로 자녀에게 푸시 발송
- 포어그라운드 알림은 SnackBar로 표시

---

## 프로젝트 구조

```
lib/
├── main.dart                          # 진입점 + 세션 복원 + FCM 백그라운드 핸들러
├── firebase_options.dart              # Firebase 설정값 (⚠️ flutterfire configure 필요)
├── config/
│   ├── app_config.dart                # API 키 설정 (카카오, FCM)
│   └── app_globals.dart               # 전역 ScaffoldMessengerKey
├── theme/
│   └── app_theme.dart                 # 시니어 친화 테마 (40px 폰트, 대형 버튼)
├── services/
│   ├── firestore_service.dart         # Firebase Auth + Firestore 모든 로직
│   ├── geocoding_service.dart         # 카카오 역지오코딩 (주소 변환)
│   └── notification_service.dart     # FCM 토큰 저장 + 푸시 전송
└── screens/
    ├── role_selection_screen.dart     # 역할 선택 (부모님 / 자녀)
    ├── parent/
    │   ├── parent_code_screen.dart    # 6자리 코드 표시 + 연결 대기
    │   └── parent_home_screen.dart    # 택시 호출 요청 버튼 화면
    └── child/
        ├── child_link_screen.dart     # 6자리 코드 입력
        └── child_home_screen.dart     # 요청 수신 + 주소 + 지도 연동
```

---

## Firestore 데이터 구조

```
linking_codes/{6자리코드}
  ├── parentUid      : string
  ├── childUid       : string | null
  ├── isLinked       : boolean
  ├── createdAt      : timestamp
  └── linkedAt       : timestamp | null

users/{uid}
  ├── role           : 'parent' | 'child'
  ├── linkCode       : string
  ├── linkedWithUid  : string | null
  ├── fcmToken       : string | null
  └── createdAt      : timestamp

requests/{parentUid}
  ├── parentUid      : string
  ├── linkedChildUid : string
  ├── latitude       : number
  ├── longitude      : number
  ├── accuracy       : number
  ├── status         : 'pending' | 'accepted'
  ├── timestamp      : timestamp
  └── acceptedAt     : timestamp | null
```

---

## 실행 방법

### 1. Firebase 프로젝트 생성
1. [Firebase 콘솔](https://console.firebase.google.com) → 새 프로젝트 생성
2. **Authentication** → 익명 로그인 활성화
3. **Firestore Database** → 테스트 모드로 생성
4. **Cloud Messaging** → 서버 키 복사

### 2. 설정 파일 채우기
```bash
# Firebase 자동 설정 (터미널에서 실행)
dart pub global activate flutterfire_cli
flutterfire configure
```

`lib/config/app_config.dart`에 키 입력:
```dart
static const String kakaoRestApiKey = '발급받은_카카오_키';   // 주소 변환용
static const String fcmServerKey    = '발급받은_FCM_서버_키'; // 푸시 알림용
```

### 3. 앱 실행
```bash
flutter pub get
flutter run
```

---

## 향후 개선 계획

- [ ] 앱 내 지도 SDK 연동 (google_maps_flutter 또는 네이버 지도)
- [ ] 요청 히스토리 화면 (과거 위치 전송 기록)
- [ ] 자녀 여러 명 연결 지원
- [ ] Cloud Functions로 FCM 서버 마이그레이션 (보안 강화)
- [ ] 카카오택시 / 타다 직접 연동
- [ ] 위치 전송 시 문자(SMS) 동시 발송

---

## 주의사항

- `lib/firebase_options.dart`는 Firebase 설정값을 담고 있어 `.gitignore`에 추가를 권장합니다.
- FCM 서버 키는 클라이언트 앱에 포함하는 것은 프로토타입 전용입니다. 실서비스에서는 반드시 Firebase Cloud Functions 또는 별도 백엔드 서버로 이전하세요.
