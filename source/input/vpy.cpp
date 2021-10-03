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

void VS_CC frameDoneCallback(void* userData, const VSFrame* f, const int n, VSNode*, const char* errorMsg)
{
    reinterpret_cast<VPYInput*>(userData)->setAsyncFrame(n, f, errorMsg);
}

void VS_CC logMessageHandler(int msgType, const char* msg, void*)
{
    auto vsToX265LogLevel = [msgType]()
    {
        switch (msgType)
        {
            case mtDebug: return X265_LOG_DEBUG;
            case mtInformation: return X265_LOG_INFO;
            case mtWarning: return X265_LOG_WARNING;
            case mtCritical: return X265_LOG_WARNING;
            case mtFatal: return X265_LOG_ERROR;
            default: return X265_LOG_FULL;
        }
    };
    general_log(nullptr, "vpy", vsToX265LogLevel(), "%s\n", msg);
}

void VPYInput::setAsyncFrame(int n, const VSFrame* f, const char* errorMsg)
{
    if (errorMsg)
    {
        sprintf(frameError, "%s\n", errorMsg);
        vpyFailed = true;
    }

    if (f)
    {
        ++completedFrames;
        frameMap[n].second = f;
    }

    SetEvent(frameMap[n].first);
}

const VSFrame* VPYInput::getAsyncFrame(int n)
{
    WaitForSingleObject(frameMap[n].first, INFINITE);
    const VSFrame *frame = frameMap[n].second;
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
        {std::string {"library"},        1},
        {std::string {"output"},         2},
        {std::string {"requests"},       3},
        {std::string {"use-script-sar"}, 4}
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
            case 4:
                useScriptSar = static_cast<bool>(std::stoi(value));
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
        general_log(nullptr, "vpy", X265_LOG_ERROR, "failed to load VSScript\n");
        vpyFailed = true;
        return;
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

    getVSScriptAPI = reinterpret_cast<func_vssapi>(vs_address("getVSScriptAPI"));
    if (!getVSScriptAPI)
    {
        general_log(nullptr, "vpy", X265_LOG_ERROR, "failed to load getVSScriptAPI function. Upgrade Vapoursynth to R55 or never!\n");
        vpyFailed = true;
        return;
    }

    #if defined(__GNUC__) && __GNUC__ >= 8
    #pragma GCC diagnostic pop
    #endif

    vssapi = getVSScriptAPI(VSSCRIPT_API_VERSION);
    if (!vssapi)
    {
        general_log(nullptr, "vpy", X265_LOG_ERROR, "failed to initialize VSScript\n");
        vpyFailed = true;
        return;
    }

    vsapi = vssapi->getVSAPI(VAPOURSYNTH_API_VERSION);
    if (!vsapi)
    {
        general_log(nullptr, "vpy", X265_LOG_ERROR, "failed to get VapourSynth API pointer\n");
        vpyFailed = true;
        return;
    }

    core = vsapi->createCore(0);
    vsapi->addLogHandler(logMessageHandler, nullptr, nullptr, core);
    script = vssapi->createScript(core);
    vssapi->evalSetWorkingDir(script, 1);
    vssapi->evaluateFile(script, info.filename);

    if (vssapi->getError(script))
    {
        general_log(nullptr, "vpy", X265_LOG_ERROR, "script evaluation failed: %s\n", vssapi->getError(script));
        vpyFailed = true;
        return;
    }

    if (nodeIndex > 0)
    {
        general_log(nullptr, "vpy", X265_LOG_INFO, "output node changed to %d\n", nodeIndex);
    }

    node = vssapi->getOutputNode(script, nodeIndex);
    if (!node || vsapi->getNodeType(node) != mtVideo)
    {
        general_log(nullptr, "vpy", X265_LOG_ERROR, "`%s' at output node %d has no video data\n", info.filename, nodeIndex);
        vpyFailed = true;
        return;
    }

    VSCoreInfo core_info;
    vsapi->getCoreInfo(vssapi->getCore(script), &core_info);

    const VSVideoInfo* vi = vsapi->getVideoInfo(node);
    if (!vsh::isConstantVideoFormat(vi))
    {
        general_log(nullptr, "vpy", X265_LOG_ERROR, "only constant video formats are supported\n");
        vpyFailed = true;
    }

    info.width = vi->width;
    info.height = vi->height;

    if (parallelRequests == -1 || core_info.numThreads < parallelRequests)
        parallelRequests = core_info.numThreads;

    char errbuf[256];
    const VSFrame* frame0 = vsapi->getFrame(nextFrame, node, errbuf, sizeof(errbuf));
    if (!frame0)
    {
        general_log(nullptr, "vpy", X265_LOG_ERROR, "%s occurred while getting frame 0\n", errbuf);
        vpyFailed = true;
        return;
    }

    const VSMap* frameProps0 = vsapi->getFramePropertiesRO(frame0);

    info.sarWidth  = vsapi->mapNumElements(frameProps0, "_SARNum") > 0 && useScriptSar ? vsapi->mapGetInt(frameProps0, "_SARNum", 0, nullptr) : 0;
    info.sarHeight = vsapi->mapNumElements(frameProps0, "_SARDen") > 0 && useScriptSar ? vsapi->mapGetInt(frameProps0, "_SARDen", 0, nullptr) : 0;

    if (vi->fpsNum == 0 && vi->fpsDen == 0) // VFR detection
    {
        int errDurNum, errDurDen;
        int64_t rateDen = vsapi->mapGetInt(frameProps0, "_DurationNum", 0, &errDurNum);
        int64_t rateNum = vsapi->mapGetInt(frameProps0, "_DurationDen", 0, &errDurDen);

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
    info.depth = vi->format.bitsPerSample;

    if (info.encodeToFrame)
    {
        framesToRequest = info.encodeToFrame + nextFrame;
    }

    if (vi->format.bitsPerSample >= 8 && vi->format.bitsPerSample <= 16)
    {
        if (vi->format.colorFamily == cfYUV)
        {
            if (vi->format.subSamplingW == 0 && vi->format.subSamplingH == 0)
            {
                info.csp = X265_CSP_I444;
            }
            else if (vi->format.subSamplingW == 1 && vi->format.subSamplingH == 0)
            {
                info.csp = X265_CSP_I422;
            }
            else if (vi->format.subSamplingW == 1 && vi->format.subSamplingH == 1)
            {
                info.csp = X265_CSP_I420;
            }
        }
        else if (vi->format.colorFamily == cfGray)
        {
            info.csp = X265_CSP_I400;
        }
    }
    else
    {
        char formatNname[32];
        vsapi->getVideoFormatName(&vi->format, formatNname);
        general_log(nullptr, "vpy", X265_LOG_ERROR, "not supported pixel type: %s\n", formatNname);
        vpyFailed = true;
        return;
    }

    vsapi->freeFrame(frame0);

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
        vssapi->freeScript(script);

    if (vss_library)
        vs_close();

    if (frame_buffer)
        x265_free(frame_buffer);

    delete this;
}

bool VPYInput::readPicture(x265_picture& pic)
{
    const VSFrame* currentFrame = nullptr;

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

