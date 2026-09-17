# iam — 테슬라 전진/후진 워치 제어 앱 개발 계획

> Apple Watch에서 테슬라 차량의 **전진 / 후진(Summon)** 을 실행하는 watchOS 앱을 만들기 위한 계획서입니다.
> 차량을 원격으로 움직이는 기능은 안전에 직접 영향을 주므로, 이 문서는 기능 구현보다 **안전 설계와 실현 가능성 검증**을 우선합니다.

---

## 1. 목표

| 구분 | 내용 |
|---|---|
| 핵심 목표 | 워치 화면에서 버튼을 **누르고 있는 동안만** 차량이 전진 또는 후진하고, 손을 떼면 즉시 정지 |
| 부가 목표 | 차량 상태 조회(잠금, 배터리, 위치), 잠금/해제, 경적, 트렁크 등 기본 제어 |
| 비목표 | Smart Summon(자율 호출), 경로 주행, 자동 주차 등 고급 자율 기능 |
| 성공 기준 | 워치 조작 → 차량 반응 지연 1초 이내, 버튼 해제 → 정지 지연 0.5초 이내, 통신 단절 시 자동 정지 |

---

## 2. 배경 및 실현 가능성 분석

### 2.1 테슬라가 제공하는 제어 경로

| 경로 | 공식 여부 | 전진/후진 지원 | 비고 |
|---|---|---|---|
| **Fleet API** (REST + Vehicle Command Protocol) | 공식 | ❌ 미지원 | 잠금/해제, 공조, 트렁크, 충전 등만 제공. Summon 계열 명령은 공개되지 않음. 개발자 등록·OAuth·가상 키(Virtual Key) 등록 필요. 2025년부터 유료 크레딧 과금. |
| **BLE Vehicle Command** (`tesla/vehicle-command`) | 공식(오픈소스) | ❌ 미지원 | 폰 키 기반 근거리 명령. 잠금/트렁크/공조 등. Summon 명령 없음. |
| **Streaming WebSocket** `autopark_forward` / `autopark_reverse` / `autopark_abort` | 비공식(리버스 엔지니어링) | ⚠️ 구형 차량 일부 | 커뮤니티가 분석한 구 Owner API 스트리밍 채널. USS(초음파 센서) 장착 차량에서만 동작 보고. 언제든 차단될 수 있고 약관 위반 소지. |
| **테슬라 공식 앱 Summon** | 공식(사용자 기능) | ✅ | 앱 내부 전용 프로토콜. 폰이 차량 근처(약 6m)에 있어야 하며, 서드파티에 열려 있지 않음. |

### 2.2 결론

- **공식 API만으로는 전진/후진을 구현할 수 없습니다.** 이는 기술 부족이 아니라 테슬라의 정책이며, 안전 책임 문제 때문에 앞으로도 공개될 가능성이 낮습니다.
- 따라서 이 프로젝트는 두 갈래로 설계합니다.
  1. **Track A(공식)**: Fleet API 기반 상태 조회 + 기본 제어 → 앱의 뼈대이자 출시 가능한 결과물
  2. **Track B(실험)**: 비공식 Summon 채널을 이용한 전진/후진 → 개인 차량 대상 실험 기능, 배포 금지, 기능 플래그로 분리
- Track B는 **App Store 심사 통과가 불가능**하다고 가정하고, 개인용 사이드로딩(Xcode 직접 설치) 범위로 한정합니다.

### 2.3 법적·약관 검토 항목 (착수 전 확인)

- [ ] Tesla Fleet API 이용약관에서 금지하는 행위 범위 확인
- [ ] 비공식 API 사용 시 차량 보증·보험 영향 확인
- [ ] 원격 차량 이동 사고 시 책임 소재(개인 사용 한정 명시)
- [ ] 한국 도로교통법상 원격 조작 관련 규정 확인

---

## 3. 시스템 아키텍처

```
┌────────────────────┐        ┌─────────────────────┐        ┌───────────────┐
│  Apple Watch       │  HTTPS │  Companion / Proxy  │  HTTPS │  Tesla Cloud  │
│  (watchOS App)     │◀──────▶│  (iPhone 또는 서버)  │◀──────▶│  Fleet API    │
│                    │  WCSession│                    │  WSS   │  Streaming    │
│  - Hold-to-Move UI │        │  - OAuth 토큰 관리   │        │               │
│  - Haptic 피드백   │        │  - 명령 서명(Virtual │        └───────┬───────┘
│  - Watchdog 타이머 │        │    Key, ECDSA)       │                │
│  - 상태 표시       │        │  - Summon 세션 유지  │                ▼
└────────────────────┘        │  - 데드맨 스위치     │        ┌───────────────┐
                              └─────────────────────┘        │  Tesla 차량   │
                                                             └───────────────┘
```

### 3.1 구성 요소

