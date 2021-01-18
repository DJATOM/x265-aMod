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

#include "vpy.h"
#include "common.h"

static void frameDoneCallback(void* userData, const VSFrameRef* f, const int n, VSNodeRef* node, const char*)
{
    VSFDCallbackData* vpyCallbackData = static_cast<VSFDCallbackData*>(userData);

    ++vpyCallbackData->completedFrames;

    if(f)
    {
        vpyCallbackData->reorderMap[n] = f;

        size_t retries = 0;
        while((vpyCallbackData->completedFrames - vpyCallbackData->outputFrames) > vpyCallbackData->parallelRequests) // wait until x265 asks more frames
        {
            Sleep(15);
            if(retries > vpyCallbackData->parallelRequests * 1.5) // we don't want to wait for eternity
                break;
            retries++;
        }

        if(vpyCallbackData->requestedFrames < vpyCallbackData->framesToRequest && vpyCallbackData->isRunning) // don't ask for new frames if user cancelled execution
        {
            //x265::general_log(nullptr, "vpy", X265_LOG_FULL, "Callback: retries: %d, current frame: %d, requested: %d, completed: %d, output: %d  \n", retries, n, vpyCallbackData->requestedFrames.load(), vpyCallbackData->completedFrames.load(), vpyCallbackData->outputFrames.load());
            vpyCallbackData->vsapi->getFrameAsync(vpyCallbackData->requestedFrames, node, frameDoneCallback, vpyCallbackData);
            ++vpyCallbackData->requestedFrames;
        }
    }
}

using namespace X265_NS;

lib_path_t VPYInput::convertLibraryPath(std::string path)
    {
#if defined(_WIN32_WINNT)
        int size_needed = MultiByteToWideChar(CP_UTF8, 0, &path[0], (int)path.size(), NULL, 0);
        std::wstring wstrTo( size_needed, 0 );
        MultiByteToWideChar(CP_UTF8, 0, &path[0], (int)path.size(), &wstrTo[0], size_needed);
        return wstrTo;
#else
        return path;
#endif
    }

void VPYInput::parseVpyOptions(const char* _options)
{
    std::string options {_options}; options += ";";
    std::string optSeparator {";"};
    std::string valSeparator {"="};
    std::map<std::string, int> knownOptions {
        {std::string {"library"},  1},
        {std::string {"output"},   2},
        {std::string {"requests"}, 3}
    };

    auto start = 0U;
    auto end = options.find(optSeparator);

    while ((end = options.find(optSeparator, start)) != std::string::npos)
    {
        auto option = options.substr(start, end - start);
        auto valuePos = option.find(valSeparator);
        if (valuePos != std::string::npos)
        {
            auto key = option.substr(0U, valuePos);
            auto value = option.substr(valuePos + 1, option.length());
            switch (knownOptions[key])
            {
            case 1:
                vss_library_path = convertLibraryPath(value);
                general_log(nullptr, "vpy", X265_LOG_INFO, "using external VapourSynth library from %s\n", value.c_str());
                break;
            case 2:
                nodeIndex = std::stoi(value);
                break;
            case 3:
                vpyCallbackData.parallelRequests = std::stoi(value);
                break;
            }
        }
        else if (option.length() > 0)
        {
            general_log(nullptr, "vpy", X265_LOG_ERROR, "invalid option \"%s\" ignored\n", option.c_str());
        }
        start = end + optSeparator.length();
        end = options.find(optSeparator, start);
    }
}

