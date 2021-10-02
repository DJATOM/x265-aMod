/*****************************************************************************
 * Copyright (C) 2013-2020 MulticoreWare, Inc
 *
 * Authors: Vladimir Kontserenko <djatom@beatrice-raws.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02111, USA.
 *
 * This program is also available under a commercial proprietary license.
 * For more information, contact us at license @ x265.com.
 *****************************************************************************/

#ifndef X265_VPY_H
#define X265_VPY_H

#ifdef X86_64
#define VPY_64 1
#else
#define VPY_64 0
#endif

#include <unordered_map>
#include <atomic>
#include <string>
#include <vector>
#include <map>
#include <array>

#ifdef _WIN32
#include <windows.h>
#endif

#include <vapoursynth/VSScript4.h>
#include <vapoursynth/VSHelper4.h>

#include "input.h"

#ifdef __unix__
#include <unistd.h>
#include <dlfcn.h>
#define Sleep(x) usleep(x)
#define __stdcall
#endif

#if defined(_WIN32) || defined(_WIN64)
#define CloseEvent CloseHandle
#else
#include "event.h"
#endif

namespace X265_NS {
// x265 private namespace

using func_vssapi = const VSSCRIPTAPI* (VS_CC *)(int version);

#if defined(_WIN32_WINNT)
using lib_path_t = std::wstring;
using lib_hnd_t = HMODULE;
using func_t = FARPROC;
#else
using lib_path_t = std::string;
using lib_hnd_t = void*;
using func_t = void*;
#endif

class VPYInput : public InputFile
{
protected:
    std::unordered_map<int, std::pair<HANDLE, const VSFrame*>> frameMap;
    int parallelRequests {-1};
    std::atomic<int> requestedFrames {-1};
    std::atomic<int> completedFrames {-1};
    int framesToRequest {-1};
    std::atomic<bool> isRunning {false};
    int nextFrame {0};
    int nodeIndex {0};
    bool useScriptSar {false};
    bool vpyFailed {false};
    char frameError[512];
    size_t frame_size {0};
    uint8_t* frame_buffer {nullptr};
    InputFileInfo _info;
    lib_hnd_t vss_library;
#if _WIN32
    lib_path_t vss_library_path {L"vsscript"};
    void vs_open() { vss_library = LoadLibraryW(vss_library_path.c_str()); }
    void vs_close() { FreeLibrary(vss_library); vss_library = nullptr; }
    func_t vs_address(LPCSTR func) { return GetProcAddress(vss_library, func); }
#else
#ifdef __MACH__
    lib_path_t vss_library_path {"libvapoursynth-script.dylib"};
#else
    lib_path_t vss_library_path {"libvapoursynth-script.so"};
#endif
    void vs_open() { vss_library = dlopen(vss_library_path.c_str(), RTLD_GLOBAL | RTLD_LAZY | RTLD_NOW); }
    void vs_close() { dlclose(vss_library); vss_library = nullptr; }
    func_t vs_address(const char* func) { return dlsym(vss_library, func); }
#endif
    lib_path_t convertLibraryPath(std::string);
    void parseVpyOptions(const char* _options);
    const VSFrame* getAsyncFrame(int n);
    func_vssapi getVSScriptAPI;
    const VSSCRIPTAPI* vssapi = nullptr;
    const VSAPI* vsapi = nullptr;
    VSCore *core = nullptr;
    VSScript* script = nullptr;
    VSNode* node = nullptr;

public:
    VPYInput(InputFileInfo& info);
    ~VPYInput() {};
    void setAsyncFrame(int n, const VSFrame* f, const char* errorMsg);
    void release();
    bool isEof() const { return nextFrame >= _info.frameCount; }
    bool isFail() { return vpyFailed; }
    void startReader();
    void stopReader();
    bool readPicture(x265_picture&);
    const char* getName() const { return "vpy"; }
    int getWidth() const { return _info.width; }
    int getHeight() const { return _info.height; }
    int outputFrame() { return nextFrame; }
};
}

#endif // ifndef X265_VPY_H
