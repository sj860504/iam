# 조사: 유튜브 뮤직 워치 단독 실행 앱 실현 가능성

> 작성일: 2026-09-17
> 질문: "유튜브 뮤직을 Apple Watch에서 단독(standalone) 실행하는 서드파티 앱을 만들 수 있는가?"
> 결론: **합법적으로는 불가.** 공식 API 부재 + YouTube 약관 + watchOS 웹뷰 부재의 삼중 장벽.

---

## 1. 결론 요약

| 경로 | 가능? | 이유 |
|---|---|---|
| 공식 YouTube Music API로 스트리밍/재생 | ❌ | 서드파티용 **공식 재생 API가 존재하지 않음** |
| YouTube Data API + IFrame 플레이어 | ❌ | 약관이 **오디오 분리·백그라운드 재생·비공식 플레이어**를 금지. 게다가 IFrame은 웹 플레이어인데 **watchOS엔 개발자용 WKWebView가 없음** |
| 비공식 API(ytmusicapi 등, 쿠키 인증) | ⚠️ 기술적 가능 / ❌ 합법성 | YouTube 약관 위반, App Store 거절, 계정 정지 위험, 엔드포인트 변경 시 수시 중단 |
| 공식 YouTube Music 워치 앱 | 대기 | 현재는 "컨트롤러"일 뿐 단독 아님. 구글이 Apple Watch 오프라인 다운로드를 개발 중(2026-06 코드 발견)이나 미출시 |

---

## 2. 장벽 상세

### 2.1 공식 YouTube Music API가 없음
- 구글은 서드파티가 YouTube Music 카탈로그를 **스트리밍·재생**할 수 있는 공식 API를 제공하지 않습니다.
- 서드파티 클라이언트(SimpMusic 등)는 모두 **쿠키 인증 기반의 비공식(리버스 엔지니어링) 방식**을 씁니다. "best-effort"이며 예고 없이 깨집니다.

### 2.2 YouTube API 약관이 음악 재생 용도를 금지
YouTube API Services Developer Policies 명시:
- 오디오/비디오 컴포넌트를 **분리·격리·변형 금지** (예: 영상에서 오디오만 추출해 재생).
- **백그라운드 플레이어**(화면에 보이지 않는 재생) 금지.
- YouTube가 승인한 플레이어 **이외의 수단**으로 콘텐츠 접근 금지.
→ 즉 "오디오만, 화면 꺼진 채, 자체 플레이어로" 재생하는 음악 앱은 정책상 불가.

### 2.3 watchOS에 개발자용 웹뷰가 없음
- WebKit/WKWebView는 iOS·iPadOS·macOS에만 제공되고 **watchOS는 미제공**.
- 따라서 YouTube가 유일하게 허용하는 **IFrame 임베드 플레이어조차 워치에서 실행 불가**(영상 컴포넌트도 없음).

### 2.4 공식 앱도 아직 단독이 아님
- 현재 Apple Watch용 YouTube Music은 폰을 제어하는 **컨트롤러**이며, 워치에 곡을 저장/단독 재생하지 못함.
- Wear OS·Garmin은 이미 오프라인 지원. Apple Watch용은 구글이 개발 중이나 출시 시점 미정.

---

## 3. 참고 — 기존 사례
- `andremiliano/YTWatch-OpenSource`: "Apple Watch에서 유튜브 뮤직 오프라인 재생" 오픈소스. 이런 앱은 위 2.1~2.2의 **비공식 방식**에 의존하며, App Store 정식 배포가 아니라 개인 사이드로딩 범위. 약관·계정 리스크를 그대로 안음.

---

## 4. 현실적인 선택지

| 선택지 | 내용 | 평가 |
|---|---|---|
| A. 공식 지원 대기 | 구글의 YouTube Music Apple Watch 오프라인 출시를 기다림 | 비용 0, 시점 불확실 |
| B. 내 파일 오프라인 플레이어 | 이미 만든 골격 사용. 본인이 파일로 가진 음원을 넣어 재생 | 합법·실현 가능. YouTube 카탈로그는 못 씀 |
| C. 비공식 클라이언트 | ytmusicapi류로 자체 클라이언트 | **비권장.** 약관 위반·App Store 거절·계정 정지·잦은 고장 |

**권장**: B로 계속하고 A를 병행 대기. YouTube Music 카탈로그 자체를 워치에서 단독 재생하는 것은 구글이 열어주기 전까지 서드파티가 합법적으로 만들 수 없습니다.

---

## 참고 자료
- 서드파티 YouTube Music 클라이언트 현황: https://www.androidpolice.com/i-replaced-youtube-music-with-a-third-party-client/
- ytmusicapi(비공식): https://github.com/sigma67/ytmusicapi
- YouTube API Services 약관: https://developers.google.com/youtube/terms/api-services-terms-of-service
- YouTube 개발자 정책(오디오 분리·백그라운드 금지): https://developers.google.com/youtube/terms/developer-policies
- YouTube IFrame 플레이어 API: https://developers.google.com/youtube/iframe_api_reference
- watchOS WKWebView 미지원(Apple 개발자 포럼): https://developer.apple.com/forums/thread/109330
- YouTube Music Apple Watch 오프라인 개발 중(9to5Google, 2026-06): https://9to5google.com/2026/06/23/youtube-music-may-soon-support-offline-downloads-on-apple-watch/
- YTWatch 오픈소스 사례: https://github.com/andremiliano/YTWatch-OpenSource
