#!/bin/sh

build_dir=${PWD}
THREADS_PER_BUILD=24
[ ! -d ${build_dir}/sandybridge-12b ] && mkdir ${build_dir}/sandybridge-12b
cd ${build_dir}/sandybridge-12b
export COMMON_OPTS="-Wno-deprecated -DENABLE_HDR10_PLUS=ON -DHIGH_BIT_DEPTH=ON -DENABLE_SHARED=OFF -DENABLE_CLI=ON -DENABLE_PIC=ON -DSTATIC_LINK_CRT=ON -DENABLE_VAPOURSYNTH=ON -DENABLE_AVISYNTH=ON -DCMAKE_TOOLCHAIN_FILE=${build_dir}/toolchain-x86_64-w64-mingw32.cmake"
cmake -G "MSYS Makefiles" ${COMMON_OPTS} -DARCH_OPT=sandybridge ../../../source
make clean
make -j${THREADS_PER_BUILD} ${MAKEFLAGS}
cd ${build_dir}
gccver=$(gcc --version | awk '/gcc/ {print $3}')
latest_tag=$(git describe --abbrev=0 --tags)
tag_distance=$(git rev-list ${latest_tag}.. --count --first-parent)
file_prefix="x265-x64-v${latest_tag}+${tag_distance}-aMod-gcc${gccver}"
strip "${build_dir}/sandybridge-12b/${file_prefix}-opt-sandybridge.exe"
upx -9 "${build_dir}/sandybridge-12b/${file_prefix}-opt-sandybridge.exe"