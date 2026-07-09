# KoZaeDepot

[← 개요로 돌아가기](README.md) · [English](README.en.md)

[KoZaeLibrary](https://github.com/Sunnymoon724/kozae-library) 콘솔 도구(`KZProtoGenerator`, `KZLuaConverter` 등)를 빌드·배포하는 스크립트 모음입니다.

라이브러리 repo에서 빌드한 콘솔 exe를 각 게임 프로젝트 `Tool/` 폴더로 복사하는 용도입니다.

## 구조

```
KoZaeDepot/
├── BuildLibrary.bat      # Helper DLL 빌드 → 프로젝트에 배포
├── ConfigOffice/         # 배포 대상 (Projects.list, ConsoleTargets.list, ToolPaths.map)
├── ConsoleHall/
│   ├── BuildConsole.bat  # Library 콘솔 exe 빌드 → 프로젝트 Tool 폴더로 복사
│   └── Runtime/          # 각 도구와 함께 배포되는 배치/PowerShell 템플릿
└── HelperShed/           # Helper 빌드 진입점
```

## 일반 워크플로

1. **KoZaeLibrary** 수정 → 빌드/push.
2. **KoZaeDepot** 배치·설정 수정 → commit/push.
3. `BuildLibrary.bat` 및/또는 `ConsoleHall\BuildConsole.bat` 실행.
4. 각 게임 프로젝트에서 `Tool\GenerateProto\…` 래퍼 실행 (예: `GenerateProto_DEV.bat`).

## 머신별 경로

- `ConfigOffice/Paths.env` — 이 PC의 빌드 스크립트용 `PROJECTS_ROOT`.
- `ConsoleHall/Runtime/SitePath/*.env` — alias별 시드; 프로젝트 `Tool/Paths.env`에 최초 1회 복사됨.

프로젝트 루트가 PC마다 다르면 위 파일을 편집합니다.
