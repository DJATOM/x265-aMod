#!/bin/sh

export build_dir=${PWD}
export THREADS_PER_BUILD=24
export THREADS_PER_TASK=$((${THREADS_PER_BUILD}/2))
export COMMON_OPTS="-Wno-deprecated -DENABLE_PIC=ON -DENABLE_HDR10_PLUS=ON -DENABLE_SHARED=OFF -DSTATIC_LINK_CRT=ON -DENABLE_VAPOURSYNTH=ON -DENABLE_AVISYNTH=ON -DCMAKE_TOOLCHAIN_FILE=${build_dir}/toolchain-x86_64-w64-mingw32.cmake"
[ ! -d ${build_dir}/no-opt ] && mkdir ${build_dir}/no-opt
cd ${build_dir}/no-opt
[ ! -d ${build_dir}/no-opt/8bit ] && mkdir ${build_dir}/no-opt/8bit
[ ! -d ${build_dir}/no-opt/10bit ] && mkdir ${build_dir}/no-opt/10bit
[ ! -d ${build_dir}/no-opt/12bit ] && mkdir ${build_dir}/no-opt/12bit

cd ${build_dir}/no-opt/12bit && 
cmake -G "MSYS Makefiles" ${COMMON_OPTS} -DHIGH_BIT_DEPTH=ON -DEXPORT_C_API=OFF -DENABLE_CLI=OFF -DMAIN12=ON ../../../../source 1>/dev/null &&
cmake --build . -j ${THREADS_PER_TASK} -- ${MAKEFLAGS} 1>/dev/null &&
cp libx265.a ${build_dir}/no-opt/8bit/libx265_main12.a &

cd ${build_dir}/no-opt/10bit &&
cmake -G "MSYS Makefiles" ${COMMON_OPTS} -DHIGH_BIT_DEPTH=ON -DEXPORT_C_API=OFF -DENABLE_CLI=OFF ../../../../source &&
cmake --build . -j ${THREADS_PER_TASK} -- ${MAKEFLAGS} &&
cp libx265.a ${build_dir}/no-opt/8bit/libx265_main10.a
wait

cd ${build_dir}/no-opt/8bit
cmake -G "MSYS Makefiles" ${COMMON_OPTS} -DEXTRA_LIB="x265_main10.a;x265_main12.a" -DEXTRA_LINK_FLAGS=-L. -DLINKED_10BIT=ON -DLINKED_12BIT=ON -DENABLE_CLI=ON -DENABLE_VAPOURSYNTH=ON -DENABLE_AVISYNTH=ON ../../../../source
cmake --build . -j ${THREADS_PER_BUILD} -- ${MAKEFLAGS}

cd ${build_dir}/no-opt

export gccver=$(gcc --version | awk '/gcc/ {print $3}')
export latest_tag=$(git describe --abbrev=0 --tags)
export tag_distance=$(git rev-list ${latest_tag}.. --count --first-parent)
export file_prefix="x265-x64-v${latest_tag}+${tag_distance}-aMod-gcc${gccver}"
mv "${build_dir}/no-opt/8bit/${file_prefix}.exe" "${build_dir}/no-opt/${file_prefix}.exe"
strip "${build_dir}/no-opt/${file_prefix}.exe"
upx -9 "${build_dir}/no-opt/${file_prefix}.exe"

