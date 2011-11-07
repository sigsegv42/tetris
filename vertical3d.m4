# additional m4 rules
# config.nice support lifted from Apache APR (V3D_EXPAND_VAR & V3D_CONFIG_NICE)
#

m4_define([_V3D_SERIAL], [m4_translit([
# serial 1
], [#
], [])])

dnl Iteratively interpolate the contents of the second argument
dnl until interpolation offers no new result. Then assign the
dnl final result to $1.
dnl
dnl Example:
dnl
dnl foo=1
dnl bar='${foo}/2'
dnl baz='${bar}/3'
dnl V3D_EXPAND_VAR(fraz, $baz)
dnl   $fraz is now "1/2/3"
dnl 
AC_DEFUN([V3D_EXPAND_VAR],[
ap_last=
ap_cur="$2"
while test "x${ap_cur}" != "x${ap_last}";
do
  ap_last="${ap_cur}"
  ap_cur=`eval "echo ${ap_cur}"`
done
$1="${ap_cur}"
])


dnl V3D_CONFIG_NICE(filename)
dnl
dnl Saves a snapshot of the configure command-line for later reuse
dnl
AC_DEFUN([V3D_CONFIG_NICE],[
  rm -f $1
  cat >$1<<EOF
#! /bin/sh
#
# Created by configure

EOF
  if test -n "$CC"; then
    echo "CC=\"$CC\"; export CC" >> $1
  fi
  if test -n "$CFLAGS"; then
    echo "CFLAGS=\"$CFLAGS\"; export CFLAGS" >> $1
  fi
  if test -n "$CPPFLAGS"; then
    echo "CPPFLAGS=\"$CPPFLAGS\"; export CPPFLAGS" >> $1
  fi
  if test -n "$LDFLAGS"; then
    echo "LDFLAGS=\"$LDFLAGS\"; export LDFLAGS" >> $1
  fi
  if test -n "$LIBS"; then
    echo "LIBS=\"$LIBS\"; export LIBS" >> $1
  fi
  if test -n "$INCLUDES"; then
    echo "INCLUDES=\"$INCLUDES\"; export INCLUDES" >> $1
  fi
  if test -n "$NOTEST_CFLAGS"; then
    echo "NOTEST_CFLAGS=\"$NOTEST_CFLAGS\"; export NOTEST_CFLAGS" >> $1
  fi
  if test -n "$NOTEST_CPPFLAGS"; then
    echo "NOTEST_CPPFLAGS=\"$NOTEST_CPPFLAGS\"; export NOTEST_CPPFLAGS" >> $1
  fi
  if test -n "$NOTEST_LDFLAGS"; then
    echo "NOTEST_LDFLAGS=\"$NOTEST_LDFLAGS\"; export NOTEST_LDFLAGS" >> $1
  fi
  if test -n "$NOTEST_LIBS"; then
    echo "NOTEST_LIBS=\"$NOTEST_LIBS\"; export NOTEST_LIBS" >> $1
  fi

  # Retrieve command-line arguments.
  eval "set x $[0] $ac_configure_args"
  shift

  for arg
  do
    V3D_EXPAND_VAR(arg, $arg)
    echo "\"[$]arg\" \\" >> $1
  done
  echo '"[$]@"' >> $1
  chmod +x $1
])dnl

########################################################
#
# This next section defines a bunch of helpful macros
# for use by the build system to properly build projects 
# against the various v3d libraries.
#
# All of this is heavily borrowed from boost.m4.
#
########################################################

