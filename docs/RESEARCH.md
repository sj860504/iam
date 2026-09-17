# Phase 0 조사 보고서 — 테슬라 전진/후진 워치 제어 실현 가능성

> 작성일: 2026-09-17
> 대상: [개발 계획서](PLAN.md) Phase 0 "조사 및 검증" 항목
> 결론 요약: **Track B(전진/후진) = No-Go**, **Track A(공식 API 기본 제어) = 조건부 Go**

---

## 1. 한 줄 결론

테슬라가 서드파티에 공개한 어떤 경로(Fleet API, BLE Vehicle Command)에도 전진/후진(Summon) 명령은 존재하지 않으며,
과거 커뮤니티가 사용하던 비공식 스트리밍 채널은 2024년 4월 이후 테슬라가 단계적으로 차단해 **더 이상 안정적인 구현 경로가 없습니다.**
테슬라 자체 공식 Apple Watch 앱(2024년 12월 출시)도 워치에서는 Summon을 제공하지 않습니다.

---

## 2. 조사 항목별 결과

### 2.1 공식 Fleet API / Vehicle Command 프로토콜에 Summon이 있는가 → ❌ 없음

| 확인 대상 | 결과 |
|---|---|
| Fleet API `vehicle-commands` 엔드포인트 | 잠금/해제, 트렁크, 플래시, 경적, 공조, 충전, 미디어, 스케줄 등만 존재. summon/autopark 계열 없음 |
| `teslamotors/vehicle-command` `tesla-control` 명령 목록 (약 70개) | `drive` 명령이 있으나 의미는 **"Remote start vehicle"(원격 시동)** 이며 차량 이동이 아님. 그 외 이동 관련 명령 없음 |
| `car_server.proto` (서명 명령 프로토콜 정의) | `VehicleAction` oneof에 Summon/Autopark/Motion 관련 메시지 **없음** |
| GitHub 이슈 [#114 "Feature Request: Summon"](https://github.com/teslamotors/vehicle-command/issues/114) | 2023-12-23 개설, 2026-09 현재 **Open**, 테슬라 측 공식 답변 없음, 연결된 PR·마일스톤 없음 |

**해석**: 테슬라는 서드파티 명령 프로토콜을 설계하면서 차량 이동 명령을 의도적으로 배제했습니다. 약 2년 9개월간 요청이 방치된 점을 보면 단기간에 공개될 가능성은 낮습니다.

### 2.2 비공식 스트리밍 Summon 채널이 지금도 동작하는가 → ⚠️ 사실상 종료

커뮤니티(`teslams`, `timdorr/tesla-api`)가 분석한 프로토콜:

```
wss://{email}:{owner_api_token}@streaming.vn.teslamotors.com/connect/{vehicle_id}

→ {"msg_type":"autopark:cmd_forward","latitude":..,"longitude":..}
→ {"msg_type":"autopark:cmd_reverse","latitude":..,"longitude":..}
→ {"msg_type":"autopark:heartbeat_app","timestamp":..}
→ {"msg_type":"control:ping","timestamp":..}
← autopark_state / homelink_status / heartbeat
```

| 확인 대상 | 결과 |
|---|---|
| 인증 방식 | 비공식 **Owner API 토큰**을 Basic Auth로 URL에 삽입 |
| Owner API 현황 | 테슬라가 2024-03-26 "2024년 4월부터 미공개 API 단계적 폐지" 공지. 2024-05-20 일부 지역 실제 차단 확인. 미지원 API 사용 시 **Fleet API 접근 권한 회수** 경고 |
| 서드파티 앱 상태 | Tessie 등 주요 서드파티 앱은 2023년 12월부터 "테슬라가 서드파티 Summon을 더 이상 지원하지 않음"으로 안내 |
| `timdorr/tesla-api` 문서 | `autopark.md`가 제목 한 줄만 남은 **빈 문서** 상태 (내용 삭제됨) |
| 차량 측 지원 | USS(초음파 센서) 장착 구형 차량의 "Dumb Summon" 전용. 2022~2023년 이후 생산 차량은 USS 없음 |

**해석**: 토큰 확보 경로(Owner API)가 차단 중이고, 차단 시도 자체가 Fleet API 계정 제재 사유가 됩니다. 계획서에서 상정한 "Track B PoC"는 **수행하지 않는 것이 맞습니다.** 개인 계정으로 시도할 경우 공식 앱 이용까지 영향을 받을 수 있습니다.

### 2.3 차량 하드웨어/소프트웨어별 Summon 지원 현황 → 참고 정보

| 차량/조건 | Dumb Summon(전진/후진) | Actually Smart Summon(ASS) |
|---|---|---|
| USS 장착 구형 3/Y(~2022), S/X(~2023) | ✅ 앱에서 사용 가능 | HW3: 2024.27.20 이후 ✅ |
| USS 미장착 Tesla Vision 차량 | 2025.32.3부터 비전 기반으로 복원(2023+ 3/Y, 일부 2022, 신형 S/X) | 2024.27.20 이후 ✅ (HW4 → HW3 순차) |
| Cybertruck | 2026.21.6에서 ✅ | 2026.21.6에서 ✅ |
| 한국 | 스마트 서몬은 2026년 기준 국내 실사용 후기 존재. 규제상 일부 제한 가능 | 동일 |

**해석**: 차량 자체는 전진/후진 기능을 갖고 있고 한국에서도 사용 가능하나, **제어 인터페이스가 테슬라 공식 앱에만 열려 있는 것**이 문제입니다.

### 2.4 테슬라 공식 앱의 Apple Watch 지원 → 이미 존재, Summon은 없음

- 테슬라 앱 **4.39.5**(2024년 12월)부터 공식 Apple Watch 앱 제공. 요구사항: 차량 SW 2024.44.25+, watchOS 11+.
- 워치 기능: 배터리 상태, 잠금/해제, 공조(프리컨디셔닝), 트렁크, 충전 포트, 플래시, 경적, **워치 키**(Watch as Key), 컴플리케이션.
- **Summon / ASS는 워치에서 제공되지 않음.** 스마트폰 앱에서만 가능.
- 서드파티 워치 앱(Tessie, Stats for Tesla, Watch app for Tesla)도 Summon 없음. Tessie는 BLE 오프라인 제어·Auto Unlock까지 제공.

**해석**: 테슬라조차 안전상 이유로 워치 Summon을 넣지 않았습니다. Track A(기본 제어)만으로는 **공식 워치 앱과 기능이 겹쳐** 차별화가 어렵습니다.

### 2.5 Fleet API 이용 조건과 비용 → 개인 개발 가능, 소액 과금

| 항목 | 내용 |
|---|---|
| 개발자 등록 | developer.tesla.com 계정 → 앱 생성 → 허용 도메인/리다이렉트 설정 |
| 공개키 호스팅 | `https://{도메인}/.well-known/appspecific/com.tesla.3p.public-key.pem` (prime256v1) |
| 파트너 등록 | `POST /api/1/partner_accounts` (파트너 토큰 필요) |
| 가상 키 페어링 | 차주가 `https://tesla.com/_ak/{도메인}` 방문 → 테슬라 앱에서 승인 |
| 명령 서명 | 모든 차량 명령은 ECDSA 서명 필수 → `vehicle-command` HTTP 프록시(Go, Docker) 운영 필요 |
| 리전 | 한국은 Asia-Pacific → **NA 베이스 URL**(`fleet-api.prd.na.vn.cloud.tesla.com`) 사용. 토큰 교환은 2025-08부터 `fleet-auth.prd.vn.cloud.tesla.com` |
| 과금 | 2025년부터 종량제. 계정당 **월 $10 크레딧**. 명령·스트리밍은 저가, 차량 깨우기(wake) $1/50회, REST 상태 조회는 고가. 개인 1~2대는 크레딧 내 운용 가능 |
| 약관 | 미지원 API 사용 시 접근 권한 회수. 테슬라는 안전 관련 이벤트 통지·책임을 보장하지 않음 |

### 2.6 watchOS에서 테슬라 BLE 직접 제어 가능성 → 기술적으로 가능

- 오픈소스 [`acvigue/TesKey`](https://github.com/acvigue/TesKey): watchOS에서 CoreBluetooth + protobuf로 테슬라 Vehicle Command BLE 프로토콜 구현. 접근 시 자동 해제, 이탈 시 잠금, 원격 시동 동작.
- 즉 iPhone 없이 워치 단독 BLE 제어는 가능하나, **BLE 경로에도 Summon 명령은 없음**(2.1과 동일한 프로토콜).

---

## 3. Go / No-Go 판단

| 트랙 | 판단 | 근거 |
|---|---|---|
| **Track B: 전진/후진(Summon)** | **No-Go** | 공식 경로 없음. 비공식 경로는 차단 진행 중이며 시도 자체가 계정 제재 사유. 안전 책임 문제까지 고려 시 개인 프로젝트로 감당 불가 |
| **Track A: 공식 API 기본 제어** | **조건부 Go** | 구현 가능하고 비용도 낮음. 단, 테슬라 공식 워치 앱과 기능 중복 → "공식 앱이 못 하는 것"을 찾아야 의미 있음 |

---

## 4. 대안 검토

| 대안 | 설명 | 평가 |
|---|---|---|
| A. Track A만 진행 | 상태 조회 + 잠금/공조/트렁크 등. 공식 앱 대비 자동화(위치 기반 프리컨디셔닝, 충전 스케줄, 알림), 컴플리케이션 커스터마이즈로 차별화 | 실현 가능. 학습·포트폴리오 목적으로 적절 |
| B. 공식 API에 Summon이 열릴 때까지 대기 | 이슈 #114 구독, Fleet API 변경 로그 모니터링 | 비용 0. 단, 시점 불확실 |
| C. 현재 테슬라 앱의 Summon 프로토콜 재분석 | 앱 트래픽 리버스 엔지니어링 | **비추천**. 약관 위반, 계정 정지, 펌웨어 변경 시 즉시 무력화, 사고 시 전적 책임 |
| D. 워치 → iPhone 테슬라 앱 Summon 화면 바로가기 | 워치에서 딥링크로 폰의 Summon 화면을 여는 "런처" | 실제 제어는 아니지만 안전하고 합법. 사용자 경험 개선 효과는 제한적 |

**권장**: A + B 병행. 워치 앱은 공식 API 범위로 만들고, Summon은 테슬라가 공개하는 시점에 추가할 수 있도록 아키텍처(명령 추상화, Hold-to-Move UI·안전 상태 머신)만 준비합니다.

---

## 5. 계획서 반영 사항

- Phase 0 항목 중 "비공식 채널 PoC"는 **수행하지 않음**으로 종결 (계정 제재 및 약관 위반 리스크).
- Phase 4(Track B 실차 테스트)는 **보류**. 테슬라가 공식 Summon 명령을 공개하면 재개.
- Phase 2(Track A)는 차별화 기능 정의 후 진행 여부 결정.

## 6. 다음 액션 (사용자 결정 필요)

1. Track A 진행 여부와 차별화 방향 결정 (자동화 / 컴플리케이션 / BLE 오프라인 제어 등)
2. 진행 시: Tesla 개발자 계정 생성, 공개키 호스팅용 도메인 확보
3. 보유 차량 모델·연식·소프트웨어 버전 공유 → Fleet API 및 BLE 지원 여부 최종 확인

---

## 참고 자료

- Tesla vehicle-command 저장소: https://github.com/teslamotors/vehicle-command
- tesla-control 명령 목록: https://github.com/teslamotors/vehicle-command/blob/main/cmd/tesla-control/commands.go
- 서명 명령 프로토콜 정의: https://github.com/teslamotors/vehicle-command/blob/main/pkg/protocol/protobuf/car_server.proto
- Summon 기능 요청 이슈 #114: https://github.com/teslamotors/vehicle-command/issues/114
- 리전 등록 이슈 #176: https://github.com/teslamotors/vehicle-command/issues/176
- Fleet API 문서(명령): https://developer.tesla.com/docs/fleet-api/endpoints/vehicle-commands
- Fleet API 공지/변경 로그: https://developer.tesla.com/docs/fleet-api/announcements
- Fleet API 리전별 URL: https://developer.tesla.com/docs/fleet-api/getting-started/base-urls
- 비공식 Summon 웹소켓 구현(teslams PR #118): https://github.com/hjespers/teslams/pull/118/files
- 비공식 API 문서(timdorr): https://github.com/timdorr/tesla-api/tree/master/docs/vehicle
- Owner API 폐지 논의(TeslaMate #3792): https://github.com/teslamate-org/teslamate/discussions/3792
- Fleet API 과금 의견(TeslaMate #4408): https://github.com/teslamate-org/teslamate/discussions/4408
- Fleet API 종량제 설명(Teslemetry): https://teslemetry.com/blog/tesla-fleet-api-pay-per-use
- API 과금 뉴스(Not a Tesla App): https://www.notateslaapp.com/news/2415/tesla-announces-api-pricing-third-party-service-costs-expected-to-rise
- 공식 Apple Watch 앱 4.39.5: https://www.notateslaapp.com/tesla-app-updates/version/4.39.5/release-notes
- Apple Watch 지원 TMC 스레드: https://teslamotorsclub.com/tmc/threads/apple-watch-support-now-available-in-tesla-app-4-39-5.337798/
- Actually Smart Summon(HW3 포함): https://www.notateslaapp.com/news/2232/tesla-releases-actually-smart-summon-features-videos
- Tesla Vision 전환 안내: https://www.tesla.com/en_au/support/transitioning-tesla-vision
- Summon 사용 설명서(Model 3): https://www.tesla.com/ownersmanual/model3/en_us/GUID-7D207174-88CD-4795-8265-9162A72AA578.html
- 2026.21.6 업데이트(Cybertruck Summon): https://www.yeslak.com/blogs/tesla-news-insights/tesla-2026-21-6-update-fsd-14-1-lite-14-3-7-smart-summon
- 한국 스마트 서몬 실사용 후기: https://web.getcha.kr/blog/tesla-smart-summon-korea-review-2026
- Tessie Apple Watch: https://www.tessie.com/integrations/apple-watch
- Tessie Summon 안내: https://help.tessie.com/article/121-summon
- TesKey(watchOS BLE 오픈소스): https://github.com/acvigue/TesKey
- Fleet API 등록 가이드(Home Assistant): https://www.home-assistant.io/integrations/tesla_fleet/
- 서드파티 앱 접근 관리(Tesla): https://www.tesla.com/support/access-third-party-apps
