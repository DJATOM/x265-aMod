#!/bin/sh

build_dir=${PWD}
THREADS_PER_BUILD=4
[ ! -d ${build_dir}/znver1 ] && mkdir ${build_dir}/znver1
[ ! -d ${build_dir}/znver2 ] && mkdir ${build_dir}/znver2
[ ! -d ${build_dir}/znver3 ] && mkdir ${build_dir}/znver3
[ ! -d ${build_dir}/sandybridge ] && mkdir ${build_dir}/sandybridge
[ ! -d ${build_dir}/haswell ] && mkdir ${build_dir}/haswell
[ ! -d ${build_dir}/skylake ] && mkdir ${build_dir}/skylake
[ ! -d ${build_dir}/nehalem ] && mkdir ${build_dir}/nehalem
export COMMON_OPTS="-Wno-deprecated -Wno-unused-parameter -Wno-unused-variable -DENABLE_HDR10_PLUS=ON -DHIGH_BIT_DEPTH=ON -DENABLE_SHARED=OFF -DENABLE_CLI=ON -DENABLE_PIC=ON -DSTATIC_LINK_CRT=ON -DENABLE_VAPOURSYNTH=ON -DENABLE_AVISYNTH=ON -DCMAKE_TOOLCHAIN_FILE=${build_dir}/toolchain-x86_64-w64-mingw32.cmake"
cd ${build_dir}/znver3 && cmake -G "MSYS Makefiles" ${COMMON_OPTS} -DARCH_OPT=znver3 ../../../source 1>/dev/null && make clean && make -j${THREADS_PER_BUILD} ${MAKEFLAGS} 1>/dev/null & 
cd ${build_dir}/znver2 && cmake -G "MSYS Makefiles" ${COMMON_OPTS} -DARCH_OPT=znver2 ../../../source 1>/dev/null && make clean && make -j${THREADS_PER_BUILD} ${MAKEFLAGS} 1>/dev/null & 
cd ${build_dir}/znver1 && cmake -G "MSYS Makefiles" ${COMMON_OPTS} -DARCH_OPT=znver1 ../../../source 1>/dev/null && make clean && make -j${THREADS_PER_BUILD} ${MAKEFLAGS} 1>/dev/null & 
cd ${build_dir}/sandybridge && cmake -G "MSYS Makefiles" ${COMMON_OPTS} -DARCH_OPT=sandybridge ../../../source 1>/dev/null && make clean && make -j${THREADS_PER_BUILD} ${MAKEFLAGS} 1>/dev/null & 
cd ${build_dir}/haswell && cmake -G "MSYS Makefiles" ${COMMON_OPTS} -DARCH_OPT=haswell ../../../source 1>/dev/null && make clean && make -j${THREADS_PER_BUILD} ${MAKEFLAGS} 1>/dev/null & 
cd ${build_dir}/skylake && cmake -G "MSYS Makefiles" ${COMMON_OPTS} -DARCH_OPT=skylake ../../../source 1>/dev/null && make clean && make -j${THREADS_PER_BUILD} ${MAKEFLAGS} 1>/dev/null & 
cd ${build_dir}/nehalem && cmake -G "MSYS Makefiles" ${COMMON_OPTS} -DARCH_OPT=nehalem ../../../source 1>/dev/null && make clean && make -j${THREADS_PER_BUILD} ${MAKEFLAGS} 1>/dev/null
wait
 
cd ${build_dir}
gccver=$(gcc --version | awk '/gcc/ {print $3}')
latest_tag=$(git describe --abbrev=0 --tags)
tag_distance=$(git rev-list ${latest_tag}.. --count --first-parent)
if [ ${tag_distance} -ne "0" ]; then
    file_prefix="x265-x64-v${latest_tag}+${tag_distance}-aMod-gcc${gccver}"
else
    file_prefix="x265-x64-v${latest_tag}-aMod-gcc${gccver}"
fi
strip "${build_dir}/znver1/${file_prefix}-opt-znver1.exe" && upx -9 "${build_dir}/znver1/${file_prefix}-opt-znver1.exe"
strip "${build_dir}/znver2/${file_prefix}-opt-znver2.exe" && upx -9 "${build_dir}/znver2/${file_prefix}-opt-znver2.exe"
strip "${build_dir}/znver3/${file_prefix}-opt-znver3.exe" && upx -9 "${build_dir}/znver3/${file_prefix}-opt-znver3.exe"
strip "${build_dir}/sandybridge/${file_prefix}-opt-sandybridge.exe" && upx -9 "${build_dir}/sandybridge/${file_prefix}-opt-sandybridge.exe"
strip "${build_dir}/haswell/${file_prefix}-opt-haswell.exe" && upx -9 "${build_dir}/haswell/${file_prefix}-opt-haswell.exe"
strip "${build_dir}/skylake/${file_prefix}-opt-skylake.exe" && upx -9 "${build_dir}/skylake/${file_prefix}-opt-skylake.exe"
strip "${build_dir}/nehalem/${file_prefix}-opt-nehalem.exe" && upx -9 "${build_dir}/nehalem/${file_prefix}-opt-nehalem.exe"
7z a "${build_dir}/${file_prefix}+opt.7z" "${build_dir}/no-opt/${file_prefix}.exe" \
"${build_dir}/znver1/${file_prefix}-opt-znver1.exe" "${build_dir}/znver2/${file_prefix}-opt-znver2.exe" "${build_dir}/znver3/${file_prefix}-opt-znver3.exe" \
"${build_dir}/sandybridge/${file_prefix}-opt-sandybridge.exe" "${build_dir}/haswell/${file_prefix}-opt-haswell.exe" \
"${build_dir}/skylake/${file_prefix}-opt-skylake.exe" "${build_dir}/nehalem/${file_prefix}-opt-nehalem.exe"