| 구성 요소 | 역할 | 기술 |
|---|---|---|
| **watchOS 앱** | 사용자 조작, 즉각 피드백, 안전 타이머 | SwiftUI, WatchKit, WatchConnectivity, CoreHaptics |
| **iPhone 컴패니언 앱** | 로그인/토큰 저장, 명령 중계, 차량 근접 확인(BLE/GPS) | SwiftUI, Keychain, CoreBluetooth, CoreLocation |
| **명령 프록시(선택)** | Fleet API 명령 서명 및 릴레이. 테슬라가 요구하는 `vehicle-command` HTTP 프록시 | Go(`tesla-http-proxy`) 또는 Swift 서버, Docker |
| **Fleet API 클라이언트** | 차량 목록, 상태, 기본 명령 | REST, OAuth 2.0 PKCE |
| **Summon 클라이언트(Track B)** | 스트리밍 WebSocket 연결, `autopark_*` 메시지 송신 | URLSessionWebSocketTask |

### 3.2 왜 워치 단독이 아니라 iPhone을 거치는가

- Fleet API 명령은 **Virtual Key로 서명**해야 하며, 개인 키를 워치에만 두는 것은 관리·보안상 불리합니다.
- Summon은 차량 근접 조건이 필요하고, iPhone의 BLE·GPS가 이를 더 안정적으로 판단합니다.
- 통신이 iPhone에서 끊기면 프록시 단에서 즉시 `abort`를 보낼 수 있어 **이중 안전장치**가 됩니다.
- 단, iPhone 없이도 상태 조회 정도는 가능하도록 워치 단독 네트워크 경로(Wi-Fi/셀룰러)를 fallback으로 둡니다.

---

## 4. 안전 설계 (최우선)

차량을 움직이는 기능이므로 아래 항목은 **구현 필수**이며 하나라도 미충족 시 Track B 기능을 활성화하지 않습니다.

| # | 안전장치 | 설명 |
|---|---|---|
| S1 | **Hold-to-Move** | 버튼을 누르고 있는 동안만 이동. `onLongPressGesture`가 아닌 `DragGesture(minimumDistance: 0)`로 press/release를 직접 추적 |
| S2 | **데드맨 타이머** | 워치 → 폰 → 차량 각 구간에 300ms 주기 heartbeat. 1초 이상 끊기면 자동 `abort` |
| S3 | **화면 이탈 시 정지** | 손목 내리기, 앱 백그라운드 전환, 알림 오버레이 등 `scenePhase` 변화 즉시 정지 |
| S4 | **2단계 활성화** | 전진/후진 화면 진입 전 Digital Crown 회전 또는 확인 버튼으로 "Summon 모드" 명시적 진입 |
| S5 | **근접 조건** | iPhone이 차량과 BLE 연결 상태이거나 GPS 거리 10m 이내일 때만 활성화 |
| S6 | **차량 상태 사전 점검** | 기어 P, 문·트렁크 닫힘, 탑승자 없음(좌석 센서), 충전 케이블 미연결 확인 |
| S7 | **최대 이동 시간** | 연속 이동 10초 제한 후 자동 정지, 재시작은 버튼 재입력 |
| S8 | **긴급 정지** | 화면 어디든 두 번 탭 또는 Crown 누르기로 즉시 `abort` |
| S9 | **햅틱 피드백** | 이동 중 주기적 진동, 정지 시 강한 진동으로 상태 인지 |
| S10 | **로그 기록** | 모든 이동 명령·정지 사유를 타임스탬프와 함께 로컬 저장 |

---

## 5. 단계별 개발 계획

### Phase 0 — 조사 및 검증 (1~2주) — ✅ 2026-09-17 조사 완료 → [RESEARCH.md](RESEARCH.md)
- [ ] Tesla 개발자 계정 등록, Fleet API 앱 생성, 도메인·공개키 호스팅 (Track A 진행 결정 후)
- [ ] 보유 차량 모델·소프트웨어 버전 확인 (사용자 정보 필요)
- [x] ~~비공식 `autopark_forward/reverse` 채널 PoC~~ → **수행하지 않음.** Owner API 차단 진행 중, 시도 시 Fleet API 계정 제재 사유
- [x] 법적·약관 검토: 미지원 API 사용 시 접근 권한 회수, 안전 이벤트 무보장 확인
- **판단 결과**: **Track B No-Go.** 공식·비공식 어느 경로에도 전진/후진 명령 없음. Track A는 차별화 방향 결정 후 조건부 진행

### Phase 1 — 프로젝트 골격 (1주)
- [ ] Xcode 프로젝트 생성: `iam` (iOS) + `iam Watch App` (watchOS)
- [ ] 폴더 구조, SwiftLint, 기능 플래그(`FeatureFlags.summonEnabled`) 도입
- [ ] WatchConnectivity 메시지 프로토콜 정의(Codable 기반)
- [ ] CI: GitHub Actions에서 빌드·단위 테스트

### Phase 2 — Track A: 인증 및 기본 제어 (2~3주)
- [ ] OAuth 2.0 PKCE 로그인(iPhone), 토큰 Keychain 저장 및 갱신
- [ ] 차량 목록·상태 조회, 워치에 배터리/잠금/위치 표시
- [ ] `tesla-http-proxy` 구성 및 Virtual Key 차량 등록
- [ ] 잠금/해제, 경적, 플래시, 트렁크 명령 워치에서 실행
- [ ] 컴플리케이션: 배터리 잔량 표시

