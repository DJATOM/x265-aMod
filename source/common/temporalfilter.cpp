/*****************************************************************************
* Copyright (C) 2013-2021 MulticoreWare, Inc
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

#include "temporalfilter.h"

#include "frame.h"
#include "slice.h"
#include "framedata.h"
#include "analysis.h"

using namespace X265_NS;

void OrigPicBuffer::addPicture(Frame* inFrame)
{
    m_mcstfPicList.pushFrontMCSTF(*inFrame);
}

void OrigPicBuffer::addEncPicture(Frame* inFrame)
{
    m_mcstfOrigPicFreeList.pushFrontMCSTF(*inFrame);
}

void OrigPicBuffer::addEncPictureToPicList(Frame* inFrame)
{
    m_mcstfOrigPicList.pushFrontMCSTF(*inFrame);
}

OrigPicBuffer::~OrigPicBuffer()
{
    while (!m_mcstfOrigPicList.empty())
    {
        Frame* curFrame = m_mcstfOrigPicList.popBackMCSTF();
        curFrame->destroy();
        delete curFrame;
    }

    while (!m_mcstfOrigPicFreeList.empty())
    {
        Frame* curFrame = m_mcstfOrigPicFreeList.popBackMCSTF();
        curFrame->destroy();
        delete curFrame;
    }
}

void OrigPicBuffer::setOrigPicList(Frame* inFrame, int frameCnt)
{
    Slice* slice = inFrame->m_encData->m_slice;
    uint8_t j = 0;
    for (int iterPOC = (inFrame->m_poc - inFrame->m_mcstf->s_range);
        iterPOC <= (inFrame->m_poc + inFrame->m_mcstf->s_range); iterPOC++)
    {
        if (iterPOC != inFrame->m_poc)
        {
            if (iterPOC < 0)
                continue;
            if (iterPOC >= frameCnt)
                break;

            Frame *iterFrame = m_mcstfPicList.getPOCMCSTF(iterPOC);
            X265_CHECK(iterFrame, "Reference frame not found in OPB");
            if (iterFrame != NULL)
            {
                slice->m_mcstfRefFrameList[1][j] = iterFrame;
                iterFrame->m_refPicCnt[1]--;
            }

            iterFrame = m_mcstfOrigPicList.getPOCMCSTF(iterPOC);
            if (iterFrame != NULL)
            {

                slice->m_mcstfRefFrameList[1][j] = iterFrame;

                iterFrame->m_refPicCnt[1]--;
                Frame *cFrame = m_mcstfOrigPicList.getPOCMCSTF(inFrame->m_poc);
                X265_CHECK(cFrame, "Reference frame not found in encoded OPB");
                cFrame->m_refPicCnt[1]--;
            }
            j++;
        }
    }
}

void OrigPicBuffer::recycleOrigPicList()
{
    Frame *iterFrame = m_mcstfPicList.first();

    while (iterFrame)
    {
        Frame *curFrame = iterFrame;
        iterFrame = iterFrame->m_nextMCSTF;
        if (!curFrame->m_refPicCnt[1])
        {
            m_mcstfPicList.removeMCSTF(*curFrame);
            iterFrame = m_mcstfPicList.first();
        }
    }

    iterFrame = m_mcstfOrigPicList.first();

    while (iterFrame)
    {
        Frame *curFrame = iterFrame;
        iterFrame = iterFrame->m_nextMCSTF;
        if (!curFrame->m_refPicCnt[1])
        {
            m_mcstfOrigPicList.removeMCSTF(*curFrame);
            *curFrame->m_isSubSampled = false;
            m_mcstfOrigPicFreeList.pushFrontMCSTF(*curFrame);
            iterFrame = m_mcstfOrigPicList.first();
        }
    }
}

void OrigPicBuffer::addPictureToFreelist(Frame* inFrame)
{
    m_mcstfOrigPicFreeList.pushBack(*inFrame);
}

TemporalFilter::TemporalFilter() {
    m_FrameSkip = 0;
    m_sourceWidth = 0;
    m_sourceHeight = 0,
    m_QP = 0;
    m_GOPSize = 0;
    m_framesToBeEncoded = 0;
    m_sliceTypeConfig = 3;
    m_numRef = 0;

    s_range = 2;
    s_chromaFactor = 0.55;
    s_sigmaMultiplier = 9.0;
    s_sigmaZeroPoint = 10.0;
    s_motionVectorFactor = 16;
    s_padding = 128;
}

void TemporalFilter::init(const x265_param* param)
{
    m_param = param;
    m_bitDepth = param->internalBitDepth;
    m_sourceWidth = param->sourceWidth;
    m_sourceHeight = param->sourceHeight;
    m_internalCsp = param->internalCsp;
    m_numComponents = (m_internalCsp != X265_CSP_I400) ? MAX_NUM_COMPONENT : 1;
}

int TemporalFilter::createRefPicInfo(MCTFReferencePicInfo* refFrame, x265_param* param)
{
    CHECKED_MALLOC_ZERO(refFrame->mvs, MV, sizeof(MV)* ((m_sourceWidth ) / 4) * ((m_sourceHeight ) / 4));
    refFrame->mvsStride = m_sourceWidth / 4;
    CHECKED_MALLOC_ZERO(refFrame->mvs0, MV, sizeof(MV)* ((m_sourceWidth ) / 16) * ((m_sourceHeight ) / 16));
    refFrame->mvsStride0 = m_sourceWidth / 16;
    CHECKED_MALLOC_ZERO(refFrame->mvs1, MV, sizeof(MV)* ((m_sourceWidth ) / 16) * ((m_sourceHeight ) / 16));
    refFrame->mvsStride1 = m_sourceWidth / 16;
    CHECKED_MALLOC_ZERO(refFrame->mvs2, MV, sizeof(MV)* ((m_sourceWidth ) / 16)*((m_sourceHeight ) / 16));
    refFrame->mvsStride2 = m_sourceWidth / 16;

    CHECKED_MALLOC_ZERO(refFrame->noise, int, sizeof(int) * ((m_sourceWidth) / 4) * ((m_sourceHeight) / 4));
    CHECKED_MALLOC_ZERO(refFrame->error, int, sizeof(int) * ((m_sourceWidth) / 4) * ((m_sourceHeight) / 4));

    refFrame->slicetype = X265_TYPE_AUTO;

    refFrame->compensatedPic = new PicYuv;
    refFrame->compensatedPic->create(param, true);

    return 1;
fail:
    return 0;
}

int TemporalFilter::motionErrorLuma(
    PicYuv *orig,
    PicYuv *buffer,
    int x,
    int y,
    int dx,
    int dy,
    int bs,
    int besterror)
{

    pixel* origOrigin = orig->m_picOrg[0];
    intptr_t origStride = orig->m_stride;
    pixel *buffOrigin = buffer->m_picOrg[0];
    intptr_t buffStride = buffer->m_stride;
    int error = 0;// dx * 10 + dy * 10;
    if (((dx | dy) & 0xF) == 0)
    {
        dx /= s_motionVectorFactor;
        dy /= s_motionVectorFactor;
        for (int y1 = 0; y1 < bs; y1++)
        {
            const pixel* origRowStart = origOrigin + (y + y1)*origStride + x;
            const pixel* bufferRowStart = buffOrigin + (y + y1 + dy)*buffStride + (x + dx);
            for (int x1 = 0; x1 < bs; x1 += 2)
            {
                int diff = origRowStart[x1] - bufferRowStart[x1];
                error += diff * diff;
                diff = origRowStart[x1 + 1] - bufferRowStart[x1 + 1];
                error += diff * diff;
            }
            if (error > besterror)
            {
                return error;
            }
        }
    }
    else
    {
        const int *xFilter = s_interpolationFilter[dx & 0xF];
        const int *yFilter = s_interpolationFilter[dy & 0xF];
        int tempArray[64 + 8][64];

        int iSum, iBase;
        for (int y1 = 1; y1 < bs + 7; y1++)
        {
            const int yOffset = y + y1 + (dy >> 4) - 3;
            const pixel *sourceRow = buffOrigin + (yOffset)*buffStride + 0;
            for (int x1 = 0; x1 < bs; x1++)
            {
                iSum = 0;
                iBase = x + x1 + (dx >> 4) - 3;
                const pixel *rowStart = sourceRow + iBase;

                iSum += xFilter[1] * rowStart[1];
                iSum += xFilter[2] * rowStart[2];
                iSum += xFilter[3] * rowStart[3];
                iSum += xFilter[4] * rowStart[4];
                iSum += xFilter[5] * rowStart[5];
                iSum += xFilter[6] * rowStart[6];

                tempArray[y1][x1] = iSum;
            }
        }

        const pixel maxSampleValue = (1 << m_bitDepth) - 1;
        for (int y1 = 0; y1 < bs; y1++)
        {
            const pixel *origRow = origOrigin + (y + y1)*origStride + 0;
            for (int x1 = 0; x1 < bs; x1++)
            {
                iSum = 0;
                iSum += yFilter[1] * tempArray[y1 + 1][x1];
                iSum += yFilter[2] * tempArray[y1 + 2][x1];
                iSum += yFilter[3] * tempArray[y1 + 3][x1];
                iSum += yFilter[4] * tempArray[y1 + 4][x1];
                iSum += yFilter[5] * tempArray[y1 + 5][x1];
                iSum += yFilter[6] * tempArray[y1 + 6][x1];

                iSum = (iSum + (1 << 11)) >> 12;
                iSum = iSum < 0 ? 0 : (iSum > maxSampleValue ? maxSampleValue : iSum);

                error += (iSum - origRow[x + x1]) * (iSum - origRow[x + x1]);
            }
            if (error > besterror)
            {
                return error;
            }
        }
    }
    return error;
}

void TemporalFilter::applyMotion(MV *mvs, uint32_t mvsStride, PicYuv *input, PicYuv *output)
{
    static const int lumaBlockSize = 8;
    int srcStride = 0;
    int dstStride = 0;
    int csx = 0, csy = 0;
    for (int c = 0; c < m_numComponents; c++)
    {
        const pixel maxValue = (1 << X265_DEPTH) - 1;

        const pixel *pSrcImage = input->m_picOrg[c];
        pixel *pDstImage = output->m_picOrg[c];

        if (c == 0)
        {
            srcStride = (int)input->m_stride;
            dstStride = (int)output->m_stride;
        }
        else
        {
            srcStride = (int)input->m_strideC;
            dstStride = (int)output->m_strideC;
            csx = CHROMA_H_SHIFT(m_internalCsp);
            csy = CHROMA_V_SHIFT(m_internalCsp);
        }
        const int blockSizeX = lumaBlockSize >> csx;
        const int blockSizeY = lumaBlockSize >> csy;
        const int height = input->m_picHeight >> csy;
        const int width = input->m_picWidth >> csx;

        for (int y = 0, blockNumY = 0; y + blockSizeY <= height; y += blockSizeY, blockNumY++)
        {
            for (int x = 0, blockNumX = 0; x + blockSizeX <= width; x += blockSizeX, blockNumX++)
            {
                int mvIdx = blockNumY * mvsStride + blockNumX;
                const MV &mv = mvs[mvIdx];
                const int dx = mv.x >> csx;
                const int dy = mv.y >> csy;
                const int xInt = mv.x >> (4 + csx);
                const int yInt = mv.y >> (4 + csy);

                const int *xFilter = s_interpolationFilter[dx & 0xf];
                const int *yFilter = s_interpolationFilter[dy & 0xf]; // will add 6 bit.
                const int numFilterTaps = 7;
                const int centreTapOffset = 3;

                int tempArray[lumaBlockSize + numFilterTaps][lumaBlockSize];

                for (int by = 1; by < blockSizeY + numFilterTaps; by++)
                {
                    const int yOffset = y + by + yInt - centreTapOffset;
                    const pixel *sourceRow = pSrcImage + yOffset * srcStride;
                    for (int bx = 0; bx < blockSizeX; bx++)
                    {
                        int iBase = x + bx + xInt - centreTapOffset;
                        const pixel *rowStart = sourceRow + iBase;

                        int iSum = 0;
                        iSum += xFilter[1] * rowStart[1];
                        iSum += xFilter[2] * rowStart[2];
                        iSum += xFilter[3] * rowStart[3];
                        iSum += xFilter[4] * rowStart[4];
                        iSum += xFilter[5] * rowStart[5];
                        iSum += xFilter[6] * rowStart[6];

                        tempArray[by][bx] = iSum;
                    }
                }

                pixel *pDstRow = pDstImage + y * dstStride;
                for (int by = 0; by < blockSizeY; by++, pDstRow += dstStride)
                {
                    pixel *pDstPel = pDstRow + x;
                    for (int bx = 0; bx < blockSizeX; bx++, pDstPel++)
                    {
                        int iSum = 0;

                        iSum += yFilter[1] * tempArray[by + 1][bx];
                        iSum += yFilter[2] * tempArray[by + 2][bx];
                        iSum += yFilter[3] * tempArray[by + 3][bx];
                        iSum += yFilter[4] * tempArray[by + 4][bx];
                        iSum += yFilter[5] * tempArray[by + 5][bx];
                        iSum += yFilter[6] * tempArray[by + 6][bx];

                        iSum = (iSum + (1 << 11)) >> 12;
                        iSum = iSum < 0 ? 0 : (iSum > maxValue ? maxValue : iSum);
                        *pDstPel = (pixel)iSum;
                    }
                }
            }
        }
    }
}

#if 0
/*
* Old Version: bilateralFilter
*/
void TemporalFilter::bilateralFilter(Frame* frame,
    MCTFReferencePicInfo* m_mctfRefList,
    double overallStrength)
{

    const int numRefs = frame->m_mcstf->m_numRef;

    for (int i = 0; i < numRefs; i++)
    {
        MCTFReferencePicInfo *ref = &m_mctfRefList[i];
        applyMotion(m_mctfRefList[i].mvs, m_mctfRefList[i].mvsStride, m_mctfRefList[i].picBuffer, ref->compensatedPic);
    }

    int refStrengthRow = 2;
    if (numRefs == s_range * 2)
    {
        refStrengthRow = 0;
    }
    else if (numRefs == s_range)
    {
        refStrengthRow = 1;
    }

    const double lumaSigmaSq = (m_QP - s_sigmaZeroPoint) * (m_QP - s_sigmaZeroPoint) * s_sigmaMultiplier;
    const double chromaSigmaSq = 30 * 30;

    PicYuv* orgPic = frame->m_fencPic;

    for (int c = 0; c < m_numComponents; c++)
    {
        int height, width;
        pixel *srcPelRow = NULL;
        intptr_t srcStride, correctedPicsStride = 0;

        if (c == 0)
        {
            height = orgPic->m_picHeight;
            width = orgPic->m_picWidth;
            srcPelRow = orgPic->m_picOrg[c];
            srcStride = orgPic->m_stride;
        }
        else
        {
            int csx = CHROMA_H_SHIFT(m_internalCsp);
            int csy = CHROMA_V_SHIFT(m_internalCsp);

            height = orgPic->m_picHeight >> csy;
            width = orgPic->m_picWidth >> csx;
            srcPelRow = orgPic->m_picOrg[c];
            srcStride = (int)orgPic->m_strideC;
        }

        const double sigmaSq = (!c) ? lumaSigmaSq : chromaSigmaSq;
        const double weightScaling = overallStrength * ((!c) ? 0.4 : s_chromaFactor);

        const pixel maxSampleValue = (1 << m_bitDepth) - 1;
        const double bitDepthDiffWeighting = 1024.0 / (maxSampleValue + 1);

        for (int y = 0; y < height; y++, srcPelRow += srcStride/*, dstPelRow += dstStride*/)
        {
            pixel *srcPel = srcPelRow;

            for (int x = 0; x < width; x++, srcPel++)
            {
                const int orgVal = (int)*srcPel;
                double temporalWeightSum = 1.0;
                double newVal = (double)orgVal;

                for (int i = 0; i < numRefs; i++)
                {
                    MCTFReferencePicInfo *refPicInfo = &m_mctfRefList[i];

                    if (c == 0)
                        correctedPicsStride = refPicInfo->compensatedPic->m_stride;
                    else
                        correctedPicsStride = refPicInfo->compensatedPic->m_strideC;

                    const pixel *pCorrectedPelPtr = refPicInfo->compensatedPic->m_picOrg[c] + (y * correctedPicsStride + x);
                    const int refVal = (int)*pCorrectedPelPtr;
                    double diff = (double)(refVal - orgVal);
                    diff *= bitDepthDiffWeighting;
                    double diffSq = diff * diff;

                    const int index = X265_MIN(1, std::abs(refPicInfo->origOffset) - 1);
                    const double weight = weightScaling * s_refStrengths[refStrengthRow][index] * exp(-diffSq / (2 * sigmaSq));

                    newVal += weight * refVal;
                    temporalWeightSum += weight;
                }
                newVal /= temporalWeightSum;
                pixel sampleVal = (pixel)round(newVal);
                sampleVal = (sampleVal < 0 ? 0 : (sampleVal > maxSampleValue ? maxSampleValue : sampleVal));
                //*dstPel = sampleVal;
                *srcPel = sampleVal;
            }
        }
    }
}