# V3D_REQUIRE([VERSION], [ACTION-IF-NOT-FOUND])
# -----------------------------------------------
# Look for v3D.  If version is given, it must either be a literal of the form
# "X.Y.Z" where X, Y and Z are integers (the ".Z" part being optional) or a
# variable "$var".
# Defines the value V3D_CPPFLAGS.  This macro only checks for headers with
# the required version, it does not check for any of the Boost libraries.
# On # success, defines HAVE_V3D.  On failure, calls the optional
# ACTION-IF-NOT-FOUND action if one was supplied.
# Otherwise aborts with an error message.
AC_DEFUN([V3D_REQUIRE],
[AC_REQUIRE([AC_PROG_CXX])dnl
AC_REQUIRE([AC_PROG_GREP])dnl
echo "$as_me: this is vertical3d.m4[]_V3D_SERIAL" >&AS_MESSAGE_LOG_FD
v3d_save_IFS=$IFS
v3d_version_req=$1
IFS=.
set x $v3d_version_req 0 0 0
IFS=$v3d_save_IFS
shift
v3d_version_req=`expr "$[1]" '*' 100000 + "$[2]" '*' 100 + "$[3]"`
v3d_version_req_string=$[1].$[2].$[3]
AC_ARG_WITH([v3d],
   [AS_HELP_STRING([--with-v3d=DIR],
                   [prefix of v3D $1 @<:@guess@:>@])])dnl
AC_ARG_VAR([V3D_ROOT],[Location of v3D installation])dnl
# If V3D_ROOT is set and the user has not provided a value to
# --with-v3d, then treat V3D_ROOT as if it the user supplied it.
if test x"$V3D_ROOT" != x; then
  if test x"$with_boost" = x; then
    AC_MSG_NOTICE([Detected V3D_ROOT; continuing with --with-v3d=$V3D_ROOT])
    with_boost=$V3D_ROOT
  else
    AC_MSG_NOTICE([Detected V3D_ROOT=$V3D_ROOT, but overridden by --with-v3d=$with_v3d])
  fi
fi
AC_SUBST([DISTCHECK_CONFIGURE_FLAGS],
         ["$DISTCHECK_CONFIGURE_FLAGS '--with-v3d=$with_v3d'"])dnl
v3d_save_CPPFLAGS=$CPPFLAGS
  AC_CACHE_CHECK([for v3D headers version >= $v3d_version_req_string],
    [v3d_cv_inc_path],
    [v3d_cv_inc_path=no
AC_LANG_PUSH([C++])dnl
m4_pattern_allow([^V3D_VERSION$])dnl
    AC_LANG_CONFTEST([AC_LANG_PROGRAM([[#include <vertical3d/version.h>
#if !defined V3D_VERSION
# error V3D_VERSION is not defined
#elif V3D_VERSION < $v3d_version_req
# error v3D headers version < $v3d_version_req
#endif
]])])
    # If the user provided a value to --with-v3d, use it and only it.
    case $with_v3d in #(
      ''|yes) set x '' /opt/local/include /usr/local/include /opt/include \
                 /usr/include C:/Vertical3D/include;; #(
      *)      set x "$with_v3d/include" "$with_v3d";;
    esac
    shift
    for v3d_dir
    do
    # Without --layout=system, v3D (or at least some versions) installs
    # itself in <prefix>/include/vertical3d-<version>.  This inner loop helps to
    # find headers in such directories.
    #
    # Any ${v3d_dir}/vertical3d-x_xx directories are searched in reverse version
    # order followed by ${v3d_dir}.  The final '.' is a sentinel for
    # searching $v3d_dir" itself.  Entries are whitespace separated.
    #
    # I didn't indent this loop on purpose (to avoid over-indented code)
    v3d_layout_system_search_list=`cd "$v3d_dir" 2>/dev/null \
        && ls -1 | "${GREP}" '^vertical3d-' | sort -rn -t- -k2 \
        && echo .`
    for v3d_inc in $v3d_layout_system_search_list
    do
      if test x"$v3d_inc" != x.; then
        v3d_inc="$v3d_dir/$v3d_inc"
      else
        v3d_inc="$v3d_dir" # Uses sentinel in boost_layout_system_search_list
      fi
      if test x"$v3d_inc" != x; then
        # We are going to check whether the version of v3D installed
        # in $v3d_inc is usable by running a compilation that
        # #includes it.  But if we pass a -I/some/path in which v3D
        # is not installed, the compiler will just skip this -I and
        # use other locations (either from CPPFLAGS, or from its list
        # of system include directories).  As a result we would use
        # header installed on the machine instead of the /some/path
        # specified by the user.  So in that precise case (trying
        # $v3d_inc), make sure the version.h exists.
        #
        # Use test -e as there can be symlinks.
        test -e "$v3d_inc/vertical3d/version.h" || continue
        CPPFLAGS="$CPPFLAGS -I$v3d_inc"
      fi
      AC_COMPILE_IFELSE([], [v3d_cv_inc_path=yes], [v3d_cv_version=no])
      if test x"$v3d_cv_inc_path" = xyes; then
        if test x"$v3d_inc" != x; then
          v3d_cv_inc_path=$v3d_inc
        fi
        break 2
      fi
    done
    done
AC_LANG_POP([C++])dnl
    ])
    case $v3d_cv_inc_path in #(
      no)
        v3d_errmsg="cannot find v3D headers version >= $v3d_version_req_string"
        m4_if([$2], [],  [AC_MSG_ERROR([$v3d_errmsg])],
                        [AC_MSG_NOTICE([$v3d_errmsg])])
        $2
        ;;#(
      yes)
        V3D_CPPFLAGS=
        ;;#(
      *)
        AC_SUBST([V3D_CPPFLAGS], ["-I$v3d_cv_inc_path"])dnl
        ;;
    esac
  if test x"$v3d_cv_inc_path" != xno; then
  AC_DEFINE([HAVE_V3D], [1],
            [Defined if the requested minimum V3D version is satisfied])
  AC_CACHE_CHECK([for v3D's header version],
    [v3d_cv_lib_version],
    [m4_pattern_allow([^V3D_LIB_VERSION$])dnl
     _BOOST_SED_CPP([/^v3d-lib-version = /{s///;s/\"//g;p;q;}],
                    [#include <vertical3d/version.h>
v3d-lib-version = V3D_LIB_VERSION],
    [v3d_cv_lib_version=`cat conftest.i`])])
    # e.g. "134" for 1_34_1 or "135" for 1_35
    v3d_major_version=`echo "$v3d_cv_lib_version" | sed 's/\.//;s/_.*//'`
    case $v3d_major_version in #(
      '' | *[[!0-9]]*)
        AC_MSG_ERROR([invalid value: v3d_major_version=$v3d_major_version])
        ;;
    esac
fi
CPPFLAGS=$v3d_save_CPPFLAGS
])# V3D_REQUIRE


