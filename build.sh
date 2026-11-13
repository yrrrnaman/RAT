#!/usr/bin/env bash
set -euo pipefail
JH="${JAVA_HOME:?set JAVA_HOME}"
OUT=build
rm -rf "$OUT" && mkdir -p "$OUT/classes" "$OUT/native" "$OUT/inc"
python3 tool/strgen.py
x86_64-w64-mingw32-g++ -c -O2 -municode src/main/native/jvmstub.cpp -o "$OUT/native/stub.exe"
xxd -i "$OUT/native/stub.exe" > "$OUT/native/payload.inc"
x86_64-w64-mingw32-g++ -shared -O2 -s -static-libgcc -static-libstdc++ \
  -I"$JH/include" -I"$JH/include/win32" -I"$OUT/inc" -Isrc/main/native \
  -include "$OUT/native/payload.inc" src/main/native/*.cpp -o "$OUT/n.dll" \
  -luser32 -ladvapi32 -lgdi32 -lntdll -liphlpapi -Wl,--kill-at
javac -source 8 -target 8 -encoding UTF-8 -h "$OUT/inc" -d "$OUT/classes" $(find src -name '*.java')
cp "$OUT/n.dll" "$OUT/classes/n.dll"
printf 'Main-Class: com.sun.rt.Bootstrap\nPermissions: all-permissions\n' > "$OUT/manifest.txt"
( cd "$OUT/classes" && jar cfm ../rt.jar ../manifest.txt . )
echo "built: $OUT/rt.jar -> run launch4j.xml next"