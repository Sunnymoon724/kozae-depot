# Refinery

[← KoZaeDepot](../README.md) · [English](README.en.md)

[KoZaeRefinery](https://github.com/Sunnymoon724/kozae-refinery) Python 도구를 빌드·배포하는 패키지입니다.

현재는 **ProtoBuilder** (`KZProtoBuilder`)만 포함합니다. 소스는 `KoZaeRefinery/Proto`입니다.

## 구조

```
Refinery/
├── BuildProtoBuilder.bat        # 빌드용 (배포 안 함)
└── ProtoBuilder/                # 통째로 배포하는 패키지
    ├── KZProtoBuilder.exe       # 빌드 산출 (커밋 안 함)
    ├── Config.env.example
    ├── Config.env               # 로컬 전용 (커밋 안 함)
    ├── GenerateProto.bat
    ├── GenerateProto_DEV.bat
    ├── …
    └── ProtoOutput/             # 생성 중간 결과 (커밋 안 함)
```

## 빌드

```bat
BuildProtoBuilder.bat
```

`KoZaeRefinery/Proto` 소스로 `ProtoBuilder\KZProtoBuilder.exe`를 만듭니다. (MessagePack 파이프라인, 템플릿 포함)

## 실행

### 직접 실행

```bat
KZProtoBuilder.exe <protoFolder> <environment> <language>
```

| 인수 | 설명 |
|------|------|
| `protoFolder` | Excel Proto 폴더 |
| `environment` | `Branch.xlsx` 환경 이름 (예: `DEV`, `LIVE`) |
| `language` | `csharp` 또는 `cpp` |

### 배치로 생성 (권장)

1. `Config.env.example` → `Config.env` 복사 후 수정
2. `GenerateProto_DEV.bat` (또는 LIVE / QA / REVIEW) 실행

`GenerateProto.bat` 동작:

1. `KZProtoBuilder.exe`로 `ProtoOutput\` 생성
2. `Plugin\` → `PLUGIN_OUTPUT`, `Proto\` → `PROTO_OUTPUT`으로 배포
3. `ProtoProject\` 정리
4. `KEEP_CSV=0`이면 `ProtoOutput\` 삭제

| `Config.env` 키 | 설명 |
|-----------------|------|
| `PROTO_FOLDER` | Excel Proto 폴더 절대 경로 |
| `LANGUAGE` | `csharp` 또는 `cpp` |
| `PLUGIN_OUTPUT` | Plugin 배포 경로 (`.dll` 또는 `.h`+`.lib`) |
| `PROTO_OUTPUT` | `.bytes` 배포 경로 |
| `KEEP_CSV` | `1` = `ProtoOutput` 유지, `0` = 배포 후 삭제 |

`csharp`일 때 .NET SDK, `cpp`일 때 CMake + MSVC (x64)가 필요합니다. PATH에 `cmake`가 없으면 배치가 Visual Studio CMake를 찾습니다.

`cpp` 소비 프로젝트는 공개 `.h` + `KZProto.lib`만 있으면 됩니다. msgpack은 게임 include에 필요 없고, `Load{Name}Proto`로 `.bytes`를 읽습니다.

## 출력

생성 직후:

```
ProtoOutput/
  Proto/    *.bytes
  Csv/      *.csv
  Plugin/   ← 선택한 language만
```

이후 `PLUGIN_OUTPUT` / `PROTO_OUTPUT`으로 배포되고, `KEEP_CSV=0`이면 `ProtoOutput\`은 삭제됩니다.

## 게임 프로젝트로 배포

`ProtoBuilder\` 폴더 전체를 복사합니다. (`BuildProtoBuilder.bat`은 Depot에 남김)
