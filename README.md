# 안심 귀가 - Bridge App

시니어 모빌리티 브릿지 앱. 부모님(시니어)과 자녀(보호자)를 6자리 코드로 연결합니다.

## 프로젝트 구조

```
lib/
├── main.dart                        # 앱 진입점 + 세션 복원 라우팅
├── firebase_options.dart            # Firebase 설정 (⚠️ 직접 입력 필요)
├── theme/
│   └── app_theme.dart               # 시니어 친화적 테마 (대형 텍스트/버튼)
├── services/
│   └── firestore_service.dart       # Firebase Auth + Firestore 로직
└── screens/
    ├── role_selection_screen.dart   # 첫 화면: 역할 선택
    ├── parent/
    │   ├── parent_code_screen.dart  # 6자리 코드 표시 + 연결 대기
    │   └── parent_home_screen.dart  # 연결 완료 화면 (부모)
    └── child/
        ├── child_link_screen.dart   # 6자리 코드 입력
        └── child_home_screen.dart   # 연결 완료 화면 (자녀)
```

## Firestore 데이터 구조

```
linking_codes/{6자리코드}
  ├── parentUid: string
  ├── createdAt: timestamp
  ├── isLinked: boolean
  ├── childUid: string | null
  └── linkedAt: timestamp | null

users/{uid}
  ├── role: 'parent' | 'child'
  ├── linkCode: string
  ├── linkedWithUid: string | null
  └── createdAt: timestamp
```

## Firebase 설정 방법

### 1. Firebase 프로젝트 생성
1. [Firebase 콘솔](https://console.firebase.google.com) 에서 새 프로젝트 생성
2. Android 앱 추가 (패키지명: `com.bridgeapp.bridgeApp`)
3. iOS 앱 추가 (번들 ID: `com.bridgeapp.bridgeApp`)

### 2. Firebase 서비스 활성화
- **Authentication** → 로그인 방법 → 익명 로그인 사용 설정
- **Firestore Database** → 데이터베이스 만들기 (프로덕션 모드)

### 3. Firestore 보안 규칙
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /linking_codes/{code} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.auth.uid == request.resource.data.parentUid;
      allow update: if request.auth != null;
    }
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
      allow update: if request.auth != null;
    }
  }
}
```

### 4. firebase_options.dart 자동 생성 (권장)
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=YOUR_PROJECT_ID
```

또는 `lib/firebase_options.dart` 파일의 `TODO` 주석 부분을 직접 수정하세요.

## 앱 화면 흐름

```
시작
 ├── [부모님] → 6자리 코드 생성 → Firestore 저장 → 코드 화면 대기
 │                                                    ↓ (자녀가 코드 입력 시 자동 전환)
 │                                              부모 홈 화면 ✅
 │
 └── [자녀] → 6자리 코드 입력 → Firestore 조회 → 연결 트랜잭션
                                                    ↓ 성공
                                              자녀 홈 화면 ✅
```

## 실행

```bash
flutter pub get
flutter run
```
