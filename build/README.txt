= Mandatory Prerequisites =

* GCC, MSVC (9, 10, 11, 12), Xcode or Intel C/C++
* CMake 2.8.8 or later http://www.cmake.org
* On linux, ccmake is helpful, usually a package named cmake-curses-gui 

Note: MSVC12 requires cmake 2.8.11 or later

Note: When the SVE/SVE2 instruction set of Arm AArch64 architecture is to be used, the GCC10.x and onwards must
      be installed in order to compile x265.


= Optional Prerequisites =

1. To compile assembly primitives (performance) 
   a) If you are using release 2.6 or older, download and install Yasm 1.2.0 or later, 

   For Windows, download the latest yasm executable
   http://yasm.tortall.net/Download.html and copy the EXE into
   C:\Windows or somewhere else in your %PATH% that a 32-bit app (cmake)
   can find it. If it is not in the path, you must manually tell cmake
   where to find it.  Note: you do not need the vsyasm packages, x265
   does not use them.  You only need the yasm executable itself.

   On Linux, the packaged yasm may be older than 1.2, in which case
   so you will need get the latest source and build it yourself.

   Once YASM is properly installed, run cmake to regenerate projects. If you
   do not see the below line in the cmake output, YASM is not in the PATH.

   -- Found Yasm 1.3.0 to build assembly primitives

   Now build the encoder and run x265 -V:

   x265 [info]: using cpu capabilities: MMX, SSE2, ...

   If cpu capabilities line says 'none!', then the encoder was built
   without yasm.

   b) If you are building from the default branch after release 2.6, download and install nasm 2.13 or newer
   
   For windows and linux, you can download the nasm installer from http://www.nasm.us/pub/nasm/releasebuilds/?C=M;O=D.
   Make sure that it is in your PATH environment variable (%PATH% in windows, and $PATH in linux) so that cmake
   can find it.

   Once NASM is properly installed, run cmake to regenerate projects. If you
   do not see the below line in the cmake output, NASM is not in the PATH.

   -- Found Nasm 2.13 to build assembly primitives

   Now build the encoder and run x265 -V:

   x265 [info]: using cpu capabilities: MMX, SSE2, ...

   If cpu capabilities line says 'none!', then the encoder was built
   without nasm and will be considerably slower for performance.

2. VisualLeakDetector (Windows Only)

   Download from https://vld.codeplex.com/releases and install. May need
   to re-login in order for it to be in your %PATH%.  Cmake will find it
   and enable leak detection in debug builds without any additional work.

   If VisualLeakDetector is not installed, cmake will complain a bit, but
   it is completely harmless.


= Build Instructions Linux =

1. Use cmake to generate Makefiles: cmake ../source
2. Build x265:                      make

  Or use our shell script which runs cmake then opens the curses GUI to
  configure build options

1. cd build/linux ; ./make-Makefiles.bash
2. make


= Build Instructions Windows =

We recommend you use one of the make-solutions.bat files in the appropriate
build/ sub-folder for your preferred compiler.  They will open the cmake-gui
to configure build options, click configure until no more red options remain,
then click generate and exit.  There should now be an x265.sln file in the
same folder, open this in Visual Studio and build it.

= Version number considerations =

Note that cmake will update X265_VERSION each time cmake runs, if you are
building out of a Mercurial source repository.  If you are building out of
a release source package, the version will not change.  If Mercurial is not
found, the version will be "unknown".

= Build Instructions for cross-compilation for Arm AArch64 Targets=

When the target platform is based on Arm AArch64 architecture, the x265 can be
built in x86 platforms. However, the CMAKE_C_COMPILER and CMAKE_CXX_COMPILER
enviroment variables should be set to point to the cross compilers of the
appropriate gcc. For example:

1. export CMAKE_C_COMPILER=aarch64-unknown-linux-gnu-gcc
2. export CMAKE_CXX_COMPILER=aarch64-unknown-linux-gnu-g++

The default ones are aarch64-linux-gnu-gcc and aarch64-linux-gnu-g++.
Then, the normal building process can be followed.

Moreover, if the target platform supports SVE or SVE2 instruction set, the
CROSS_COMPILE_SVE or CROSS_COMPILE_SVE2 environment variables should be set
to true, respectively. For example:

1. export CROSS_COMPILE_SVE2=true
2. export CROSS_COMPILE_SVE=true

Then, the normal building process can be followed.
