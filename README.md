# 🚕 안심 귀가 — Senior Mobility Bridge App

> **부모님은 버튼 하나만 누르세요. 나머지는 자녀가 합니다.**

[![APK 빌드 상태](https://github.com/lgw7126/Bridge-app/actions/workflows/build-apk.yml/badge.svg)](https://github.com/lgw7126/Bridge-app/actions/workflows/build-apk.yml)

### 📲 앱 다운로드 (APK)
👉 **[여기 클릭 → Actions 탭 → 최신 빌드 → debug-apk 다운로드](https://github.com/lgw7126/Bridge-app/actions/workflows/build-apk.yml)**

> ⚠️ 앱을 실행하려면 Firebase 설정이 필요합니다. 아래 "처음 실행하는 방법"을 먼저 읽어주세요.

---

## 이 앱은 무엇인가요?

고령의 부모님이 혼자 귀가할 때 택시 앱 조작이 어렵다는 문제에서 출발했습니다.

**안심 귀가**는 이렇게 작동합니다:

```
① 부모님이 큰 버튼 하나를 누릅니다
       ↓
② 부모님의 현재 위치가 자녀 폰으로 전달됩니다
       ↓
③ 자녀가 위치를 확인하고 택시를 대신 불러드립니다
```

타이핑 없이, 검색 없이, 버튼 하나로 끝납니다.

---

## 주요 기능

| 기능 | 설명 |
|------|------|
| 🔗 **6자리 코드 연결** | 부모님-자녀 계정을 숫자 코드로 1회 연결 |
| 📍 **GPS 위치 전송** | 버튼 하나로 현재 위치 즉시 전달 |
| 🔔 **푸시 알림** | 앱이 꺼져 있어도 자녀에게 알림 전송 |
| 🗺️ **카카오맵 연동** | 부모님 위치를 지도에서 바로 확인 |
| 📋 **주소 복사** | 택시 앱에 붙여넣기용 주소 한 번에 복사 |
| ✅ **처리 완료 알림** | 자녀가 확인하면 부모님 폰에 표시 |

---

## 앱 화면 흐름

```
앱 실행
 │
 ├── 부모님 선택
 │     ├── 6자리 코드 화면 (자녀에게 알려주기)
 │     └── 홈 화면: 화면 절반 크기의 "택시 호출 요청" 버튼
 │
 └── 자녀 선택
       ├── 코드 입력 화면 (부모님 코드 입력)
       └── 홈 화면: 요청 수신 → 주소 확인 → 카카오맵 → 처리완료
```

---

## 💻 처음 실행하는 방법 (Windows, 왕초보용)

### 준비물
- Windows 노트북
- 안드로이드 폰 + USB 케이블
- Google 계정

---

### STEP 1 — 필요한 프로그램 설치하기

#### 1-1. Git 설치
1. 구글에서 **"git windows 다운로드"** 검색
2. [git-scm.com](https://git-scm.com) 접속 → **Download for Windows** 클릭
3. 다운로드된 파일 실행 → 계속 Next 클릭 → 설치 완료

#### 1-2. Flutter 설치
1. 구글에서 **"flutter windows 설치"** 검색 또는 [flutter.dev](https://flutter.dev/docs/get-started/install/windows) 접속
2. **flutter_windows_3.x.x-stable.zip** 다운로드
3. `C:\flutter` 폴더 만들고 그 안에 압축 해제
4. Windows 검색창에 **"시스템 환경 변수"** 검색 → **환경 변수 편집** 클릭
5. 아래쪽 **"시스템 변수"** 에서 **Path** 선택 → **편집** → **새로 만들기** → `C:\flutter\bin` 입력 → 확인

#### 1-3. Android Studio 설치
1. 구글에서 **"Android Studio 다운로드"** 검색
2. [developer.android.com/studio](https://developer.android.com/studio) → **Download Android Studio** 클릭
3. 설치 실행 → 기본값으로 계속 Next → 설치 완료
4. Android Studio 실행 → **More Actions** → **SDK Manager** → **Android 14 (API 34)** 체크 → Apply

#### 1-4. VS Code 설치 (코드 편집기)
1. 구글에서 **"VS Code 다운로드"** 검색
2. [code.visualstudio.com](https://code.visualstudio.com) → Download 클릭 → 설치
3. VS Code 실행 → 왼쪽 블록 아이콘(확장) 클릭 → **Flutter** 검색 → 설치

---

### STEP 2 — Firebase 프로젝트 만들기

1. [console.firebase.google.com](https://console.firebase.google.com) 접속 (Google 계정으로 로그인)
2. **"프로젝트 추가"** 클릭 → 이름 입력 (예: `bridge-app`) → 계속 → 완료
3. 왼쪽 메뉴 **Authentication** → **시작하기** → **익명** → **사용 설정** → 저장
4. 왼쪽 메뉴 **Firestore Database** → **데이터베이스 만들기** → **테스트 모드** → **다음** → **완료**
5. 왼쪽 메뉴 **Cloud Messaging** → **서버 키** 복사해두기 (나중에 필요)

---

### STEP 3 — 앱 코드 다운로드하기

1. Windows 검색창에 **"cmd"** 입력 → 명령 프롬프트 실행
2. 아래 명령어 3줄을 순서대로 입력 (각 줄 입력 후 Enter):

```
cd C:\
git clone https://github.com/lgw7126/Bridge-app.git
cd Bridge-app
```

---

### STEP 4 — Firebase 연결하기

명령 프롬프트에서 순서대로 입력:

```
dart pub global activate flutterfire_cli
```
```
flutterfire configure
```

실행하면 Firebase 프로젝트 목록이 나와요 → 방금 만든 프로젝트 선택 → Enter  
→ `lib/firebase_options.dart` 파일이 자동으로 완성됩니다 ✅

---

### STEP 5 — 폰 연결하기

**폰에서 개발자 모드 켜기:**
1. 설정 앱 열기
2. **"휴대전화 정보"** 또는 **"기기 정보"** 탭
3. **"소프트웨어 정보"** → **"빌드 번호"** 를 **7번** 연속으로 탭
4. 설정으로 돌아가면 **"개발자 옵션"** 메뉴가 생겨 있음
5. **개발자 옵션** → **USB 디버깅** 켜기

**USB로 연결:**
1. USB 케이블로 폰과 노트북 연결
2. 폰 화면에 **"USB 디버깅을 허용하시겠습니까?"** 팝업 → **허용** 탭

---

### STEP 6 — 앱 실행하기

명령 프롬프트에서:

```
flutter pub get
flutter run
```

잠시 기다리면 폰에 앱이 자동으로 설치되고 실행됩니다! 🎉

---

### 문제 해결

| 문제 | 해결방법 |
|------|----------|
| `flutter` 명령어를 모른다고 나옴 | STEP 1-2의 환경 변수 설정 다시 확인 |
| 폰이 인식 안 됨 | USB 케이블 교체 또는 폰 드라이버 설치 |
| 앱 실행 시 흰 화면에서 멈춤 | Firebase 연결(STEP 4) 다시 확인 |

---

## 기술 스택

| 구분 | 기술 |
|------|------|
| 프레임워크 | Flutter 3.32 (Dart 3.8) |
| 인증 | Firebase Anonymous Auth |
| 데이터베이스 | Cloud Firestore |
| 푸시 알림 | Firebase Cloud Messaging (FCM) |
| 위치 | geolocator |
| 주소 변환 | 카카오 로컬 API |
| 지도 연동 | 카카오맵 딥링크 |

---

## API 키 설정 (선택사항)

`lib/config/app_config.dart` 파일을 열어서 입력:

```dart
static const String kakaoRestApiKey = '발급받은_카카오_키';  // 한국어 주소 표시용
static const String fcmServerKey    = '발급받은_FCM_서버_키'; // 푸시 알림용
```

키 없이도 앱은 실행됩니다 (주소 대신 좌표 표시, 알림 미전송).

---

## 프로젝트 구조

```
lib/
├── main.dart                       # 진입점
├── config/
│   ├── app_config.dart             # API 키 설정
│   └── app_globals.dart            # 전역 상태
├── services/
│   ├── firestore_service.dart      # Firebase 로직
│   ├── geocoding_service.dart      # 주소 변환
│   └── notification_service.dart  # 푸시 알림
├── theme/
│   └── app_theme.dart              # 시니어 친화 테마
└── screens/
    ├── role_selection_screen.dart  # 역할 선택
    ├── parent/                     # 부모님 화면
    └── child/                      # 자녀 화면
```

---

## 향후 계획

- [ ] 앱 내 지도 (카카오맵 SDK)
- [ ] 요청 히스토리
- [ ] 자녀 여러 명 연결
- [ ] 카카오택시 직접 연동
- [ ] Play Store 출시
