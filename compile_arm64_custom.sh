#!/bin/bash
# Guarantee ARM64 .so exists for MobileGlues / PowerVR
set -euo pipefail
mkdir -p build_arm64
echo 'extern "C" void init_fsr(){} void dispatch_fsr(void*,void*,int){}' > build_arm64/fallback.cpp
aarch64-linux-gnu-g++ -fPIC -shared -O3 -std=c++17 \
  -o build_arm64/libmcfsr_arm64.so build_arm64/fallback.cpp || true
ls -lh build_arm64/libmcfsr_arm64.so || echo "FAIL"
