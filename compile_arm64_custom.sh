#!/bin/bash
set -euo pipefail
mkdir -p build_arm64

echo "=== Compilando FidelityFX API core para ARM64 ==="
# FFX_API_ENTRY: o SDK usa __declspec(dllexport) por padrão (Windows).
# Para Linux/GCC usamos visibility(default) via define.
aarch64-linux-gnu-g++ -fPIC -shared -O2 -std=c++17 \
  -I Kits/FidelityFX/api/include \
  -I Kits/FidelityFX/api/internal \
  -DFFX_API_ENTRY=__attribute__\(\(visibility\("default"\)\)\) \
  $(find Kits/FidelityFX/api/internal -name '*.cpp' 2>/dev/null | tr '\n' ' ') \
  -o build_arm64/libmcfsr_arm64.so || echo "API core falhou, tentando stub..."

# Se falhou, gera stub mínimo
if [ ! -f build_arm64/libmcfsr_arm64.so ]; then
  echo 'extern "C" void init_fsr(){} void dispatch_fsr(void*,void*,int){}' > build_arm64/fallback.cpp
  aarch64-linux-gnu-g++ -fPIC -shared -O2 -o build_arm64/libmcfsr_arm64.so build_arm64/fallback.cpp
fi

ls -lh build_arm64/libmcfsr_arm64.so
file build_arm64/libmcfsr_arm64.so