VPYInput::VPYInput(InputFileInfo& info)
{
    if (info.readerOpts)
        parseVpyOptions(info.readerOpts);

    vs_open();
    if (!vss_library)
    {
        general_log(nullptr, "vpy", X265_LOG_ERROR, "failed to load VapourSynth\n");
        vpyFailed = true;
    }

    if (info.skipFrames)
    {
        nextFrame = info.skipFrames;
    }

    vpyCallbackData.outputFrames = nextFrame;
    vpyCallbackData.requestedFrames = nextFrame;
    vpyCallbackData.completedFrames = nextFrame;
    vpyCallbackData.startFrame = nextFrame;

    #if defined(__GNUC__) && __GNUC__ >= 8
    #pragma GCC diagnostic push
    #pragma GCC diagnostic ignored "-Wcast-function-type"
    #endif

    std::array<std::pair<void **, const char*>, 8> vss_func_list {{
        { reinterpret_cast<void **>(&vss_func.init),         (X86_64) ? "vsscript_init"         : "_vsscript_init@0"          },
        { reinterpret_cast<void **>(&vss_func.finalize),     (X86_64) ? "vsscript_finalize"     : "_vsscript_finalize@0"      },
        { reinterpret_cast<void **>(&vss_func.evaluateFile), (X86_64) ? "vsscript_evaluateFile" : "_vsscript_evaluateFile@12" },
        { reinterpret_cast<void **>(&vss_func.freeScript),   (X86_64) ? "vsscript_freeScript"   : "_vsscript_freeScript@4"    },
        { reinterpret_cast<void **>(&vss_func.getError),     (X86_64) ? "vsscript_getError"     : "_vsscript_getError@4"      },
        { reinterpret_cast<void **>(&vss_func.getOutput),    (X86_64) ? "vsscript_getOutput"    : "_vsscript_getOutput@8"     },
        { reinterpret_cast<void **>(&vss_func.getCore),      (X86_64) ? "vsscript_getCore"      : "_vsscript_getCore@4"       },
        { reinterpret_cast<void **>(&vss_func.getVSApi2),    (X86_64) ? "vsscript_getVSApi2"    : "_vsscript_getVSApi2@4"     }
    }};

    for (auto& vsscriptf : vss_func_list) {
        if (nullptr == (*(vsscriptf.first) = reinterpret_cast<void *>(vs_address(vsscriptf.second)))) {
            general_log(nullptr, "vpy", X265_LOG_ERROR, "failed to get vsscript function %s\n", vsscriptf.second);
            vpyFailed = true;
            return;
        }
    }

    #if defined(__GNUC__) && __GNUC__ >= 8
    #pragma GCC diagnostic pop
    #endif

    if (!vss_func.init())
    {
        general_log(nullptr, "vpy", X265_LOG_ERROR, "failed to initialize VapourSynth environment\n");
        vpyFailed = true;
        return;
    }

    vpyCallbackData.vsapi = vsapi = vss_func.getVSApi2(VAPOURSYNTH_API_VERSION);
    if (vss_func.evaluateFile(&script, info.filename, efSetWorkingDir))
    {
        general_log(nullptr, "vpy", X265_LOG_ERROR, "can't evaluate script: %s\n", vss_func.getError(script));
        vpyFailed = true;
        return;
    }
    if (nodeIndex > 0)
    {
        general_log(nullptr, "vpy", X265_LOG_INFO, "output node changed to %d\n", nodeIndex);
    }

    node = vss_func.getOutput(script, nodeIndex);
    if (!node)
    {
        general_log(nullptr, "vpy", X265_LOG_ERROR, "`%s' at output node %d has no video data\n", info.filename, nodeIndex);
        vpyFailed = true;
        return;
    }

    const VSCoreInfo* core_info = vsapi->getCoreInfo(vss_func.getCore(script));

    const VSVideoInfo* vi = vsapi->getVideoInfo(node);
    if (!isConstantFormat(vi))
    {
        general_log(nullptr, "vpy", X265_LOG_ERROR, "only constant video formats are supported\n");
        vpyFailed = true;
    }

    info.width = vi->width;
    info.height = vi->height;

    if (vpyCallbackData.parallelRequests == -1 || core_info->numThreads != vpyCallbackData.parallelRequests)
        vpyCallbackData.parallelRequests = core_info->numThreads;

    char errbuf[256];
    frame0 = vsapi->getFrame(nextFrame, node, errbuf, sizeof(errbuf));
    if (!frame0)
    {
        general_log(nullptr, "vpy", X265_LOG_ERROR, "%s occurred while getting frame 0\n", errbuf);
        vpyFailed = true;
        return;
    }

    vpyCallbackData.reorderMap[nextFrame] = frame0;
    ++vpyCallbackData.completedFrames;

    const VSMap* frameProps0 = vsapi->getFramePropsRO(frame0);

    info.sarWidth = vsapi->propNumElements(frameProps0, "_SARNum") > 0 ? vsapi->propGetInt(frameProps0, "_SARNum", 0, nullptr) : 0;
    info.sarHeight =vsapi->propNumElements(frameProps0, "_SARDen") > 0 ? vsapi->propGetInt(frameProps0, "_SARDen", 0, nullptr) : 0;
    if (vi->fpsNum == 0 && vi->fpsDen == 0) // VFR detection
    {
        int errDurNum, errDurDen;
        int64_t rateDen = vsapi->propGetInt(frameProps0, "_DurationNum", 0, &errDurNum);
        int64_t rateNum = vsapi->propGetInt(frameProps0, "_DurationDen", 0, &errDurDen);

        if (errDurNum || errDurDen)
        {
            general_log(nullptr, "vpy", X265_LOG_ERROR, "VFR: missing FPS values at frame 0");
            vpyFailed = true;
            return;
        }

        if (!rateNum)
        {
            general_log(nullptr, "vpy", X265_LOG_ERROR, "VFR: FPS numerator is zero at frame 0");
            vpyFailed = true;
            return;
        }

        /* Force CFR until we have support for VFR by x265 */
        info.fpsNum   = rateNum;
        info.fpsDenom = rateDen;
        general_log(nullptr, "vpy", X265_LOG_INFO, "VideoNode is VFR, but x265 doesn't support that at the moment. Forcing CFR\n");
    }
    else
    {
        info.fpsNum   = vi->fpsNum;
        info.fpsDenom = vi->fpsDen;
    }

    info.frameCount = vpyCallbackData.framesToRequest = vi->numFrames;
    info.depth = vi->format->bitsPerSample;

    if (info.encodeToFrame)
    {
        vpyCallbackData.framesToRequest = info.encodeToFrame + nextFrame;
    }

    if (vi->format->bitsPerSample >= 8 && vi->format->bitsPerSample <= 16)
    {
        if (vi->format->colorFamily == cmYUV)
        {
            if (vi->format->subSamplingW == 0 && vi->format->subSamplingH == 0) {
                info.csp = X265_CSP_I444;
            }
            else if (vi->format->subSamplingW == 1 && vi->format->subSamplingH == 0) {
                info.csp = X265_CSP_I422;
            }
            else if (vi->format->subSamplingW == 1 && vi->format->subSamplingH == 1) {
                info.csp = X265_CSP_I420;
            }
        }
        else if (vi->format->colorFamily == cmGray) {
            info.csp = X265_CSP_I400;
        }
    }
    else
    {
        general_log(nullptr, "vpy", X265_LOG_ERROR, "not supported pixel type: %s\n", vi->format->name);
        vpyFailed = true;
        return;
    }

    vpyCallbackData.isRunning = true;

    _info = info;
}

