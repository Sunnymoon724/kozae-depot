# KoZaeDepot

[← Back to overview](README.md) · [한국어](README.ko.md)

Build and deploy packages for KoZae console tools.

| Area | Source | Role |
|------|--------|------|
| ConsoleHall / HelperShed | [KoZaeLibrary](https://github.com/Sunnymoon724/kozae-library) | C# console exes & Helper DLLs → game project `Tool/` |

Python Proto builder publish lives in [KoZaeRefinery](https://github.com/Sunnymoon724/kozae-refinery) `Proto/Publish/`.

## Layout

```
KoZaeDepot/
├── BuildLibrary.bat      # Build Helper DLLs → deploy to projects
├── ConfigOffice/         # Deploy config (*.example in git; copy to local files on each PC)
├── ConsoleHall/
│   ├── BuildConsole.bat  # Build Library console exes → copy to project Tool folders
│   └── Runtime/          # Batch/PowerShell templates; SitePath/ for per-alias Paths.env seeds
└── HelperShed/           # Helper build entry point
```

## Setup (first time)

`ConfigOffice` holds **machine-local** deploy settings. The repo tracks only `*.example` templates — copy each file and replace placeholders with your paths.

| Copy | To | Purpose |
|------|-----|---------|
| `Paths.env.example` | `Paths.env` | `PROJECTS_ROOT` on this PC; `HELPER_PROJECT` = Helper alias in `Projects.list` |
| `Projects.list.example` | `Projects.list` | Alias → project folder under `PROJECTS_ROOT` |
| `ConsoleTargets.list.example` | `ConsoleTargets.list` | Which projects receive each console tool |
| `ToolPaths.map.example` | `ToolPaths.map` | `Tool\...` subfolder under each alias (edit only if your layout differs) |

**`ConsoleTargets.list` deploy modes**

| Line | What gets copied | Where |
|------|------------------|--------|
| `@direct <alias>` | exe + runtime batches (`direct-only\` included) | `PROJECTS_ROOT` + `Projects.list` + `ToolPaths.map` |
| `@common <alias>` | exe + runtime batches (no `direct-only\`) | same path rule; use for a shared `Common` Tool tree |
| `@wrap <relPath>` | `wrappers\` only + `CallCommon.bat` at Tool root | `PROJECTS_ROOT\<relPath>\<toolFolder>` — calls `@common` / `@direct` via `CallCommon` |

`@wrap` does **not** copy exe. It expects a full deploy (`@direct` or `@common`) elsewhere; wrappers only forward to it.

**`Projects.list` example** (replace angle-bracket placeholders):

```
<HelperAlias>=<ProjectRoot>
<ConsoleAlias>=<ProjectRoot>
```

- `HELPER_PROJECT` in `Paths.env` must match `<HelperAlias>`.
- `@direct` / `@common` in `ConsoleTargets.list` must match an alias in `Projects.list`.
- Deploy path = `PROJECTS_ROOT` + path from `Projects.list` + entry from `ToolPaths.map`.

Do **not** commit `Paths.env`, `Projects.list`, `ConsoleTargets.list`, or `ToolPaths.map`.

**`SitePath/` — runtime `Paths.env` seeds**

Used when `BuildConsole` deploys with `@direct` or `@common`. If the project `Tool/Paths.env` does not exist yet, it copies `SitePath/<alias>.env` once (`<alias>` = `Projects.list` name). If missing, falls back to `Runtime/Paths.env`. Existing `Tool/Paths.env` is never overwritten.

| Copy | To | When needed |
|------|-----|-------------|
| `SitePath/alias.env.example` | `SitePath/<alias>.env` | One file per `@direct` / `@common` alias |

| Key | Used for |
|-----|----------|
| `PROJECTS_ROOT` | Base path on this PC |
| `WORK_PROJECT_PATH` | Unity project (plugins, generated proto copy target) |
| `DATA_ROOT_PATH` | `DataBase\{ENV}` output root |
| `PROTO_SOURCE_PATH` | Excel proto source (`ProtoGenerator` only) |

`@wrap` does not use `SitePath`; wrappers pass paths via `Project.env` / `CallCommon.bat` instead.

Do **not** commit `SitePath/*.env` (only `*.example`).

## Typical workflow

**Library (C# consoles)**

1. Change **KoZaeLibrary** → build/push library.
2. Change **KoZaeDepot** batches or config → commit/push depot.
3. Run `BuildLibrary.bat` and/or `ConsoleHall\BuildConsole.bat`.
4. In each game project, run `Tool\GenerateProto\…` wrappers (e.g. `GenerateProto_DEV.bat`).

**Refinery (Python ProtoBuilder)**

Build and ship from [KoZaeRefinery Proto/Publish](https://github.com/Sunnymoon724/kozae-refinery/tree/main/Proto/Publish).

## Machine paths

`ConfigOffice/` and `SitePath/` are **local on each PC** (see Setup). Edit when `PROJECTS_ROOT` or project folders differ.
