// ---------------------------------------------------------------------------
// ffx_posix_compat.h
//
// Shim de compatibilidade POSIX/GCC para compilar o nucleo Vulkan + internal
// do FidelityFX SDK em Linux/aarch64. O SDK upstream so compila em MSVC e usa
// as funcoes seguras da Microsoft (wcscpy_s / strcpy_s / sprintf_s) que nao
// existem na libc do GCC/Clang. Este header e injetado com -include pelo
// compilador (ver compile_arm64_custom.sh) e so tem efeito fora do Windows.
//
// Nenhum codigo do SDK foi modificado: tudo aqui sao apenas implementacoes
// equivalentes das rotinas _s para que a assinatura usada no repo compile.
// ---------------------------------------------------------------------------
#pragma once

#if !defined(_WIN32)

#include <cstddef>
#include <cstdarg>
#include <cstdio>
#include <cstring>
#include <cwchar>

// sprintf_s(buffer, tamanho, formato, ...)
static inline int sprintf_s(char* buffer, size_t sizeInBytes, const char* format, ...)
{
    if (!buffer || sizeInBytes == 0)
        return -1;
    va_list args;
    va_start(args, format);
    const int written = vsnprintf(buffer, sizeInBytes, format, args);
    va_end(args);
    return written;
}

// strcpy_s(destino, tamanho, origem)  -> ponteiro
static inline int strcpy_s(char* dest, size_t sizeInBytes, const char* src)
{
    if (!dest || !src || sizeInBytes == 0)
        return 22; // EINVAL
    const size_t len = strlen(src);
    if (len + 1 > sizeInBytes)
    {
        dest[0] = '\0';
        return 34; // ERANGE
    }
    memcpy(dest, src, len + 1);
    return 0;
}

// wcscpy_s(destino, contagem, origem)  -> ponteiro
static inline int wcscpy_s(wchar_t* dest, size_t sizeInWords, const wchar_t* src)
{
    if (!dest || !src || sizeInWords == 0)
        return 22; // EINVAL
    const size_t len = wcslen(src);
    if (len + 1 > sizeInWords)
    {
        dest[0] = L'\0';
        return 34; // ERANGE
    }
    wmemcpy(dest, src, len + 1);
    return 0;
}

// Sobrecargas com deducao do tamanho do array (estilo template do MSVC),
// usadas pelo SDK como wcscpy_s(obj.name, origem) / strcpy_s(obj.name, origem).
template <size_t N>
static inline int wcscpy_s(wchar_t (&dest)[N], const wchar_t* src)
{
    return wcscpy_s(dest, N, src);
}

template <size_t N>
static inline int strcpy_s(char (&dest)[N], const char* src)
{
    return strcpy_s(dest, N, src);
}

#endif // !_WIN32
