# KoZaeDepot

[← 개요로 돌아가기](README.md) · [English](README.en.md)

KoZae 콘솔 도구를 빌드·배포하는 스크립트 모음입니다.

| 영역 | 소스 | 역할 |
|------|------|------|
| ConsoleHall / HelperShed | [KoZaeLibrary](https://github.com/Sunnymoon724/kozae-library) | C# 콘솔 exe·Helper DLL → 게임 프로젝트 `Tool/` |
| Refinery | [KoZaeRefinery](https://github.com/Sunnymoon724/kozae-refinery) | Python Proto 빌더 패키지 → 게임 프로젝트 `Tool/ProtoBuilder` 등으로 복사 |

## 구조

```
KoZaeDepot/
├── BuildLibrary.bat      # Helper DLL 빌드 → 프로젝트에 배포
├── ConfigOffice/         # 배포 설정 (git: *.example / PC마다 로컬 파일로 복사)
├── ConsoleHall/
│   ├── BuildConsole.bat  # Library 콘솔 exe 빌드 → 프로젝트 Tool 폴더로 복사
│   └── Runtime/          # 배치/PowerShell 템플릿; SitePath/는 alias별 Paths.env 시드
├── HelperShed/           # Helper 빌드 진입점
└── Refinery/             # Refinery(Python) 도구 publish — 상세는 Refinery README
    └── ProtoBuilder/     # KZProtoBuilder 빌드·생성 패키지
```

Refinery 사용법: [Refinery/README.ko.md](Refinery/README.ko.md)

## 최초 설정

`ConfigOffice`는 **이 PC 전용** 배포 설정입니다. repo에는 `*.example`만 있고, 복사한 뒤 본인 경로로 수정합니다.

| 복사 | 생성 | 용도 |
|------|------|------|
| `Paths.env.example` | `Paths.env` | `PROJECTS_ROOT`; `HELPER_PROJECT` = `Projects.list`의 Helper alias |
| `Projects.list.example` | `Projects.list` | alias → `PROJECTS_ROOT` 아래 프로젝트 폴더 |
| `ConsoleTargets.list.example` | `ConsoleTargets.list` | 콘솔 도구를 배포할 프로젝트 |
| `ToolPaths.map.example` | `ToolPaths.map` | alias 루트 아래 `Tool\...` 경로 (레이아웃 다를 때만 수정) |

**`ConsoleTargets.list` 배포 방식**

| 줄 | 복사 내용 | 배치 위치 |
|----|-----------|-----------|
| `@direct <alias>` | exe + 런타임 배치 (`direct-only\` 포함) | `PROJECTS_ROOT` + `Projects.list` + `ToolPaths.map` |
| `@common <alias>` | exe + 런타임 배치 (`direct-only\` 제외) | 경로 규칙 동일; 공용 `Common` Tool 트리용 |
| `@wrap <relPath>` | `wrappers\`만 + Tool 루트에 `CallCommon.bat` | `PROJECTS_ROOT\<relPath>\<toolFolder>` — `CallCommon`으로 `@common`/`@direct` 호출 |

`@wrap`은 exe를 복사하지 않습니다. 다른 곳에 `@direct` 또는 `@common`으로 올려 둔 뒤, 래퍼만 연결합니다.

**`Projects.list` 예시** — `<>` 안을 alias와 프로젝트 경로로 바꿉니다.

```
<HelperAlias>=<ProjectRoot>
<ConsoleAlias>=<ProjectRoot>
```

- `Paths.env`의 `HELPER_PROJECT` = `<HelperAlias>`와 같아야 함.
- `ConsoleTargets.list`의 `@direct` / `@common` = `Projects.list`에 있는 alias와 같아야 함.
- 실제 배포 경로 = `PROJECTS_ROOT` + `Projects.list` 경로 + `ToolPaths.map` 항목.

`Paths.env`, `Projects.list`, `ConsoleTargets.list`, `ToolPaths.map`은 **git에 올리지 않음**.

**`SitePath/` — 런타임 `Paths.env` 시드**

`BuildConsole`이 `@direct` / `@common`으로 배포할 때 씁니다. 프로젝트 `Tool/Paths.env`가 없으면 `SitePath/<alias>.env`를 **한 번만** 복사합니다 (`<alias>` = `Projects.list` 이름). 없으면 `Runtime/Paths.env`로 대체합니다. 이미 있는 `Tool/Paths.env`는 덮어쓰지 않습니다.

| 복사 | 생성 | 필요 시점 |
|------|------|-----------|
| `SitePath/alias.env.example` | `SitePath/<alias>.env` | `@direct` / `@common` alias마다 1개 |

| 키 | 용도 |
|----|------|
| `PROJECTS_ROOT` | 이 PC의 프로젝트 루트 |
| `WORK_PROJECT_PATH` | Unity 프로젝트 (Plugins, proto 복사 대상) |
| `DATA_ROOT_PATH` | `DataBase\{ENV}` 출력 루트 |
| `PROTO_SOURCE_PATH` | Excel proto 원본 (`ProtoGenerator`용) |

`@wrap`은 `SitePath`를 쓰지 않습니다. 래퍼는 `Project.env` / `CallCommon.bat`으로 경로를 넘깁니다.

`SitePath/*.env`는 **git에 올리지 않음** (`*.example`만).

## 일반 워크플로

**Library (C# 콘솔)**

1. **KoZaeLibrary** 수정 → 빌드/push.
2. **KoZaeDepot** 배치·설정 수정 → commit/push.
3. `BuildLibrary.bat` 및/또는 `ConsoleHall\BuildConsole.bat` 실행.
4. 각 게임 프로젝트에서 `Tool\GenerateProto\…` 래퍼 실행 (예: `GenerateProto_DEV.bat`).

**Refinery (Python ProtoBuilder)**

1. **KoZaeRefinery/Proto** 수정 → push.
2. `Refinery\BuildProtoBuilder.bat` 실행.
3. `ProtoBuilder\` 폴더를 게임 프로젝트 `Tool\ProtoBuilder\` 등으로 통째로 복사.
4. 프로젝트에서 `Config.env` 설정 후 `GenerateProto_DEV.bat` 등 실행.

상세: [Refinery/README.ko.md](Refinery/README.ko.md)

## 머신별 경로

`ConfigOffice/`와 `SitePath/`는 **PC마다 로컬**입니다 (위 최초 설정 참고). `PROJECTS_ROOT`나 프로젝트 폴더가 다르면 수정합니다.
