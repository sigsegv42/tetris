AC_INIT([Tetris], [0.1], [sigsegv@quantumfish.com], [Tetris], [http://www.quantumfish.com/])
AC_PREREQ([2.59])
AM_INIT_AUTOMAKE([1.10 -Wall no-define])
AC_PROG_CXX
AC_PROG_LIBTOOL
LT_INIT([disable-static])

AC_HEADER_STDC
AC_CHECK_HEADERS([string])
AC_CHECK_HEADERS([iostream])

# need at least vertical3d 1.0
V3D_REQUIRE([1.0])
# check for additional v3d libraries
V3D_3DTYPES

# need at least boost 1.41 for property tree support
BOOST_REQUIRE([1.41])
BOOST_TEST
BOOST_SIGNALS
BOOST_SYSTEM
BOOST_FILESYSTEM
BOOST_PROGRAM_OPTIONS

# use pkg-config
PKG_PROG_PKG_CONFIG([0.2])

# checks for libraries which use pkg-config

# libv3dimage needs libpng support
PKG_CHECK_MODULES([libpng], [libpng])

# need log4cxx for logging support
PKG_CHECK_MODULES([liblog4cxx], [liblog4cxx])

# libv3dfont needs freetype2
PKG_CHECK_MODULES([freetype2], [freetype2])

# libv3daudio needs openal
PKG_CHECK_MODULES([openal], [openal])
PKG_CHECK_MODULES([freealut], [freealut])

PKG_CHECK_MODULES([gl], [gl])

# libhookah needs sdl
PKG_CHECK_MODULES([sdl], [sdl])

AC_ARG_WITH(jpeg, 
	[AC_HELP_STRING([--with-jpeg=<DIR>],
    [Provide an alternative path to the libJPEG library directory])],
    libjpeg_libdir=$withval,
    libjpeg_libdir=""
    )

# Check for -ljpeg
AC_CHECK_LIB(jpeg, jpeg_destroy_decompress,
                   jpeg_ok=yes, jpeg_ok=no
                   AC_MSG_ERROR([JPEG library (libjpeg) not found]))
if test "$jpeg_ok" = yes; then
   AC_MSG_CHECKING([for jpeglib])
   AC_TRY_CPP(
[#include <stdio.h>
#undef PACKAGE
#undef VERSION
#undef HAVE_STDLIB_H
#include <jpeglib.h>],
         jpeg_ok=yes,
         jpeg_ok=no)
   AC_MSG_RESULT($jpeg_ok)
   if test "$jpeg_ok" = yes; then
      JPEG_LIBS="-ljpeg"
      # should we check for progressive JPEG like GTK+ as well?
   else
      AC_MSG_ERROR([JPEG library (libjpeg) not found])
   fi
fi
AC_SUBST([JPEG_LIBS])


# gcov support (for code coverage reports)

AC_PATH_PROG([GCOV], [gcov], [enable_gcov=no])

AC_MSG_CHECKING([whether to build with gcov testing])

AC_ARG_ENABLE([gcov],
              [AS_HELP_STRING([--enable-gcov],
                              [Whether to enable coverage testing (requires gcc and gcov)])],
              [],
              [enable_gcov=no])

AS_IF([test "x$enable_gcov" = "xyes" && test "x$GCC" = "xyes"],
      [
        GCOV_CFLAGS="-g -O0 -fprofile-arcs -ftest-coverage"
        GCOV_LDFLAGS="-lgcov"
      ]
)

AM_CONDITIONAL([GCOV_ENABLED], [test "x$enable_gcov" = "xyes"])
AC_SUBST([GCOV_CFLAGS])
AC_SUBST([GCOV_LDFLAGS])
AC_MSG_RESULT([$enable_gcov])

# need at least vertical3d 1.0
V3D_REQUIRE([1.0])
# check for additional v3d libraries
V3D_3DTYPES
V3D_IMAGE
V3D_INPUT
V3D_COMMAND
V3D_FONT
V3D_GL
V3D_GUI
V3D_HOOKAH
V3D_HOOKAH_SDL

AC_SUBST([TETRIS_SO_VERSION], [0:1:0])
AC_SUBST([TETRIS_API_VERSION], [1.0])

# save configure options in config.nice
V3D_CONFIG_NICE([config.nice])

AC_CONFIG_FILES([
Makefile 
tetris/Makefile
tests/Makefile
])

AC_OUTPUT

