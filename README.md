# 🧠 수학 게임 (Math Game Flutter)

모던하고 세련된 UI를 갖춘 다채로운 수학 퍼즐 게임 모음집입니다.

## 🎮 포함된 게임

### 1. 🏹 수식 양궁 (Math Archery)
- 주어진 숫자와 연산자를 조합하여 목표 숫자를 맞추는 지능형 퍼즐입니다.
- **특징**: 
  - 각 과녁마다 다른 점수 (1pt, 3pt, 10pt, 50pt) 부여
  - 'PASS' 기능 및 'Skip Round' 기능 제공 (각 1pt 감점)
  - 화려한 화살 발사 애니메이션

### 2. ⚡ 수식 암산 (Flash Mental)
- 화면에 빠르게 지나가는 숫자들을 기억하고 합계를 맞추는 게임입니다.
- **특징**:
  - 10문제 연속 도전 모드
  - 오답 시 즉시 종료되는 고난도 모드
  - 실시간 타이머 및 최고 기록 갱신

### 3. 🔢 사칙연산 퀴즈 (Square Quiz)
- 사각형 형태의 레이아웃에서 빠르게 사칙연산 문제를 푸는 게임입니다.
- **특징**:
  - 입체적인 파티클 효과와 타격감 있는 UI

### 4. 🔍 소수 찾기 (Prime Detector)
- 4x4 그리드에서 소수(Prime Number)를 찾아내는 게임입니다.
- **특징**:
  - 소수 분해 안내 메시지 제공
  - **4 스트라이크 제도**: 4번 틀릴 시 게임 종료

### 5. 팩토리얼 계산기 (Factorial Calculator)
- 큰 숫자의 팩토리얼을 계산하고 그 과정을 확인하는 도구입니다.

### 6. ⚖️ 크기 비교 (Sum Comparison)
- 양쪽 수식의 합 중 어느 쪽이 더 큰지 빠르게 판단하는 게임입니다.
- **특징**:
  - 공개 시간(Reveal Time) 중에도 빠른 선택 가능
  - 슬림하고 직관적인 타이머 바

## 🚀 주요 기능

- **포인트 시스템**: 모든 게임의 결과가 통합 포인트로 관리됩니다.
- **세션 기반 이력 관리**: 게임별로 한 세션의 총 합계가 포인트 내역에 깔끔하게 기록됩니다.
- **프리미엄 UI/UX**: 다크 모드 기반의 세련된 디자인, 부드러운 애니메이션, 직관적인 인터페이스를 제공합니다.
- **로컬 저장**: `SharedPreferences`를 사용하여 포인트와 내역이 기기에 안전하게 복구됩니다.

## 🛠 기술 스택

- **Framework**: Flutter
- **Language**: Dart
- **State Management**: Provider
- **Storage**: SharedPreferences

## 📝 설치 및 실행 방법

```bash
git clone https://github.com/joeyKor/math_game_flutter.git
cd math_game_flutter
flutter pub get
flutter run
```