#else

/*
* New Version: bilateralFilter
*/
void TemporalFilter::bilateralFilter(Frame* frame,
    MCTFReferencePicInfo* m_mctfRefList,
    double overallStrength)
{

    const int numRefs = frame->m_mcstf->m_numRef;

    for (int i = 0; i < numRefs; i++)
    {
        MCTFReferencePicInfo *ref = &m_mctfRefList[i];
        applyMotion(m_mctfRefList[i].mvs, m_mctfRefList[i].mvsStride, m_mctfRefList[i].picBuffer, ref->compensatedPic);
    }

    int refStrengthRow = 2;
    if (numRefs == s_range * 2)
    {
        refStrengthRow = 0;
    }
    else if (numRefs == s_range)
    {
        refStrengthRow = 1;
    }

    const double lumaSigmaSq = (m_QP - s_sigmaZeroPoint) * (m_QP - s_sigmaZeroPoint) * s_sigmaMultiplier;
    const double chromaSigmaSq = 30 * 30;

    PicYuv* orgPic = frame->m_fencPic;

    for (int c = 0; c < m_numComponents; c++)
    {
        int height, width;
        pixel *srcPelRow = NULL;
        intptr_t srcStride, correctedPicsStride = 0;

        if (c == 0)
        {
            height = orgPic->m_picHeight;
            width = orgPic->m_picWidth;
            srcPelRow = orgPic->m_picOrg[c];
            srcStride = orgPic->m_stride;
        }
        else
        {
            int csx = CHROMA_H_SHIFT(m_internalCsp);
            int csy = CHROMA_V_SHIFT(m_internalCsp);

            height = orgPic->m_picHeight >> csy;
            width = orgPic->m_picWidth >> csx;
            srcPelRow = orgPic->m_picOrg[c];
            srcStride = (int)orgPic->m_strideC;
        }

        const double sigmaSq = (!c)  ? lumaSigmaSq : chromaSigmaSq;
        const double weightScaling = overallStrength * ( (!c) ? 0.4 : s_chromaFactor);

        const pixel maxSampleValue = (1 << m_bitDepth) - 1;
        const double bitDepthDiffWeighting = 1024.0 / (maxSampleValue + 1);

        const int blkSize = (!c) ? 8 : 4;

        for (int y = 0; y < height; y++, srcPelRow += srcStride)
        {
            pixel *srcPel = srcPelRow;

            for (int x = 0; x < width; x++, srcPel++)
            {
                const int orgVal = (int)*srcPel;
                double temporalWeightSum = 1.0;
                double newVal = (double)orgVal;

                if ((y % blkSize == 0) && (x % blkSize == 0))
                {
                    for (int i = 0; i < numRefs; i++)
                    {
                        MCTFReferencePicInfo *refPicInfo = &m_mctfRefList[i];

                        if (!c)
                            correctedPicsStride = refPicInfo->compensatedPic->m_stride;
                        else
                            correctedPicsStride = refPicInfo->compensatedPic->m_strideC;

                        double variance = 0, diffsum = 0;
                        for (int y1 = 0; y1 < blkSize - 1; y1++)
                        {
                            for (int x1 = 0; x1 < blkSize - 1; x1++)
                            {
                                int pix = *(srcPel + x1);
                                int pixR = *(srcPel + x1 + 1);
                                int pixD = *(srcPel + x1 + srcStride);

                                int ref = *(refPicInfo->compensatedPic->m_picOrg[c] + ((y + y1) * correctedPicsStride + x + x1));
                                int refR = *(refPicInfo->compensatedPic->m_picOrg[c] + ((y + y1) * correctedPicsStride + x + x1 + 1));
                                int refD = *(refPicInfo->compensatedPic->m_picOrg[c] + ((y + y1 + 1) * correctedPicsStride + x + x1));

                                int diff = pix - ref;
                                int diffR = pixR - refR;
                                int diffD = pixD - refD;

                                variance += diff * diff;
                                diffsum += (diffR - diff) * (diffR - diff);
                                diffsum += (diffD - diff) * (diffD - diff);
                            }
                        }

                        refPicInfo->noise[(y / blkSize) * refPicInfo->mvsStride + (x / blkSize)] = (int)round((300 * variance + 50) / (10 * diffsum + 50));
                    }
                }

                double minError = 9999999;
                for (int i = 0; i < numRefs; i++)
                {
                    MCTFReferencePicInfo *refPicInfo = &m_mctfRefList[i];
                    minError = X265_MIN(minError, (double)refPicInfo->error[(y / blkSize) * refPicInfo->mvsStride + (x / blkSize)]);
                }

                for (int i = 0; i < numRefs; i++)
                {
                    MCTFReferencePicInfo *refPicInfo = &m_mctfRefList[i];

                    const int error = refPicInfo->error[(y / blkSize) * refPicInfo->mvsStride + (x / blkSize)];
                    const int noise = refPicInfo->noise[(y / blkSize) * refPicInfo->mvsStride + (x / blkSize)];

                    const pixel *pCorrectedPelPtr = refPicInfo->compensatedPic->m_picOrg[c] + (y * correctedPicsStride + x);
                    const int refVal = (int)*pCorrectedPelPtr;
                    double diff = (double)(refVal - orgVal);
                    diff *= bitDepthDiffWeighting;
                    double diffSq = diff * diff;

                    const int index = X265_MIN(3, std::abs(refPicInfo->origOffset) - 1);
                    double ww = 1, sw = 1;
                    ww *= (noise < 25) ? 1 : 1.2;
                    sw *= (noise < 25) ? 1.3 : 0.8;
                    ww *= (error < 50) ? 1.2 : ((error > 100) ? 0.8 : 1);
                    sw *= (error < 50) ? 1.3 : 1;
                    ww *= ((minError + 1) / (error + 1));
                    const double weight = weightScaling * s_refStrengths[refStrengthRow][index] * ww * exp(-diffSq / (2 * sw * sigmaSq));

                    newVal += weight * refVal;
                    temporalWeightSum += weight;
                }
                newVal /= temporalWeightSum;
                pixel sampleVal = (pixel)round(newVal);
                sampleVal = (sampleVal < 0 ? 0 : (sampleVal > maxSampleValue ? maxSampleValue : sampleVal));
                //*dstPel = sampleVal;
                *srcPel = sampleVal;
            }
        }
    }
}
#endif

