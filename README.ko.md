# iphone-screen-skill

[English](README.md) · **한국어**

`iphone-screen`은 macOS 터미널에서 USB로 연결된 iPhone의 실시간 화면을 PNG로 캡처하는 Claude Code 및 OpenAI Codex용 에이전트 스킬입니다. 실기기에서 앱을 조작하거나 수동 단계를 확인하고, 기기 UI 테스트가 멈춘 원인을 파악할 때 에이전트가 실제 기기 화면을 직접 볼 수 있게 해 줍니다. QuickTime을 열지 않고 헤드리스로 동작하며, Mac 화면이 아닌 iPhone 화면만 캡처합니다.

## 요구 사항

- Xcode 명령줄 도구(`swiftc`)가 설치된 macOS
- USB로 연결되고 잠금 해제되었으며 이 Mac을 신뢰한 iPhone
- **시스템 설정 > 개인정보 보호 및 보안 > 카메라**에서 사용 중인 터미널 앱에 부여된 카메라 권한

## 설치

저장소를 클론한 뒤 `iphone-screen` 디렉터리를 Claude Code 또는 OpenAI Codex(또는 둘 다)의 스킬 디렉터리에 심볼릭 링크로 연결합니다.

```sh
git clone https://github.com/naelonambul/iphone-screen-skill.git
```

Claude Code (`~/.claude/skills/`):

```sh
mkdir -p ~/.claude/skills
ln -s "$(pwd)/iphone-screen-skill/iphone-screen" ~/.claude/skills/iphone-screen
```

OpenAI Codex (`~/.agents/skills/`):

```sh
mkdir -p ~/.agents/skills
ln -s "$(pwd)/iphone-screen-skill/iphone-screen" ~/.agents/skills/iphone-screen
```

## 사용법

출력 파일 경로 하나를 인자로 넘겨 스크립트를 실행합니다.

```sh
<skill-dir>/scripts/iphone-shot /tmp/phone.png
```

성공하면 `<path> <width>x<height>`를 출력하고 `0`으로 종료합니다. 명령 실행만으로는 에이전트가 화면을 볼 수 없으므로, 생성된 PNG 파일을 이어서 열어야 합니다(Claude Code는 `Read`, Codex는 `view_image`). 첫 실행 시 바이너리를 `~/.cache/iphone-screen/`에 컴파일하며, 이후 실행에는 약 0.6초가 걸립니다.

프롬프트 예시:

- Claude Code: `Use the iphone-screen skill to capture the connected iPhone's screen and look at it.`
- OpenAI Codex: `Use $iphone-screen to capture the connected iPhone's screen and look at it.`

## 종료 코드

오류가 발생하면 stderr에 한 줄을 출력하고 0이 아닌 종료 코드를 반환합니다.

| 코드 | 메시지 | 의미 |
| --- | --- | --- |
| 2 | `no device` | 10초 내에 iPhone 화면 장치를 찾지 못함(연결 해제, 잠김 또는 신뢰되지 않음). |
| 3 | `not authorized` | 터미널 앱에 카메라 권한이 없거나, 샌드박스가 카메라 접근을 차단함. |
| 4 | `no frame` | 장치를 찾았으나 두 번 연속 15초 동안 비디오 프레임이 도착하지 않음(래퍼가 자동으로 한 번 재시도함). 보통 기기가 잠겼거나 사용 중인 상태임. |
| 5 | `cannot write` | 출력 경로에 쓸 수 없음(예: 상위 디렉터리가 존재하지 않음). |
| 64 | `usage` | 인자가 잘못됨. 출력 파일 경로 하나만 전달해야 함. |

## 개인정보 보호

- USB로 연결된 iPhone 화면만 캡처하며, Mac 화면이나 다른 창은 절대 캡처하지 않습니다.
- 캡처 파일은 임시 디렉터리나 세션용 스크래치 디렉터리에 저장하고 확인 후 삭제하세요.
- 캡처 이미지를 저장소에 커밋하거나 외부로 전송하지 마세요.
- 이 도구는 시스템, 개인정보 보호 또는 기기 설정을 변경하지 않습니다.

## 동작 방식

첫 실행 시 `scripts/iphone-shot`은 `swiftc -O`로 `scripts/iphone-shot.swift`를 컴파일하여 `~/.cache/iphone-screen/iphone-shot`에 캐시합니다. 바이너리는 CoreMediaIO의 `kCMIOHardwarePropertyAllowScreenCaptureDevices` 속성을 설정해 macOS가 USB 연결 iPhone을 AVFoundation 외부 muxed 장치로 노출하도록 합니다. 이는 QuickTime 동영상 녹화가 사용하는 것과 같은 메커니즘으로 QuickTime을 띄울 필요가 없으며, `ffmpeg`의 `avfoundation` 입력이 해당 속성을 설정하지 않아 iPhone을 목록에 표시하지 못하는 이유이기도 합니다. 이후 장치에서 `AVCaptureSession`을 열어 10번째로 수신된 비디오 프레임을 Core Image로 RGBA8 PNG 파일에 저장하고 종료하며, 콜드 스타트로 종료 코드 `4`가 반환되면 셸 래퍼가 자동으로 한 번 재시도합니다.

## 제한 사항

- macOS에서만 동작합니다.
- 한 번에 한 대의 기기만 지원합니다(탐색된 첫 번째 외부 muxed 장치 사용).
- Codex의 `workspace-write`와 같은 제한적 샌드박스 안에서는 터미널 앱에 카메라 권한이 있더라도 카메라 접근이 차단되어 종료 코드 `3`(`not authorized`)으로 실패합니다. 일반 승인을 받아 샌드박스 밖에서 실행해야 합니다.
- 테스트 밖에서 실시간 기기 화면을 확인하기 위한 도구이며, 테스트 판정의 기준은 여전히 XCUITest 스크린샷과 첨부 파일입니다.

## 라이선스

MIT
