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

#include <unordered_map>
#include <atomic>
#include <string>
#include <vector>
#include <map>
#include <array>

#ifdef _WIN32
#include <windows.h>
#endif

#include <vapoursynth/VSScript.h>
#include <vapoursynth/VSHelper.h>

#include "input.h"

#ifdef __unix__
#include <unistd.h>
#include <dlfcn.h>
#define Sleep(x) usleep(x)
#endif

struct VSFDCallbackData {
    const VSAPI* vsapi = nullptr;
    std::unordered_map<int, const VSFrameRef*> reorderMap;
    int parallelRequests {-1};
    std::atomic<int> outputFrames {-1};
    std::atomic<int> requestedFrames {-1};
    std::atomic<int> completedFrames {-1};
    int framesToRequest {-1};
    int startFrame {-1};
    std::atomic<bool> isRunning {false};
};

namespace X265_NS {
// x265 private namespace

using func_init = int (VS_CC *)();
using func_finalize = int (VS_CC *)();
using func_evaluateFile = int (VS_CC *)(VSScript** handle, const char* scriptFilename, int flags);
using func_freeScript = void (VS_CC *)(VSScript* handle);
using func_getError = const char* (VS_CC *)(VSScript* handle);
using func_getOutput = VSNodeRef* (VS_CC *)(VSScript* handle, int index);
using func_getCore = VSCore* (VS_CC *)(VSScript* handle);
using func_getVSApi2 = const VSAPI* (VS_CC *)(int version);

struct VSSFunc {
    func_init init;
    func_finalize finalize;
    func_evaluateFile evaluateFile;
    func_freeScript freeScript;
    func_getError getError;
    func_getOutput getOutput;
    func_getCore getCore;
    func_getVSApi2 getVSApi2;
};

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
    int nextFrame {0};
    bool vpyFailed {false};
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
    VSSFunc vss_func;
    const VSAPI* vsapi = nullptr;
    VSScript* script = nullptr;
    VSNodeRef* node = nullptr;
    const VSFrameRef* frame0 = nullptr;
    VSFDCallbackData vpyCallbackData;

public:
    VPYInput(InputFileInfo& info);
    ~VPYInput() {};
    void release();
    bool isEof() const { return nextFrame >= _info.frameCount; }
    bool isFail() { return vpyFailed; }
    void startReader();
    void stopReader();
    bool readPicture(x265_picture&);
    const char* getName() const { return "vpy"; }
    int getWidth() const { return _info.width; }
    int getHeight() const { return _info.height; }
};
}

#endif // ifndef X265_VPY_H
