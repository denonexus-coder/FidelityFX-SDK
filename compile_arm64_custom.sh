#!/usr/bin/env bash
# ===========================================================================
# compile_arm64_custom.sh
#
# Cross-compila o NUCLEO portavel do FidelityFX SDK (camada api + backend
# Vulkan + dispatch interno do FSR2/FSR3 upscaler + frame interpolation) para
# Linux aarch64 (ARM64), gerando libmcfsr.so.
#
# O que ENTRA (codigo real do repo, sem dependencia de Windows/DXGI):
#   - Kits/FidelityFX/api/internal/*.cpp          (camada ffx_api)
#   - Kits/FidelityFX/backend/vk/*.cpp            (backend Vulkan)
#   - Kits/FidelityFX/upscalers/fsr3/internal/*.cpp
#   - Kits/FidelityFX/framegeneration/fsr3/internal/*.cpp  (interpolacao/optical flow)
#
# O que fica de FORA (especifico de Windows / DirectX 12 / DXGI swapchain):
#   - backend/dx12/*
#   - framegeneration/fsr3/dx12/*
#   - framegeneration/fsr3/vk/*  (swapchain VK usa <Windows.h> / VK_USE_PLATFORM_WIN32_KHR)
#
# As funcoes seguras da MS (wcscpy_s/strcpy_s/sprintf_s), ausentes no GCC, sao
# fornecidas por Kits/FidelityFX/api/internal/ffx_posix_compat.h via -include.
# ===========================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SDK="$ROOT/Kits/FidelityFX"
OUT="$ROOT/build_arm64"
mkdir -p "$OUT"

# ---- Toolchain -------------------------------------------------------------
CXX="${CXX:-aarch64-linux-gnu-g++}"
echo ">> Compilador: $CXX"
"$CXX" --version | head -1

# ---- Include paths ---------------------------------------------------------
INCLUDES=(
  "-I$SDK"
  "-I$SDK/api/include"
  "-I$SDK/api/internal"
  "-I$SDK/api/internal/gpu"
  "-I$SDK/backend/vk"
  "-I$SDK/upscalers/include"
  "-I$SDK/upscalers/fsr3/include"
  "-I$SDK/upscalers/fsr3/internal"
  "-I$SDK/framegeneration/include"
  "-I$SDK/framegeneration/fsr3/include"
  "-I$SDK/framegeneration/fsr3/internal"
  "-I$SDK/denoisers/include"
  "-I$SDK/radiancecache/include"
)

# ---- Flags -----------------------------------------------------------------
# Vulkan e header-only aqui: carregamos os simbolos via device/instance passados
# pela aplicacao, entao nao linkamos libvulkan (apenas os headers).
CXXFLAGS=(
  -std=c++17
  -fPIC
  -O2
  -fvisibility=hidden
  -fexceptions
  -Wno-unknown-pragmas
  -Wno-unused-variable
  -Wno-unused-parameter
  -DVK_NO_PROTOTYPES
  -DFFX_API_VK
  -include "$SDK/api/internal/ffx_posix_compat.h"
)

# ---- Fontes portaveis (codigo real do repo) --------------------------------
SOURCES=()
SOURCES+=( "$SDK"/api/internal/*.cpp )
SOURCES+=( "$SDK"/backend/vk/*.cpp )
SOURCES+=( "$SDK"/upscalers/fsr3/internal/*.cpp )
SOURCES+=( "$SDK"/framegeneration/fsr3/internal/*.cpp )

echo ">> Fontes a compilar: ${#SOURCES[@]} arquivos"
printf '   %s\n' "${SOURCES[@]#$ROOT/}"

# ---- Compilacao objeto a objeto -------------------------------------------
OBJDIR="$OUT/obj"
mkdir -p "$OBJDIR"
OBJECTS=()
for src in "${SOURCES[@]}"; do
  obj="$OBJDIR/$(echo "${src#$SDK/}" | tr '/' '_').o"
  echo ">> CXX $(basename "$src")"
  "$CXX" "${CXXFLAGS[@]}" "${INCLUDES[@]}" -c "$src" -o "$obj"
  OBJECTS+=( "$obj" )
done

# ---- Link em biblioteca compartilhada --------------------------------------
SONAME="libmcfsr.so"
echo ">> LINK $SONAME"
"$CXX" -shared -fPIC -Wl,-soname,"$SONAME" "${OBJECTS[@]}" -o "$OUT/$SONAME"

echo ">> OK: $OUT/$SONAME"
file "$OUT/$SONAME" || true
ls -lh "$OUT/$SONAME"
