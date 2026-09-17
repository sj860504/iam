# iam — Apple Watch 오프라인 미디어 플레이어 개발 계획

> 목표: Apple Watch에 음악·영상을 넣어 **iPhone 없이 오프라인 재생**하는 앱.
> 사용자 요청은 "YouTube 음악/영상을 다운로드해 워치에 넣는 앱"이었으나, 조사 결과 **YouTube 다운로드 부분은 구현할 수 없습니다.**
> 대신 합법적으로 만들 수 있는 **오프라인 미디어 플레이어**로 범위를 잡고, YouTube 관련 제약을 아래에 명시합니다.

---

## 1. 먼저: 무엇이 되고 무엇이 안 되는가

| 요소 | 가능 여부 | 근거 |
|---|---|---|
| **워치에 오디오 파일을 넣어 오프라인 재생** | ✅ 가능 | WristPlayer, Player for Watch 등 실제 앱이 존재. watchOS가 로컬 오디오 저장·재생 지원 |
| **워치에서 영상 재생** | ⚠️ 제한적 가능 | 네이티브 영상 전송/플레이어 없음. 서드파티 앱이 구현하나 저장공간·배터리 부담 큼 (1시간 재생에 배터리 상당 소모) |
| **YouTube에서 영상/음악 다운로드** | ❌ 불가 | YouTube 약관이 서드파티 다운로드(yt-dlp 등) 금지. 위반 시 계정 정지·저작권 문제. App Store 심사 거절 대상 |
| **YouTube Premium 오프라인 파일을 꺼내 워치에 넣기** | ❌ 불가 | Premium 다운로드는 YouTube 앱 내부에만 저장되며 파일로 추출 불가 |

**결론**: "YouTube 다운로더"는 만들 수 없습니다. 만들 수 있는 것은 **사용자가 권리를 가진 미디어 파일**(본인 녹음/촬영물, 구매한 음원, Creative Commons 등 라이선스가 허용하는 콘텐츠)을 워치로 옮겨 오프라인 재생하는 플레이어입니다.

### 1.1 YouTube를 꼭 쓰려면 (합법 경로만)

- **YouTube Premium**: 공식 오프라인 재생. 단 다운로드가 **YouTube 앱 안에 DRM으로 잠겨** 있어 이 앱으로 파일을 가져올 수 없음(확인됨). 즉 Premium은 이 플레이어의 곡 공급원이 될 수 없음. Apple Watch용 YouTube Music 오프라인도 아직 미지원(폰 저장분만 표시).
- **YouTube에 내가 올린 내 콘텐츠**: YouTube Studio에서 원본을 내려받아 이 앱에 넣는 것은 가능(내 저작물).
- **Creative Commons(재사용 허용) 표시 영상**: 라이선스 범위 내에서 사용 가능. 다만 다운로드 자체는 여전히 공식 수단이 없어, CC 원본을 제공하는 별도 출처를 써야 함.

즉 이 앱은 YouTube에 직접 붙지 않고, **사용자가 합법적으로 확보한 파일을 import** 하는 구조로 만듭니다.

---

## 2. 앱 구성

```
┌─────────────────────────┐   WatchConnectivity   ┌──────────────────────────┐
│  iPhone 컴패니언 앱      │  (WCSession transfer  │   watchOS 앱              │
│                         │   File / UserInfo)    │                          │
│  - 파일 import          │──────────────────────▶│  - 로컬 저장(문서 디렉토리)│
│    (Files, 공유 시트,   │                       │  - 오프라인 오디오 재생   │
│     AirDrop, iCloud)    │                       │    (AVAudioPlayer/        │
│  - 메타데이터·앨범아트   │                       │     AVPlayer, 백그라운드) │
│  - 워치로 전송 큐        │◀──────────────────────│  - 재생 목록·진행 상태 동기 │
└─────────────────────────┘    진행률·삭제 동기    └──────────────────────────┘
                                                    (셀룰러 모델은 블루투스
                                                     이어폰으로 폰 없이 청취)
```

### 2.1 기술 스택

| 영역 | 선택 |
|---|---|
| 언어/UI | Swift 5.9+, SwiftUI (watchOS 10+, iOS 17+) |
| 재생 | AVFoundation (`AVAudioPlayer`/`AVPlayer`), 백그라운드 오디오, 이어폰 라우팅 |
| 파일 전송 | WatchConnectivity `WCSession.transferFile` (대용량), 진행률·재시도 |
| 저장 | 워치 앱 문서 디렉토리, 용량 관리(다운로드 목록·삭제) |
| import | iOS: `UIDocumentPicker`, Share Extension, `Transferable`, iCloud Drive |
| 메타데이터 | `AVAsset` 메타데이터, 앨범아트 캐시 |
| 재생 UI | Now Playing, Digital Crown 볼륨, 컴플리케이션(현재 곡) |

