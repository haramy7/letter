# 익명발신감정함 📮

> 오늘의 내가 나에게 보내는 편지

하루에 단 한 번, 나에게 감정 메시지를 보내고 **내일** 확인하는 감성 일기 앱입니다.

## 주요 기능

- 🔐 JWT 기반 인증 (Access Token + Refresh Token)
- ✅ Remember Me (로그인 유지)
- ✉️ 하루 1회 감정 편지 작성
- 🔒 작성한 편지는 다음 날 봉인 해제
- 📚 지난 편지 기록 열람
- 🗑️ 편지 삭제

## 기술 스택

### Backend
- Java 17
- Spring Boot 3.2.3
- Spring Security
- Spring Data JPA
- PostgreSQL
- JWT (jjwt 0.11.5)
- Lombok

### Frontend
- Flutter 3.x
- Dart
- Provider (상태관리)
- Dio (HTTP Client)
- Flutter Secure Storage

### Infra
- Docker & Docker Compose

## 프로젝트 구조
```
익명발신감정함/
├── backend/
│   ├── src/main/java/com/emotion/mailbox/
│   │   ├── core/
│   │   │   ├── AuthController.java
│   │   │   ├── LetterController.java
│   │   │   ├── MailboxService.java
│   │   │   ├── JwtProvider.java
│   │   │   ├── JwtFilter.java
│   │   │   ├── SecurityConfig.java
│   │   │   └── CustomUserDetailsService.java
│   │   ├── domain/
│   │   │   ├── User.java
│   │   │   ├── Letter.java
│   │   │   ├── UserRepository.java
│   │   │   └── LetterRepository.java
│   │   └── dto/
│   │       ├── AuthRequest.java
│   │       ├── AuthResponse.java
│   │       ├── LetterRequest.java
│   │       └── LetterDto.java
│   ├── build.gradle
│   ├── docker-compose.yml
│   └── application.yml
│
└── flutter_app/
    ├── lib/
    │   └── main.dart
    ├── assets/
    │   ├── fonts/
    │   └── images/
    └── pubspec.yaml
```

## 실행 방법

### 1. PostgreSQL 실행
```bash
cd backend
docker-compose up -d
```

### 2. Backend 실행
```bash
cd backend
./gradlew bootRun
```

### 3. Flutter 실행
```bash
cd flutter_app
flutter pub get
flutter run
```

## 📡 API 명세

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/auth/signup` | 회원가입 | ❌ |
| POST | `/auth/login` | 로그인 | ❌ |
| POST | `/auth/refresh` | 토큰 재발급 | ❌ |
| GET | `/api/letters` | 편지 목록 조회 | ✅ |
| GET | `/api/letters/today` | 오늘 작성 여부 | ✅ |
| POST | `/api/letters` | 편지 작성 | ✅ |
| DELETE | `/api/letters/{id}` | 편지 삭제 | ✅ |

## 📝 License

허태훈 License