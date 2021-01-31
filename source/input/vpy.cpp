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

using namespace X265_NS;

void __stdcall frameDoneCallback(void* userData, const VSFrameRef* f, const int n, VSNodeRef*, const char* errorMsg)
{
    reinterpret_cast<VPYInput*>(userData)->setAsyncFrame(n, f, errorMsg);
}

void VPYInput::setAsyncFrame(int n, const VSFrameRef* f, const char* errorMsg)
{
    if (errorMsg) {
        sprintf(frameError, "%s\n", errorMsg);
        vpyFailed = true;
    }

    if (f) {
        ++completedFrames;
        frameMap[n].second = f;
    }

    SetEvent(frameMap[n].first);
}

const VSFrameRef* VPYInput::getAsyncFrame(int n)
{
    WaitForSingleObject(frameMap[n].first, INFINITE);
    const VSFrameRef *frame = frameMap[n].second;
    CloseEvent(frameMap[n].first);
    frameMap.erase(n);

    if (requestedFrames < framesToRequest && isRunning)
    {
        vsapi->getFrameAsync(requestedFrames, node, frameDoneCallback, this);
        ++requestedFrames;
    }

    return frame;
}

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
                parallelRequests = std::stoi(value);
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

    requestedFrames = nextFrame;
    completedFrames = nextFrame;

    #if defined(__GNUC__) && __GNUC__ >= 8
    #pragma GCC diagnostic push
    #pragma GCC diagnostic ignored "-Wcast-function-type"
    #endif

    std::array<std::pair<void **, const char*>, 8> vss_func_list {{
        { reinterpret_cast<void **>(&vss_func.init),         (VPY_64) ? "vsscript_init"         : "_vsscript_init@0"          },
        { reinterpret_cast<void **>(&vss_func.finalize),     (VPY_64) ? "vsscript_finalize"     : "_vsscript_finalize@0"      },
        { reinterpret_cast<void **>(&vss_func.evaluateFile), (VPY_64) ? "vsscript_evaluateFile" : "_vsscript_evaluateFile@12" },
        { reinterpret_cast<void **>(&vss_func.freeScript),   (VPY_64) ? "vsscript_freeScript"   : "_vsscript_freeScript@4"    },
        { reinterpret_cast<void **>(&vss_func.getError),     (VPY_64) ? "vsscript_getError"     : "_vsscript_getError@4"      },
        { reinterpret_cast<void **>(&vss_func.getOutput),    (VPY_64) ? "vsscript_getOutput"    : "_vsscript_getOutput@8"     },
        { reinterpret_cast<void **>(&vss_func.getCore),      (VPY_64) ? "vsscript_getCore"      : "_vsscript_getCore@4"       },
        { reinterpret_cast<void **>(&vss_func.getVSApi2),    (VPY_64) ? "vsscript_getVSApi2"    : "_vsscript_getVSApi2@4"     }
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

    vsapi = vss_func.getVSApi2(VAPOURSYNTH_API_VERSION);
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

    if (parallelRequests == -1 || core_info->numThreads < parallelRequests)
        parallelRequests = core_info->numThreads;

    char errbuf[256];
    const VSFrameRef* frame0 = vsapi->getFrame(nextFrame, node, errbuf, sizeof(errbuf));
    if (!frame0)
    {
        general_log(nullptr, "vpy", X265_LOG_ERROR, "%s occurred while getting frame 0\n", errbuf);
        vpyFailed = true;
        return;
    }

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

    info.frameCount = framesToRequest = vi->numFrames;
    info.depth = vi->format->bitsPerSample;

    if (info.encodeToFrame)
    {
        framesToRequest = info.encodeToFrame + nextFrame;
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

    vsapi->freeFrame(frame0); // probably a waste of resources, but who cares. I'd like to fire and forget that here rather than leave possible duoble deletion

    isRunning = true;

    _info = info;
}

void VPYInput::startReader()
{
    general_log(nullptr, "vpy", X265_LOG_INFO, "using %d parallel requests\n", parallelRequests);

    for (int i = nextFrame; i <= framesToRequest; i++)
    {
        if (NULL == (frameMap[i].first = CreateEvent(NULL, false, false, NULL)))
        {
            general_log(nullptr, "vpy", X265_LOG_ERROR, "failed to create async event for frame %d\n", i);
            vpyFailed = true;
            isRunning = false;
            return;
        }
    }

    const int requestStart = completedFrames;
    const int intitalRequestSize = std::min<int>(parallelRequests, _info.frameCount - requestStart);
    requestedFrames = requestStart + intitalRequestSize;

    for (int n = requestStart; n < requestStart + intitalRequestSize; n++)
        vsapi->getFrameAsync(n, node, frameDoneCallback, this);

}

void VPYInput::stopReader()
{
    isRunning = false;

    while (requestedFrames != completedFrames)
    {
        general_log(nullptr, "vpy", X265_LOG_INFO, "waiting completion of %d requested frames...    \r", requestedFrames.load() - completedFrames.load());
        Sleep(400);
    }

    for (auto &iter : frameMap)
    {
        if (iter.second.second != nullptr)
            vsapi->freeFrame(iter.second.second);
    }
}

void VPYInput::release()
{
    isRunning = false;

    if (vpyFailed)
        for (auto &iter : frameMap)
        {
            if (iter.second.second != nullptr)
                vsapi->freeFrame(iter.second.second);
        }

    for (int i = 0; i < framesToRequest; i++)
    {
        if (frameMap.count(i)>0)
            if(frameMap[i].first)
                CloseEvent(frameMap[i].first);
    }

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

    if (nextFrame >= _info.frameCount || !isRunning)
        return false;

    currentFrame = getAsyncFrame(nextFrame);

    if (!currentFrame)
    {
        fprintf(stderr, "%*s\r", 130, " "); // make it more readable
        general_log(nullptr, "vpy", X265_LOG_ERROR, "error occurred while reading frame %d - %s", nextFrame, frameError);
        framesToRequest = nextFrame;
        vpyFailed = true;
        return false;
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