# V3D_FIND_HEADER([HEADER-NAME], [ACTION-IF-NOT-FOUND], [ACTION-IF-FOUND])
# --------------------------------------------------------------------------
# Wrapper around AC_CHECK_HEADER for v3D headers.  Useful to check for
# some parts of the v3D library which are only made of headers and don't
# require linking
#
# Default ACTION-IF-NOT-FOUND: Fail with a fatal error unless v3D couldn't be
# found in the first place, in which case by default a notice is issued to the
# user.  Presumably if we haven't died already it's because it's OK to not have
# Boost, which is why only a notice is issued instead of a hard error.
#
# Default ACTION-IF-FOUND: define the preprocessor symbol HAVE_<HEADER-NAME> in
# case of success # (where HEADER-NAME is written LIKE_THIS, e.g.,
# HAVE_V3D_BREP_H).
AC_DEFUN([V3D_FIND_HEADER],
[AC_REQUIRE([V3D_REQUIRE])dnl
if test x"$v3d_cv_inc_path" = xno; then
  m4_default([$2], [AC_MSG_NOTICE([v3D not available, not searching for $1])])
else
AC_LANG_PUSH([C++])dnl
v3d_save_CPPFLAGS=$CPPFLAGS
CPPFLAGS="$CPPFLAGS $V3D_CPPFLAGS"
AC_CHECK_HEADER([$1],
  [m4_default([$3], [AC_DEFINE(AS_TR_CPP([HAVE_$1]), [1],
                               [Define to 1 if you have <$1>])])],
  [m4_default([$2], [AC_MSG_ERROR([cannot find $1])])])
CPPFLAGS=$v3d_save_CPPFLAGS
AC_LANG_POP([C++])dnl
fi
])# V3D_FIND_HEADER