### 2.2 watchOS 제약 반영

- **오디오 우선.** 영상은 배터리·저장공간 부담이 커 2차 기능으로 두거나 오디오만 추출해 넣는 옵션 제공.
- **전송은 iPhone 경유가 안정적.** 워치 직접 다운로드는 셀룰러/Wi-Fi 조건이 까다로워 컴패니언 전송을 기본으로.
- **저장공간 관리 필수.** 워치 여유 용량 확인, 곡별 삭제, 비트레이트 다운컨버트 옵션.

---

## 3. 단계별 계획

### Phase 1 — 골격 (1주) — ✅ 진행 중
- [x] 프로젝트 명세(XcodeGen `project.yml`): `iam`(iOS) + `iam Watch App`(watchOS)
- [x] WatchConnectivity 세션 수립(양쪽), 연결 상태 표시
- [x] 폴더 구조, 공유 `MediaItem` 모델, 재생/전송 상태 모델

### Phase 2 — iPhone import & 라이브러리 (1~2주)
- [x] 파일 import(`fileImporter`/Document Picker)
- [x] 오디오 메타데이터(제목·아티스트·길이) 추출, 라이브러리 목록·JSON 인덱스
- [ ] 공유 시트로 다른 앱에서 받기(Share Extension), 앨범아트, 포맷 검증 강화

### Phase 3 — 워치 전송 & 오프라인 재생 (2주) — 골격 완료
- [x] `transferFile`로 워치에 전송, 수신·로컬 저장·중복 방지
- [x] 오프라인 오디오 재생(`AVAudioPlayer`, 백그라운드 오디오 세션)
- [x] 기본 Now Playing UI(재생/일시정지/정지)
- [ ] 진행률·재시도 표시, Digital Crown 볼륨, 이전/다음, 재생 위치 복원

### Phase 4 — 관리 기능 (1주)
- [ ] 저장공간 표시·곡 삭제, 재생목록, 정렬/검색
- [ ] 현재 곡 컴플리케이션, 재생 위치 복원

### Phase 5 — 영상(선택) & 마무리 (1~2주)
- [ ] 영상 재생 실험(포맷·해상도 제한, 배터리 경고)
- [ ] 오디오만 추출 옵션, 접근성, App Store 준비

---

## 4. 리스크·주의

| 항목 | 내용 | 대응 |
|---|---|---|
| YouTube 다운로드 기능 | 약관 위반·App Store 거절 | **미구현.** import 기반으로만 동작 |
| 저작권 | 사용자가 넣는 파일의 권리는 사용자 책임 | 앱 내 고지, 합법 소스 안내 |
| 영상 배터리·용량 | 워치에서 영상은 부담 큼 | 오디오 우선, 영상은 경고와 함께 선택 기능 |
| 대용량 전송 실패 | 블루투스 전송 느림·중단 | 재시도·재개, 폰 근접 시 전송 권장 |
| 심사 정책 | 미디어 앱 정책 준수 | import 전용, 다운로더로 오해될 문구 배제 |

---

## 5. 다음 액션

1. 이 범위(오프라인 import 플레이어)로 진행할지 확인
2. 오디오 전용으로 시작할지, 영상까지 포함할지 결정
3. 확정 시 Phase 1 Xcode 프로젝트 골격부터 생성

---

## 참고 자료

- watchOS 로컬 미디어 플레이어 예: WristPlayer — https://apps.apple.com/us/app/wristplayer-offline-music/id6740153794
- Player for Watch — https://apps.apple.com/us/app/player-for-watch/id6446242162
- 워치 영상 플레이어 예(WaPlayer) — https://apps.apple.com/us/app/waplayer-play-video-on-watch/id1583396759
- 오픈소스 워치 영상 플레이어(WatchPlayer) — https://github.com/McTooter/WatchPlayer
- WKInterfaceMovie(Apple 문서) — https://developer.apple.com/documentation/watchkit/wkinterfacemovie
- YouTube Music Apple Watch 오프라인 현황 — https://www.idownloadblog.com/2025/10/28/using-youtube-music-on-apple-watch/
- YouTube 다운로드 약관·합법성 — https://www.techsmith.com/blog/download-youtube-videos/
- Spotify 워치 오프라인 다운로드 — https://www.xda-developers.com/how-to-download-spotify-music-apple-watch/