#if 0
/*Old Version: motionEstimationLuma*/

void TemporalFilter::motionEstimationLuma(MV *mvs, uint32_t mvStride, PicYuv *orig, PicYuv *buffer, int blockSize,
    MV *previous, uint32_t prevMvStride, int factor, bool doubleRes, int* minError)
{

    int range = 5;


    const int stepSize = blockSize;

    const int origWidth = orig->m_picWidth;
    const int origHeight = orig->m_picHeight;


    for (int blockY = 0; blockY + blockSize < origHeight; blockY += stepSize)
    {
        for (int blockX = 0; blockX + blockSize < origWidth; blockX += stepSize)
        {
            MV best(0, 0);
            int leastError = INT_MAX;

            if (previous == NULL)
            {
                range = 8;
            }
            else
            {

                for (int py = -2; py <= 2; py++)
                {
                    int testy = blockY / (2 * blockSize) + py;

                    for (int px = -2; px <= 2; px++)
                    {

                        int testx = blockX / (2 * blockSize) + px;
                        if ((testx >= 0) && (testx < origWidth / (2 * blockSize)) && (testy >= 0) && (testy < origHeight / (2 * blockSize)))
                        {
                            int mvIdx = testy * prevMvStride + testx;
                            MV old = previous[mvIdx];

                            int error = motionErrorLuma(orig, buffer, blockX, blockY, old.x * factor, old.y * factor, blockSize, leastError);
                            if (error < leastError)
                            {
                                best.set(old.x * factor, old.y * factor);
                                leastError = error;
                            }
                        }
                    }
                }

            }

            MV prevBest = best;
            for (int y2 = prevBest.y / s_motionVectorFactor - range; y2 <= prevBest.y / s_motionVectorFactor + range; y2++)
            {
                for (int x2 = prevBest.x / s_motionVectorFactor - range; x2 <= prevBest.x / s_motionVectorFactor + range; x2++)
                {
                    int error = motionErrorLuma(orig, buffer, blockX, blockY, x2 * s_motionVectorFactor, y2 * s_motionVectorFactor, blockSize, leastError/*best.error*/);
                    if (error < leastError)
                    {
                        best.set(x2 * s_motionVectorFactor, y2 * s_motionVectorFactor);
                        leastError = error;
                    }
                }
            }

            if (doubleRes)
            { // merge into one loop, probably with precision array (here [12, 3] or maybe [4, 1]) with setable number of iterations
                prevBest = best;
                int doubleRange = 3 * 4;
                for (int y2 = prevBest.y - doubleRange; y2 <= prevBest.y + doubleRange; y2 += 4)
                {
                    for (int x2 = prevBest.x - doubleRange; x2 <= prevBest.x + doubleRange; x2 += 4)
                    {
                        int error = motionErrorLuma(orig, buffer, blockX, blockY, x2, y2, blockSize, leastError);
                        if (error < leastError)
                        {
                            best.set(x2, y2);
                            leastError = error;
                        }
                    }
                }

                prevBest = best;
                doubleRange = 3;
                for (int y2 = prevBest.y - doubleRange; y2 <= prevBest.y + doubleRange; y2++)
                {
                    for (int x2 = prevBest.x - doubleRange; x2 <= prevBest.x + doubleRange; x2++)
                    {
                        int error = motionErrorLuma(orig, buffer, blockX, blockY, x2, y2, blockSize, leastError);
                        if (error < leastError)
                        {
                            best.set(x2, y2);
                            leastError = error;
                        }
                    }
                }
            }

            int mvIdx = (blockY / stepSize) * mvStride + (blockX / stepSize);
            mvs[mvIdx] = best;
            if (doubleRes)
                minError[mvIdx] = leastError;
        }
    }
}