# V3D_FIND_LIB([LIB-NAME], [HEADER-NAME], [CXX-TEST],
#                [CXX-PROLOGUE])
# -------------------------------------------------------------------------
# Look for the v3D library LIB-NAME (e.g., LIB-NAME = `types', for
# libv3dtypes).  Check that HEADER-NAME works and check that
# libv3dLIB-NAME can link with the code CXX-TEST.  The optional argument
# CXX-PROLOGUE can be used to include some C++ code before the `main'
# function.
#
# Invokes V3D_FIND_HEADER([HEADER-NAME]) (see above).
#
AC_DEFUN([V3D_FIND_LIB],
[AC_REQUIRE([V3D_REQUIRE])dnl
if test x"$v3d_cv_inc_path" = xno; then
  AC_MSG_NOTICE([v3D not available, not searching for the v3D $1 library])
else
dnl The else branch is huge and wasn't intended on purpose.
AC_LANG_PUSH([C++])dnl
AS_VAR_PUSHDEF([v3d_lib], [v3d_cv_lib_$1])dnl
AS_VAR_PUSHDEF([v3d_lib_LDFLAGS], [v3d_cv_lib_$1_LDFLAGS])dnl
AS_VAR_PUSHDEF([v3d_lib_LDPATH], [v3d_cv_lib_$1_LDPATH])dnl
AS_VAR_PUSHDEF([v3d_lib_LIBS], [v3d_cv_lib_$1_LIBS])dnl
V3D_FIND_HEADER([$2])
v3d_save_CPPFLAGS=$CPPFLAGS
CPPFLAGS="$CPPFLAGS $V3D_CPPFLAGS"
# Now let's try to find the library.  
# Each library is searched through the various standard paths were v3D is
# usually installed.
AC_CACHE_CHECK([for the v3D $1 library], [v3d_lib],
  [v3d_lib=no

  # Look for the abs path the static archive.
  # $libext is computed by Libtool but let's make sure it's non empty.
  test -z "$libext" &&
    AC_MSG_ERROR([the libext variable is empty, did you invoke Libtool?])
  v3d_save_ac_objext=$ac_objext
  # Generate the test file.
  AC_LANG_CONFTEST([AC_LANG_PROGRAM([#include <$2>
$4], [$3])])
dnl Optimization hacks: compiling C++ is slow, especially with Boost.  What
dnl we're trying to do here is guess the right combination of link flags
dnl (LIBS / LDFLAGS) to use a given library.  This can take several
dnl iterations before it succeeds and is thus *very* slow.  So what we do
dnl instead is that we compile the code first (and thus get an object file,
dnl typically conftest.o).  Then we try various combinations of link flags
dnl until we succeed to link conftest.o in an executable.  The problem is
dnl that the various TRY_LINK / COMPILE_IFELSE macros of Autoconf always
dnl remove all the temporary files including conftest.o.  So the trick here
dnl is to temporarily change the value of ac_objext so that conftest.o is
dnl preserved accross tests.  This is obviously fragile and I will burn in
dnl hell for not respecting Autoconf's documented interfaces, but in the
dnl mean time, it optimizes the macro by a factor of 5 to 30.
dnl Another small optimization: the first argument of AC_COMPILE_IFELSE left
dnl empty because the test file is generated only once above (before we
dnl start the for loops).
  AC_COMPILE_IFELSE([],
    [ac_objext=do_not_rm_me_plz],
    [AC_MSG_ERROR([cannot compile a test that uses v3D $1])])
  ac_objext=$v3d_save_ac_objext
  v3d_failed_libs=
# Don't bother to ident the 6 nested for loops, only the 2 innermost ones
# matter.
for v3d_ver_ in -$v3d_cv_lib_version ''; do
  for v3d_lib in \
    v3d$1$v3d_ver_
  do
    # Avoid testing twice the same lib
    case $v3d_failed_libs in #(
      *@$v3d_lib@*) continue;;
    esac
    # If with_v3d is empty, we'll search in /lib first, which is not quite
    # right so instead we'll try to a location based on where the headers are.
    v3d_tmp_lib=$with_v3d
    test x"$with_v3d" = x && v3d_tmp_lib=${v3d_cv_inc_path%/include}
    for v3d_ldpath in "$v3d_tmp_lib/lib" '' \
             /opt/local/lib* /usr/local/lib* /opt/lib* /usr/lib* \
             "$with_v3d" C:/Vertical3D/lib /lib*
    do
      test -e "$v3d_ldpath" || continue
      v3d_save_LDFLAGS=$LDFLAGS
      # Are we looking for a static library?
      case $v3d_ldpath in #(
        *?*:*s*) # Yes (Non empty v3d_ldpath + s in rt opt)
          v3d_lib_LIBS="$v3d_ldpath/lib$v3d_lib.$libext"
          test -e "$v3d_lib_LIBS" || continue;; #(
        *) # No: use -lv3dfoo to find the shared library.
          v3d_lib_LIBS="-l$v3d_lib";;
      esac
      v3d_save_LIBS=$LIBS
      LIBS="$v3d_lib_LIBS $LIBS"
      test x"$v3d_ldpath" != x && LDFLAGS="$LDFLAGS -L$v3d_ldpath"
dnl First argument of AC_LINK_IFELSE left empty because the test file is
dnl generated only once above (before we start the for loops).
      _BOOST_AC_LINK_IFELSE([],
                            [v3d_lib=yes], [v3d_lib=no])
      ac_objext=$v3d_save_ac_objext
      LDFLAGS=$v3d_save_LDFLAGS
      LIBS=$v3d_save_LIBS
      if test x"$v3d_lib" = xyes; then
        v3d_lib_LDFLAGS="-L$v3d_ldpath -R$v3d_ldpath"
        v3d_lib_LDPATH="$v3d_ldpath"
        break 6
      else
        v3d_failed_libs="$v3d_failed_libs@$v3d_lib@"
      fi
    done
  done
done
rm -f conftest.$ac_objext
])
case $v3d_lib in #(
  no) _AC_MSG_LOG_CONFTEST
    AC_MSG_ERROR([cannot find the flags to link with v3D $1])
    ;;
