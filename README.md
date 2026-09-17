# iam

Apple Watch(watchOS) 앱 프로젝트입니다.

## 소개

`iam`은 Apple Watch에서 동작하는 독립형(standalone) watchOS 앱입니다.
손목 위에서 빠르게 확인하고 조작할 수 있는 가볍고 직관적인 경험을 목표로 합니다.

## 기술 스택

- **플랫폼**: watchOS 10 이상
- **언어**: Swift 5.9 이상
- **UI**: SwiftUI
- **개발 도구**: Xcode 15 이상
- **주요 프레임워크**
  - WidgetKit (컴플리케이션)
  - HealthKit (건강 데이터 연동, 필요 시)
  - WatchConnectivity (iPhone 연동, 필요 시)

## 프로젝트 구조 (예정)

```
iam/
├── iam Watch App/          # watchOS 앱 타깃
│   ├── iamApp.swift        # 앱 진입점
│   ├── Views/              # SwiftUI 화면
│   ├── Models/             # 데이터 모델
│   └── Assets.xcassets     # 이미지, 색상 등 리소스
├── iam Watch Widget/       # 컴플리케이션(WidgetKit) 타깃
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

- [ ] Xcode 프로젝트 생성 및 기본 화면 구성
- [ ] 핵심 기능 구현
- [ ] 컴플리케이션 지원
- [ ] iPhone 컴패니언 앱 연동 검토
- [ ] App Store 출시 준비

## 요구 사항

- macOS Sonoma 이상
- Xcode 15 이상
- Apple Developer 계정 (실기기 테스트 및 배포 시)

## 라이선스

라이선스는 추후 결정 예정입니다.
