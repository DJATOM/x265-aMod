#!/bin/sh

export build_dir=${PWD}

export THREADS_PER_BUILD=32
export THREADS_PER_TASK=$((${THREADS_PER_BUILD}/2))
export COMMON_OPTS="-Wno-deprecated -Wno-unused-parameter -Wno-unused-variable -DENABLE_PIC=ON -DENABLE_HDR10_PLUS=ON -DENABLE_SHARED=OFF -DSTATIC_LINK_CRT=ON -DCMAKE_TOOLCHAIN_FILE=${build_dir}/toolchain-x86_64-w64-mingw32.cmake"
export LINK_OPTS="-static -static-libgcc -static-libstdc++"

if [ "${CPU_OPT}" == '' ]; then
    CPU_OPT="no-opt"
    OPT_SUFFIX=''
else
    export COMMON_OPTS="${COMMON_OPTS} -DARCH_OPT=${CPU_OPT}"
    OPT_SUFFIX="-opt-${CPU_OPT}"
fi

[ ! -d ${build_dir}/${CPU_OPT} ] && mkdir ${build_dir}/${CPU_OPT}

cd ${build_dir}/${CPU_OPT}

if [ "${CLEAN_BUILD_DIRS}" == "yes" ]; then
    [ -d ${build_dir}/${CPU_OPT}/8bit ] && rm -R ${build_dir}/${CPU_OPT}/8bit
    [ -d ${build_dir}/${CPU_OPT}/10bit ] && rm -R ${build_dir}/${CPU_OPT}/10bit
    [ -d ${build_dir}/${CPU_OPT}/12bit ] && rm -R ${build_dir}/${CPU_OPT}/12bit
fi

[ ! -d ${build_dir}/${CPU_OPT}/8bit ] && mkdir ${build_dir}/${CPU_OPT}/8bit
[ ! -d ${build_dir}/${CPU_OPT}/10bit ] && mkdir ${build_dir}/${CPU_OPT}/10bit
[ ! -d ${build_dir}/${CPU_OPT}/12bit ] && mkdir ${build_dir}/${CPU_OPT}/12bit

cd ${build_dir}/${CPU_OPT}/12bit &&
cmake -G "MSYS Makefiles" ${COMMON_OPTS} -DHIGH_BIT_DEPTH=ON -DEXPORT_C_API=OFF -DENABLE_CLI=OFF -DMAIN12=ON ../../../../source 1>/dev/null &&
cmake --build . -j ${THREADS_PER_TASK} -- ${MAKEFLAGS} 1>/dev/null &&
cp libx265.a ${build_dir}/${CPU_OPT}/8bit/libx265_main12.a &

cd ${build_dir}/${CPU_OPT}/10bit &&
cmake -G "MSYS Makefiles" ${COMMON_OPTS} -DHIGH_BIT_DEPTH=ON -DEXPORT_C_API=OFF -DENABLE_CLI=OFF ../../../../source &&
cmake --build . -j ${THREADS_PER_TASK} -- ${MAKEFLAGS} &&
cp libx265.a ${build_dir}/${CPU_OPT}/8bit/libx265_main10.a
wait

cd ${build_dir}/${CPU_OPT}/8bit
cmake -G "MSYS Makefiles" ${COMMON_OPTS} -DCMAKE_EXE_LINKER_FLAGS="${LINK_OPTS}" -DEXTRA_LIB="x265_main10.a;x265_main12.a" -DEXTRA_LINK_FLAGS=-L. -DLINKED_10BIT=ON -DLINKED_12BIT=ON -DENABLE_CLI=ON -DENABLE_VAPOURSYNTH=ON -DENABLE_AVISYNTH=ON ../../../../source
sed -i CMakeFiles/cli.dir/linklibs.rsp -e 's/-Wl,-Bdynamic/-Wl,-Bstatic/'
cmake --build . -j ${THREADS_PER_BUILD} -- ${MAKEFLAGS}

cd ${build_dir}/${CPU_OPT}

export gccver=$(gcc --version | awk '/gcc/ {print $3}')
if [ "${gccver}" == 'Built' ]; then
    export gccver=$(gcc --version | awk '/gcc/ {print $7}')
fi
export latest_tag=$(git describe --abbrev=0 --tags)
export tag_distance=$(git rev-list ${latest_tag}.. --count --first-parent)
export file_prefix="x265-x64-v${latest_tag}+${tag_distance}-aMod-gcc${gccver}${OPT_SUFFIX}"
mv "${build_dir}/${CPU_OPT}/8bit/${file_prefix}.exe" "${build_dir}/${CPU_OPT}/${file_prefix}.exe"
strip "${build_dir}/${CPU_OPT}/${file_prefix}.exe"
upx -9 "${build_dir}/${CPU_OPT}/${file_prefix}.exe"

