#!/bin/sh

export build_dir=${PWD}

declare -a builds=( 'znver1' 'znver2' 'znver3' 'znver4' 'sandybridge' 'haswell' 'skylake' 'raptorlake' 'nehalem' 'bdver1' )

CLEAN_BUILD_DIRS="yes" ./aMod-build-multilib.sh
for opt in "${builds[@]}"
do
  CPU_OPT="${opt}" CLEAN_BUILD_DIRS="yes" ./aMod-build-multilib.sh
done

gccver=$(gcc --version | awk '/gcc/ {print $3}')
if [ "${gccver}" == 'Built' ]; then
    export gccver=$(gcc --version | awk '/gcc/ {print $7}')
fi
latest_tag=$(git describe --abbrev=0 --tags)
tag_distance=$(git rev-list ${latest_tag}.. --count --first-parent)
if [ ${tag_distance} -ne "0" ]; then
    file_prefix="x265-x64-v${latest_tag}+${tag_distance}-aMod-gcc${gccver}"
else
    file_prefix="x265-x64-v${latest_tag}-aMod-gcc${gccver}"
fi

files="${build_dir}/no-opt/${file_prefix}.exe"

for opt in "${builds[@]}"
do
  files="${files} ${build_dir}/${opt}/${file_prefix}-opt-${opt}.exe"
done

7z a "${build_dir}/${file_prefix}+opt.7z" ${files}