void VPYInput::startReader()
{
    general_log(nullptr, "vpy", X265_LOG_INFO, "using %d parallel requests\n", vpyCallbackData.parallelRequests);

    const int requestStart = vpyCallbackData.completedFrames;
    const int intitalRequestSize = std::min<int>(vpyCallbackData.parallelRequests, _info.frameCount - requestStart);
    vpyCallbackData.requestedFrames = requestStart + intitalRequestSize;

    for (int n = requestStart; n < requestStart + intitalRequestSize; n++)
        vsapi->getFrameAsync(n, node, frameDoneCallback, &vpyCallbackData);
}

void VPYInput::stopReader()
{
    vpyCallbackData.isRunning = false;

    while (vpyCallbackData.requestedFrames != vpyCallbackData.completedFrames)
    {
        general_log(nullptr, "vpy", X265_LOG_INFO, "waiting completion of %d requested frames...    \r", vpyCallbackData.requestedFrames.load() - vpyCallbackData.completedFrames.load());
        Sleep(400);
    }

    for (int frame = nextFrame; frame < vpyCallbackData.completedFrames; frame++)
    {
        const VSFrameRef* currentFrame = nullptr;
        currentFrame = vpyCallbackData.reorderMap[frame];
        vpyCallbackData.reorderMap.erase(frame);
        if (currentFrame)
        {
            vsapi->freeFrame(currentFrame);
        }
    }
}

void VPYInput::release()
{
    vpyCallbackData.isRunning = false;

    if (node)
        vsapi->freeNode(node);

    if (script)
        vss_func.freeScript(script);
    vss_func.finalize();

    if (vss_library)
        vs_close();

    if (frame_buffer)
        x265_free(frame_buffer);

    delete this;
}

bool VPYInput::readPicture(x265_picture& pic)
{
    const VSFrameRef* currentFrame = nullptr;

    if (nextFrame >= _info.frameCount || !vpyCallbackData.isRunning)
        return false;

    while (!!!vpyCallbackData.reorderMap[nextFrame])
    {
        Sleep(10); // wait for completition a bit
    }

    currentFrame = vpyCallbackData.reorderMap[nextFrame];
    vpyCallbackData.reorderMap.erase(nextFrame);
    ++vpyCallbackData.outputFrames;

    if (!currentFrame)
    {
        general_log(nullptr, "vpy", X265_LOG_ERROR, "error occurred while reading frame %d\n", nextFrame);
        vpyFailed = true;
    }

    pic.width = _info.width;
    pic.height = _info.height;
    pic.colorSpace = _info.csp;
    pic.bitDepth = _info.depth;

    if (frame_size == 0 || frame_buffer == nullptr) {
        for (int i = 0; i < x265_cli_csps[_info.csp].planes; i++)
            frame_size += vsapi->getFrameHeight(currentFrame, i) * vsapi->getStride(currentFrame, i);
        frame_buffer = reinterpret_cast<uint8_t*>(x265_malloc(frame_size));
    }

    pic.framesize = frame_size;

    uint8_t* ptr = frame_buffer;
    for (int i = 0; i < x265_cli_csps[_info.csp].planes; i++)
    {
        pic.stride[i] = vsapi->getStride(currentFrame, i);
        pic.planes[i] = ptr;
        auto len = vsapi->getFrameHeight(currentFrame, i) * pic.stride[i];

        memcpy(pic.planes[i], const_cast<unsigned char*>(vsapi->getReadPtr(currentFrame, i)), len);
        ptr += len;
    }

    vsapi->freeFrame(currentFrame);

    nextFrame++; // for Eof method

    return true;
}

