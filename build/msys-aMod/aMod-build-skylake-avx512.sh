#!/bin/sh

build_dir=${PWD}
[ ! -d ${build_dir}/skylake-avx512 ] && mkdir ${build_dir}/skylake-avx512
cd ${build_dir}/skylake-avx512
export COMMON_OPTS="-Wno-deprecated -DENABLE_HDR10_PLUS=ON -DHIGH_BIT_DEPTH=ON -DENABLE_SHARED=OFF -DENABLE_CLI=ON -DENABLE_PIC=ON -DSTATIC_LINK_CRT=ON -DENABLE_VAPOURSYNTH=ON -DENABLE_AVISYNTH=ON -DCMAKE_TOOLCHAIN_FILE=${build_dir}/toolchain-x86_64-w64-mingw32.cmake"
cmake -G "MSYS Makefiles" ${COMMON_OPTS} -DARCH_OPT=skylake-avx512 ../../../source
make -j24 ${MAKEFLAGS}
cd ${build_dir}
export gccver=$(gcc --version | awk '/gcc/ {print $3}')
export latest_tag=$(git describe --abbrev=0 --tags)
export tag_distance=$(git rev-list ${latest_tag}.. --count --first-parent)
export file_prefix="x265-x64-v${latest_tag}+${tag_distance}-aMod-gcc${gccver}"
strip "${build_dir}/skylake-avx512/${file_prefix}-opt-skylake-avx512.exe"
upx -9 "${build_dir}/skylake-avx512/${file_prefix}-opt-skylake-avx512.exe"