#else

/*New Version: motionEstimationLuma*/
void TemporalFilter::motionEstimationLuma(MV *mvs, uint32_t mvStride, PicYuv *orig, PicYuv *buffer, int blockSize,
    MV *previous, uint32_t prevMvStride, int factor, bool doubleRes, int* minError)
{

    int range = doubleRes ? 0 : 5;


    const int stepSize = blockSize;

    const int origWidth = orig->m_picWidth;
    const int origHeight = orig->m_picHeight;


    for (int blockY = 0; blockY + blockSize <= origHeight; blockY += stepSize)
    {
        for (int blockX = 0; blockX + blockSize <= origWidth; blockX += stepSize)
        {
            MV best(0, 0);
            int leastError = INT_MAX;

            if (previous == NULL)
            {
                range = 8;
            }
            else
            {

                for (int py = -1; py <= 1; py++)
                {
                    int testy = blockY / (2 * blockSize) + py;

                    for (int px = -1; px <= 1; px++)
                    {

                        int testx = blockX / (2 * blockSize) + px;
                        if ((testx >= 0) && (testx < origWidth / (2 * blockSize)) && (testy >= 0) && (testy < origHeight / (2 * blockSize)))
                        {
                            int mvIdx = testy * prevMvStride + testx;
                            MV old = previous[mvIdx];
                            int error = motionErrorLuma(orig, buffer, blockX, blockY, old.x * factor, old.y * factor, blockSize, leastError);
                            if (error < leastError)
                            {
                                best.set(old.x * factor, old.y * factor);
                                leastError = error;
                            }
                        }
                    }
                }

                int error = motionErrorLuma(orig, buffer, blockX, blockY, 0, 0, blockSize, leastError);
                if (error < leastError)
                {
                    best.set(0, 0);
                    leastError = error;
                }

            }

            MV prevBest = best;
            for (int y2 = prevBest.y / s_motionVectorFactor - range; y2 <= prevBest.y / s_motionVectorFactor + range; y2++)
            {
                for (int x2 = prevBest.x / s_motionVectorFactor - range; x2 <= prevBest.x / s_motionVectorFactor + range; x2++)
                {
                    int error = motionErrorLuma(orig, buffer, blockX, blockY, x2 * s_motionVectorFactor, y2 * s_motionVectorFactor, blockSize, leastError);
                    if (error < leastError)
                    {
                        best.set(x2 * s_motionVectorFactor, y2 * s_motionVectorFactor);
                        leastError = error;
                    }
                }
            }

            if (doubleRes)
            { // merge into one loop, probably with precision array (here [12, 3] or maybe [4, 1]) with setable number of iterations
                prevBest = best;
                int doubleRange = 3 * 4;
                for (int y2 = prevBest.y - doubleRange; y2 <= prevBest.y + doubleRange; y2 += 4)
                {
                    for (int x2 = prevBest.x - doubleRange; x2 <= prevBest.x + doubleRange; x2 += 4)
                    {
                        int error = motionErrorLuma(orig, buffer, blockX, blockY, x2, y2, blockSize, leastError);
                        if (error < leastError)
                        {
                            best.set(x2, y2);
                            leastError = error;
                        }
                    }
                }

                prevBest = best;
                doubleRange = 3;
                for (int y2 = prevBest.y - doubleRange; y2 <= prevBest.y + doubleRange; y2++)
                {
                    for (int x2 = prevBest.x - doubleRange; x2 <= prevBest.x + doubleRange; x2++)
                    {
                        int error = motionErrorLuma(orig, buffer, blockX, blockY, x2, y2, blockSize, leastError);
                        if (error < leastError)
                        {
                            best.set(x2, y2);
                            leastError = error;
                        }
                    }
                }
            }

            if (blockY > 0)
            {
                MV aboveMV = mvs[(blockX / stepSize, (blockY - stepSize) / stepSize)];
                int error = motionErrorLuma(orig, buffer, blockX, blockY, aboveMV.x, aboveMV.y, blockSize, leastError);
                if (error < leastError)
                {
                    best.set(aboveMV.x, aboveMV.y);
                    leastError = error;
                }
            }
            if (blockX > 0)
            {
                MV leftMV = mvs[((blockX - stepSize) / stepSize, blockY / stepSize)];
                int error = motionErrorLuma(orig, buffer, blockX, blockY, leftMV.x, leftMV.y, blockSize, leastError);
                if (error < leastError)
                {
                    best.set(leftMV.x, leftMV.y);
                    leastError = error;
                }
            }

            // calculate average
            double avg = 0.0;
            for (int x1 = 0; x1 < blockSize; x1++)
            {
                for (int y1 = 0; y1 < blockSize; y1++)
                {
                    avg = avg + *(orig->m_picOrg[0] + (blockX + x1 + orig->m_stride * (blockY + y1)));
                }
            }
            avg = avg / (blockSize * blockSize);

            // calculate variance
            double variance = 0;
            for (int x1 = 0; x1 < blockSize; x1++)
            {
                for (int y1 = 0; y1 < blockSize; y1++)
                {
                    int pix = *(orig->m_picOrg[0] + (blockX + x1 + orig->m_stride * (blockY + y1)));
                    variance = variance + (pix - avg) * (pix - avg);
                }
            }

            leastError = (int)(20 * ((leastError + 5.0) / (variance + 5.0)) + (leastError / (blockSize * blockSize)) / 50);

            int mvIdx = (blockY / stepSize) * mvStride + (blockX / stepSize);
            mvs[mvIdx] = best;
            if (doubleRes)
                minError[mvIdx] = leastError;
        }
    }
}
#endif