### Phase 3 — 안전 인프라 (2주)
- [ ] S1~S10 안전장치 구현 및 단위 테스트(타이머, 상태 머신)
- [ ] 이동 상태 머신: `idle → armed → moving(forward|reverse) → stopping → idle`
- [ ] 통신 단절 시뮬레이션 테스트(비행기 모드, 앱 강제 종료)
- [ ] 안전장치는 **차량 없이** Mock 백엔드로 100% 검증

### Phase 4 — Track B: 전진/후진 실험 구현 (2~3주) — ⏸ 보류 (Phase 0 결과, 공식 Summon 명령 공개 시 재개)
- [ ] 스트리밍 WebSocket 연결 및 Summon 세션 핸드셰이크
- [ ] `autopark_forward` / `autopark_reverse` / `autopark_abort` 송신
- [ ] Hold-to-Move UI와 heartbeat 연결
- [ ] **실차 테스트**: 넓은 개인 공간, 장애물 없음, 보조자 1명 동석, 물리 키 소지
- [ ] 반응 지연·정지 지연 측정 및 성공 기준 검증

### Phase 5 — 마무리 (1주)
- [ ] 로그 뷰어, 오류 처리, 접근성(VoiceOver)
- [ ] Track A 기능만 포함한 빌드로 App Store 심사 검토
- [ ] Track B는 개인용 빌드로 유지, README에 경고 명시

---

## 6. 화면 설계 (워치)

```
[홈]                    [Summon 모드]             [이동 중]
┌──────────────┐        ┌──────────────┐        ┌──────────────┐
│ Model 3  🔒  │        │  ⚠ 주변 확인  │        │   ▲ 전진 중   │
│ 🔋 72%  📍 8m│        │              │        │  ●●●●○○○○○○  │
│              │  ───▶  │  [ ▲ 전진 ]  │  ───▶  │              │
│ [잠금해제]    │ Crown  │  [ ▼ 후진 ]  │ hold   │  손을 떼면 정지│
│ [Summon ▶]   │        │   (꾹 누르기) │        │ [■ 긴급정지]  │
└──────────────┘        └──────────────┘        └──────────────┘
```

---

## 7. 기술 스택

| 영역 | 선택 |
|---|---|
| 언어 | Swift 5.9+ |
| UI | SwiftUI (watchOS 10+, iOS 17+) |
| 통신 | URLSession, URLSessionWebSocketTask, WatchConnectivity |
| 보안 | Keychain, CryptoKit(ECDSA P-256 명령 서명) |
| 위치/근접 | CoreLocation, CoreBluetooth |
| 프록시 | `tesla/vehicle-command` HTTP proxy (Go), Docker |
| 테스트 | XCTest, Mock 서버(Swift `Vapor` 또는 Python) |
| CI | GitHub Actions (`xcodebuild test`) |

---

## 8. 리스크

| 리스크 | 영향 | 대응 |
|---|---|---|
| 비공식 Summon 채널 차단 | Track B 전체 무력화 | Track A를 독립적으로 완성. Track B는 기능 플래그로 격리 |
| 펌웨어 업데이트로 프로토콜 변경 | 동작 불가·오동작 | 버전 고정 확인 후에만 활성화, 실패 시 즉시 abort |
| 통신 지연으로 정지 늦음 | 안전사고 | 데드맨 타이머, 최대 이동 시간, 근접 조건 |
| Fleet API 과금 | 운영 비용 | 폴링 최소화, 캐시, 웹훅 대신 필요 시 조회 |
| App Store 심사 거절 | 배포 불가 | Track A만 제출, Track B는 개인 빌드 |
| 계정 제재 | 차량 앱 사용 불가 | 개발용 별도 계정·차량 사용 검토, 약관 준수 |

---

## 9. 일정 요약

| Phase | 기간 | 산출물 |
|---|---|---|
| 0 조사·검증 | 1~2주 | 실현 가능성 보고, Go/No-Go 결정 |
| 1 골격 | 1주 | 빌드되는 Xcode 프로젝트, CI |
| 2 Track A | 2~3주 | 로그인·상태·기본 제어 동작 |
| 3 안전 인프라 | 2주 | 상태 머신·타이머 테스트 통과 |
| 4 Track B | 2~3주 | 실차 전진/후진 데모(개인용) |
| 5 마무리 | 1주 | 문서, 심사 제출 검토 |
| **합계** | **약 9~12주** | |

---

## 10. 다음 액션

1. Tesla 개발자 포털에서 앱 등록 및 Fleet API 접근 확인
2. 보유 차량의 Summon 지원 여부(USS 장착·펌웨어 버전) 확인
3. PC에서 비공식 `autopark_*` PoC 수행 → Track B Go/No-Go
4. Phase 1 Xcode 프로젝트 생성
