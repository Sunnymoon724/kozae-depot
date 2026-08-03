# Refinery

[← KoZaeDepot](../README.md) · [한국어](README.ko.md)

Build and publish packages for [KoZaeRefinery](https://github.com/Sunnymoon724/kozae-refinery) Python tools.

Currently includes **ProtoBuilder** (`KZProtoBuilder`) only. Sources live in `KoZaeRefinery/Proto`.

## Layout

```
Refinery/
├── BuildProtoBuilder.bat        # build only (not deployed)
└── ProtoBuilder/                # deploy this folder as a whole
    ├── KZProtoBuilder.exe       # built (not committed)
    ├── flatc.exe                # copied (not committed)
    ├── Config.env.example
    ├── Config.env               # local only (not committed)
    ├── GenerateProto.bat
    ├── GenerateProto_DEV.bat
    ├── …
    └── ProtoOutput/             # temp generate output (not committed)
```

## Build

```bat
BuildProtoBuilder.bat
```

Builds `KZProtoBuilder.exe` from `KoZaeRefinery/Proto`, and places `flatc.exe` alongside it.

## Run

### Direct

```bat
KZProtoBuilder.exe <protoFolder> <environment> <language>
```

| Argument | Description |
|----------|-------------|
| `protoFolder` | Excel proto folder |
| `environment` | Branch name in `Branch.xlsx` (e.g. `DEV`, `LIVE`) |
| `language` | `csharp` or `cpp` |

### Generate via batch (recommended)

1. Copy `Config.env.example` → `Config.env` and edit
2. Run `GenerateProto_DEV.bat` (or LIVE / QA / REVIEW)

`GenerateProto.bat` flow:

1. Run `KZProtoBuilder.exe` → write `ProtoOutput\`
2. Deploy `Plugin\` → `PLUGIN_OUTPUT`, `Proto\` → `PROTO_OUTPUT`
3. Clean `ProtoProject\`
4. Delete `ProtoOutput\` when `KEEP_CSV=0`

| `Config.env` key | Meaning |
|------------------|---------|
| `PROTO_FOLDER` | Absolute path to the Excel Proto folder |
| `LANGUAGE` | `csharp` or `cpp` |
| `PLUGIN_OUTPUT` | Deploy path for Plugin artifacts (`.dll` or `.h`+`.lib`) |
| `PROTO_OUTPUT` | Deploy path for `.bytes` |
| `KEEP_CSV` | `1` keeps `ProtoOutput`; `0` deletes it after deploy |

Requires .NET SDK for `csharp`, and CMake + MSVC (x64) for `cpp`. If `cmake` is not on PATH, the batch looks for Visual Studio CMake.

## Output

Right after generate:

```
ProtoOutput/
  Proto/    *.bytes
  Csv/      *.csv
  Plugin/   ← selected language only
```

Then artifacts are deployed to `PLUGIN_OUTPUT` / `PROTO_OUTPUT`, and `ProtoOutput\` is removed when `KEEP_CSV=0`.

## Deploy to a game project

Copy the whole `ProtoBuilder\` folder. (`BuildProtoBuilder.bat` stays in Depot.)
