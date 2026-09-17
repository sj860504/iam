# iam

Apple Watch(watchOS) 앱 프로젝트입니다.

## 소개

`iam`은 Apple Watch용 앱을 탐색하는 저장소입니다. 현재 진행 방향은
**워치 오프라인 미디어 플레이어**로, 사용자가 권리를 가진 음악/영상 파일을 iPhone에서
워치로 옮겨 iPhone 없이 오프라인 재생하는 앱입니다. (초기에는 테슬라 차량 제어를 탐색했으나 보류)

> ⚠️ YouTube에서 영상/음악을 직접 다운로드하는 기능은 YouTube 약관 위반이자 App Store
> 심사 거절 대상이라 구현하지 않습니다. 이 앱은 사용자가 합법적으로 확보한 파일을 import 합니다.

## 문서

- [오프라인 미디어 플레이어 계획서 (docs/MEDIA_PLAYER_PLAN.md)](docs/MEDIA_PLAYER_PLAN.md) — **현재 진행 방향**
- [테슬라 제어 앱 계획서 (docs/PLAN.md)](docs/PLAN.md) — 초기 탐색(보류)
- [테슬라 Phase 0 조사 보고서 (docs/RESEARCH.md)](docs/RESEARCH.md) — 실현 가능성 조사 (2026-09-17)

## 현재 상태

두 가지 방향을 탐색했습니다.

1. **테슬라 전진/후진 제어(보류)** — 조사 결과 서드파티가 쓸 수 있는 Summon 명령이 공식·비공식 어디에도 없고,
   전진/후진은 EAP/FSD 라이선스가 차량 펌웨어에 잠겨 있어 API로 우회 불가. 자세한 내용은 [RESEARCH.md](docs/RESEARCH.md).
2. **Apple Watch 오프라인 미디어 플레이어(진행)** — 사용자가 권리를 가진 음악/영상 파일을 iPhone에서 워치로 옮겨
   오프라인 재생하는 앱. YouTube 직접 다운로드는 약관 위반이라 미구현. 계획은 [MEDIA_PLAYER_PLAN.md](docs/MEDIA_PLAYER_PLAN.md).

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
