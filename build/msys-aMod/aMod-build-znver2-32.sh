#!/bin/sh

export build_dir=${PWD}
export THREADS_PER_BUILD=24
[ ! -d ${build_dir}/znver2-32 ] && mkdir ${build_dir}/znver2-32
cd ${build_dir}/znver2-32
export COMMON_OPTS="-Wno-deprecated -DENABLE_HDR10_PLUS=ON -DHIGH_BIT_DEPTH=ON -DENABLE_SHARED=OFF -DENABLE_CLI=ON -DENABLE_PIC=ON -DSTATIC_LINK_CRT=ON -DENABLE_VAPOURSYNTH=ON -DENABLE_AVISYNTH=ON -DCMAKE_TOOLCHAIN_FILE=${build_dir}/toolchain-i686-w64-mingw32.cmake"
cmake -G "MSYS Makefiles" ${COMMON_OPTS} -DARCH_OPT=znver2 ../../../source
cmake --build . -j ${THREADS_PER_BUILD} -- ${MAKEFLAGS}
cd ${build_dir}
export gccver=$(gcc --version | awk '/gcc/ {print $3}')
export latest_tag=$(git describe --abbrev=0 --tags)
export tag_distance=$(git rev-list ${latest_tag}.. --count --first-parent)
export file_prefix="x265-x86-v${latest_tag}+${tag_distance}-aMod-gcc${gccver}"
strip "${build_dir}/znver2-32/${file_prefix}-opt-znver2.exe"
upx -9 "${build_dir}/znver2-32/${file_prefix}-opt-znver2.exe"