esac
AC_SUBST(AS_TR_CPP([V3D_$1_LDFLAGS]), [$v3d_lib_LDFLAGS])dnl
AC_SUBST(AS_TR_CPP([V3D_$1_LDPATH]), [$v3d_lib_LDPATH])dnl
AC_SUBST([V3D_LDPATH], [$v3d_lib_LDPATH])dnl
AC_SUBST(AS_TR_CPP([V3D_$1_LIBS]), [$v3d_lib_LIBS])dnl
CPPFLAGS=$v3d_save_CPPFLAGS
AS_VAR_POPDEF([v3d_lib])dnl
AS_VAR_POPDEF([v3d_lib_LDFLAGS])dnl
AS_VAR_POPDEF([v3d_lib_LDPATH])dnl
AS_VAR_POPDEF([v3d_lib_LIBS])dnl
AC_LANG_POP([C++])dnl
fi
])# V3D_FIND_LIB


# V3D_DEFUN(LIBRARY, CODE)
# --------------------------
# Define V3D_<LIBRARY-UPPERCASE> as a macro that runs CODE.
#
# Use indir to avoid the warning on underquoted macro name given to AC_DEFUN.
m4_define([V3D_DEFUN],
[m4_indir([AC_DEFUN],
          m4_toupper([V3D_$1]),
[m4_pushdef([V3D_Library], [$1])dnl
$2
m4_popdef([V3D_Library])dnl
])
])


# V3D_3DTYPES()
# -----------------------------------------
# Look for libv3dtypes
V3D_DEFUN([3dtypes],
[V3D_FIND_LIB([types],
                [vertical3d/3dtypes/Vector3.h],
                [v3D::Vector3 test();])
])# V3D_3DTYPES


# V3D_IMAGE()
# -----------------------------------------
# Look for libv3dimage
V3D_DEFUN([image],
# this is a bit of a kludge, but in order to link the image library
# we need to link a bunch of other dependent libraries. so this macro
# must only be used after those dependent library macros have been called
v3d_image_save_LIBS=$LIBS
LIBS="$LIBS $libpng_LIBS $JPEG_LIBS $liblog4cxx_LIBS $BOOST_SYSTEM_LIBS $BOOST_FILESYSTEM_LIBS"
[V3D_FIND_LIB([image],
                [vertical3d/image/Image.h],
                [v3D::Image test();])
LIBS=$v3d_image_save_LIBS
])# V3D_IMAGE


# V3D_COMMAND()
# -----------------------------------------
# Look for libv3dcommand
V3D_DEFUN([command],
v3d_command_save_LIBS=$LIBS
LIBS="$LIBS $BOOST_SIGNALS_LIBS $liblog4cxx_LIBS"
[V3D_FIND_LIB([command],
                [vertical3d/command/Command.h],
                [v3D::CommandInfo test("cmd");])
LIBS=$v3d_command_save_LIBS
])# V3D_COMMAND


# V3D_INPUT()
# -----------------------------------------
# Look for libv3dinput
V3D_DEFUN([input],
[V3D_FIND_LIB([input],
                [vertical3d/input/KeyboardDevice.h],
                [
class TestableKeyboardDevice : public v3D::KeyboardDevice {
public: bool tick(void) { return true; } };
TestableKeyboardDevice test;
])
])# V3D_INPUT