void TemporalFilter::subsampleLuma(PicYuv *input, PicYuv *output, int factor)
{

    int newWidth = output->m_picWidth;
    int newHeight = output->m_picHeight;

    pixel* srcRow = input->m_picOrg[0];
    intptr_t srcStride = input->m_stride;

    pixel *dstRow = output->m_picOrg[0];
    intptr_t dstStride = output->m_stride;

    for (int y = 0; y < newHeight; y++, srcRow += factor * srcStride, dstRow += dstStride)
    {
        pixel *inRow = srcRow;
        pixel *inRowBelow = srcRow + srcStride;
        pixel *target = dstRow;

        for (int x = 0; x < newWidth; x++)
        {
            target[x] = (inRow[0] + inRowBelow[0] + inRow[1] + inRowBelow[1] + 2) >> 2;
            inRow += 2;
            inRowBelow += 2;
        }
    }

    // output.extendPicBorder();
    extendPicBorder(output->m_picOrg[0], output->m_stride, output->m_picWidth, output->m_picHeight, output->m_lumaMarginX, output->m_lumaMarginY);
}

void TemporalFilter::destroyRefPicInfo(MCTFReferencePicInfo* curFrame)
{
    if (curFrame)
    {
        if (curFrame->compensatedPic)
        {
            curFrame->compensatedPic->destroy();
            delete curFrame->compensatedPic;
        }

        if (curFrame->mvs)
            X265_FREE(curFrame->mvs);
        if (curFrame->mvs0)
            X265_FREE(curFrame->mvs0);
        if (curFrame->mvs1)
            X265_FREE(curFrame->mvs1);
        if (curFrame->mvs2)
            X265_FREE(curFrame->mvs2);
        if (curFrame->noise)
            X265_FREE(curFrame->noise);
        if (curFrame->error)
            X265_FREE(curFrame->error);
    }
}
