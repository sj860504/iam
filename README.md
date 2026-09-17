# iam

Apple Watch(watchOS) 앱 프로젝트입니다.

## 소개

`iam`은 Apple Watch에서 **테슬라 차량을 제어**하는 watchOS 앱입니다.
차량 상태 확인, 잠금/해제 같은 기본 제어와 함께, 버튼을 누르고 있는 동안만 차량이
**전진 / 후진(Summon)** 하도록 하는 기능을 목표로 합니다.

> ⚠️ 차량을 원격으로 움직이는 기능은 안전에 직접 영향을 줍니다. 테슬라 공식 API는
> 전진/후진 명령을 제공하지 않으므로 해당 기능은 실험적이며 개인 사용 범위로 한정합니다.
> 자세한 실현 가능성 분석과 안전 설계는 [개발 계획서](docs/PLAN.md)를 참고하세요.

## 문서

- [개발 계획서 (docs/PLAN.md)](docs/PLAN.md) — 목표, 실현 가능성 분석, 아키텍처, 안전 설계, 단계별 일정
- [Phase 0 조사 보고서 (docs/RESEARCH.md)](docs/RESEARCH.md) — 테슬라 API 조사 결과와 Go/No-Go 판단 (2026-09-17)

## 현재 상태

Phase 0 조사 결과, 테슬라 공식·비공식 어느 경로에도 서드파티가 쓸 수 있는 전진/후진 명령이 없어
**Summon 기능(Track B)은 보류**되었습니다. 공식 API 기반 기본 제어(Track A)는 차별화 방향을 정한 뒤 진행 여부를 결정합니다.

## 기술 스택

- **플랫폼**: watchOS 10 이상
- **언어**: Swift 5.9 이상
- **UI**: SwiftUI
- **개발 도구**: Xcode 15 이상
- **주요 프레임워크**
  - WatchConnectivity (iPhone 컴패니언 앱 연동)
  - WidgetKit (배터리 컴플리케이션)
  - CoreBluetooth / CoreLocation (차량 근접 확인)
  - CryptoKit (Tesla Fleet API 명령 서명)
- **외부 연동**: Tesla Fleet API, `tesla/vehicle-command` HTTP 프록시

## 프로젝트 구조 (예정)

```
iam/
├── docs/
│   └── PLAN.md             # 개발 계획서
├── iam/                    # iOS 컴패니언 앱 (로그인, 토큰, 명령 중계)
├── iam Watch App/          # watchOS 앱 타깃
│   ├── iamApp.swift        # 앱 진입점
│   ├── Views/              # SwiftUI 화면 (홈, Summon 모드, 이동 중)
│   ├── Models/             # 데이터 모델, 이동 상태 머신
│   └── Assets.xcassets     # 이미지, 색상 등 리소스
├── iam Watch Widget/       # 컴플리케이션(WidgetKit) 타깃
├── proxy/                  # tesla-http-proxy 구성 (Docker)
└── iam.xcodeproj
```

## 시작하기

1. 저장소를 클론합니다.
   ```bash
   git clone https://github.com/sj860504/iam.git
   cd iam
   ```
2. Xcode에서 `iam.xcodeproj`를 엽니다.
3. 실행 대상(Scheme)을 **iam Watch App**으로 선택합니다.
4. Apple Watch 시뮬레이터 또는 페어링된 실제 기기를 선택하고 `Cmd + R`로 실행합니다.

## 개발 로드맵

- [x] Phase 0: 테슬라 API 조사 및 Go/No-Go 판단 → [RESEARCH.md](docs/RESEARCH.md)
- [ ] Phase 1: Xcode 프로젝트 골격, CI
- [ ] Phase 2: 로그인, 차량 상태 조회, 잠금/해제·경적·트렁크 제어
- [ ] Phase 3: Hold-to-Move, 데드맨 타이머 등 안전 인프라
- [ ] ~~Phase 4: 전진/후진(Summon) 실험 구현 및 실차 테스트~~ (보류)
- [ ] Phase 5: 마무리, App Store 심사 검토(기본 제어 기능만)

## 요구 사항

- macOS Sonoma 이상
- Xcode 15 이상
- Apple Developer 계정 (실기기 테스트 및 배포 시)

## 라이선스

라이선스는 추후 결정 예정입니다.