# V3D_FONT()
# -----------------------------------------
# Look for libv3dfont
V3D_DEFUN([font],
# this is a bit of a kludge, but in order to link the image library
# we need to link a bunch of other dependent libraries. so this macro
# must only be used after those dependent library macros have been called
v3d_font_save_LIBS=$LIBS
LIBS="$LIBS $freetype2_LIBS $liblog4cxx_LIBS $V3D_IMAGE_LIBS $libpng_LIBS $JPEG_LIBS $BOOST_SYSTEM_LIBS $BOOST_FILESYSTEM_LIBS"
[V3D_FIND_LIB([font],
                [vertical3d/font/Font2D.h],
                [v3D::Font2D test();])
LIBS=$v3d_font_save_LIBS
])# V3D_FONT

# V3D_GL()
# -----------------------------------------
# Look for libv3dgl
V3D_DEFUN([gl],
# this is a bit of a kludge, but in order to link the image library
# we need to link a bunch of other dependent libraries. so this macro
# must only be used after those dependent library macros have been called
v3d_gl_save_LIBS=$LIBS
LIBS="$LIBS $gl_LIBS $liblog4cxx_LIBS $V3D_IMAGE_LIBS $V3D_FONT_LIBS $libpng_LIBS $freetype2_LIBS $JPEG_LIBS $BOOST_SYSTEM_LIBS $BOOST_FILESYSTEM_LIBS"
[V3D_FIND_LIB([gl],
                [vertical3d/gl/GLTexture.h],
                [v3D::GLTexture test();])
LIBS=$v3d_gl_save_LIBS
])# V3D_GL

# V3D_GUI()
# -----------------------------------------
# Look for libv3dgui
V3D_DEFUN([gui],
# this is a bit of a kludge, but in order to link the image library
# we need to link a bunch of other dependent libraries. so this macro
# must only be used after those dependent library macros have been called
v3d_gui_save_LIBS=$LIBS
LIBS="$LIBS $V3D_INPUT_LIBS $V3D_COMMAND_LIBS $BOOST_SIGNALS_LIBS $liblog4cxx_LIBS"
[V3D_FIND_LIB([gui],
                [vertical3d/gui/InputEventAdapter.h],
                [])
LIBS=$v3d_gui_save_LIBS
])# V3D_GUI

# V3D_HOOKAH()
# -----------------------------------------
# Look for libv3dhookah
V3D_DEFUN([hookah],
v3d_hookah_save_LIBS=$LIBS
LIBS="$LIBS $BOOST_SIGNALS_LIBS"
[V3D_FIND_LIB([hookah],
                [vertical3d/hookah/Window.h],
                [])
LIBS=$v3d_hookah_save_LIBS
])# V3D_HOOKAH

# V3D_HOOKAH_SDL()
# -----------------------------------------
# Look for libv3dhookah_sdl
V3D_DEFUN([hookah_sdl],
v3d_hookah_save_LIBS=$LIBS
LIBS="$LIBS $V3D_HOOKAH_LIBS $BOOST_SIGNALS_LIBS $sdl_LIBS $V3D_INPUT_LIBS"
[V3D_FIND_LIB([hookah_sdl],
                [vertical3d/hookah/drivers/SDLWindow.h],
                [])
LIBS=$v3d_hookah_save_LIBS
])# V3D_HOOKAH


# V3D_HOOKAH_FLTK()
# -----------------------------------------
# Look for libv3dhookah_fltk
V3D_DEFUN([hookah_fltk],
v3d_hookah_save_LIBS=$LIBS
LIBS="$LIBS $FLTK_LDFLAGS $V3D_HOOKAH_LIBS $BOOST_SIGNALS_LIBS $V3D_INPUT_LIBS"
[V3D_FIND_LIB([hookah_fltk],
                [vertical3d/hookah/drivers/FLTKWindow.h],
                [])
LIBS=$v3d_hookah_save_LIBS
])# V3D_HOOKAH


# V3D_AUDIO()
# -----------------------------------------
# Look for libv3daudio
V3D_DEFUN([audio],
v3d_audio_save_LIBS=$LIBS
LIBS="$LIBS $openal_LIBS $freealut_LIBS $V3D_TYPES_LIBS"
[V3D_FIND_LIB([audio],
                [vertical3d/audio/AudioClip.h],
                [v3D::AudioClip test();])
LIBS=$v3d_audio_save_LIBS
])# V3D_AUDIO

#V3D_BREP
