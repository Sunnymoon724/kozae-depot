# KoZaeDepot

Build and deploy scripts for KoZae console tools (`KZProtoGenerator`, `KZLuaConverter`, etc.).

**Requires:** [KoZaeLibrary](https://github.com/Sunnymoon724/kozae-library) **>= 1.2.0** (proto `.bytes` are Zstd-compressed only; no password / AES encryption)

## Layout

```
KoZaeDepot/
├── BuildLibrary.bat      # Build Helper DLLs → deploy to projects
├── ConfigOffice/         # Deploy targets (Projects.list, ConsoleTargets.list, ToolPaths.map)
├── ConsoleHall/
│   ├── BuildConsole.bat  # Build Library console exes → copy to project Tool folders
│   └── Runtime/          # Batch/PowerShell templates shipped with each tool
└── HelperShed/           # Helper build entry point
```

## Typical workflow

1. Change **KoZaeLibrary** → build/push library.
2. Change **KoZaeDepot** batches or config → commit/push depot.
3. Run `BuildLibrary.bat` and/or `ConsoleHall\BuildConsole.bat`.
4. In each game project, run `Tool\GenerateProto\…` wrappers (e.g. `GenerateProto_DEV.bat`).

## Machine paths

- `ConfigOffice/Paths.env` — `PROJECTS_ROOT` for build scripts on this machine.
- `ConsoleHall/Runtime/SitePath/*.env` — per-alias seeds copied once into each project `Tool/Paths.env`.

Edit these when project roots differ between machines.
