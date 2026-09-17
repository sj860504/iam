# 빌드 및 실행 가이드 (Phase 1 골격)

이 저장소에는 `.xcodeproj`가 커밋되어 있지 않습니다. 프로젝트 파일은
[XcodeGen](https://github.com/yonaskolb/XcodeGen)으로 `project.yml`에서 생성합니다.
소스와 설정만 버전 관리하므로 병합 충돌이 적습니다.

## 요구 사항

- macOS + Xcode 15 이상
- watchOS 10+ / iOS 17+ SDK
- XcodeGen (`brew install xcodegen`)

## 생성 & 실행

```bash
cd iam
xcodegen generate      # project.yml → iam.xcodeproj
open iam.xcodeproj
```

Xcode에서:
1. Scheme을 **iam Watch App**으로 선택
2. 페어링된 시뮬레이터(예: iPhone 15 + Apple Watch) 또는 실제 기기 선택
3. `Cmd + R` 실행

## 서명

- 두 타깃 모두 `Signing & Capabilities`에서 본인 팀(Team)을 선택하세요.
- 번들 ID는 `com.iam.app`(iOS) / `com.iam.app.watchkitapp`(watchOS)입니다.
  이미 사용 중이면 `project.yml`의 `PRODUCT_BUNDLE_IDENTIFIER`를 바꾼 뒤 재생성하세요.
  워치 번들 ID는 iOS 앱 ID로 시작해야 하고, watch Info.plist의
  `WKCompanionAppBundleIdentifier`도 iOS 번들 ID와 일치해야 합니다.

## 현재 동작 (Phase 1~3 골격)

- **iPhone(iam)**: 파일 앱에서 오디오 파일 가져오기(import) → 라이브러리 목록 →
  곡 탭 시 워치로 전송(`WCSession.transferFile`).
- **Apple Watch(iam Watch App)**: 전송받은 파일을 로컬 저장 → 목록 표시 →
  탭하면 오프라인 재생(`AVAudioPlayer`, 백그라운드 오디오, 블루투스 이어폰).

## 다음 단계

- 전송 진행률/재시도 UI, 저장공간 표시·정리
- 재생 위치 복원, 현재 곡 컴플리케이션
- (선택) 영상 재생 실험 — 배터리·저장공간 경고 포함

자세한 로드맵은 [MEDIA_PLAYER_PLAN.md](MEDIA_PLAYER_PLAN.md) 참고.
