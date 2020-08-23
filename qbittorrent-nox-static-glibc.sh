#! /usr/bin/env bash
#
# Copyright 2019 by userdocs and contributors
#
# SPDX-License-Identifier: Apache-2.0
#
# @author - userdocs
#
# @credits - https://gist.github.com/notsure2
#
## https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
#
set -e
#
## Define some special arguments we can use to set the build directory without editing the script.
#
PARAMS=""
BUILD_DIR=""
SKIP_DELETE='no'
#
while (( "$#" )); do
  case "$1" in
    -b|--build-directory)
      BUILD_DIR=$2
      shift 2
      ;;
    -nodel|--no-delete)
      SKIP_DELETE='yes'
      shift
      ;;
    -h|--help)
      echo -e "\n\e[1mDefault build location:\e[0m \e[32m$HOME/qbittorrent-build\e[0m"
      echo -e "\n\e[32m-b\e[0m or \e[32m--build-directory\e[0m to set the location of the build directory. Paths are relative to the script location. Recommended that you use a full path."
      echo -e "\n\e[32mall\e[0m - install all modules to the default or specific build directory (when -b is used)"
      #
      echo -e "\n\e[1mExample:\e[0m \e[32m$(basename -- "$0") all\e[0m - Will install all modules and build qbittorrent to the default build location"
      echo -e "\n\e[1mExample:\e[0m \e[32m$(basename -- "$0") all -b \"\$HOME/build\"\e[0m - Will specify a build directory and install all modules to that custom location"
      echo -e "\n\e[1mExample:\e[0m \e[32m$(basename -- "$0") module\e[0m - Will install a single module to the default build location"
      echo -e "\n\e[1mExample:\e[0m \e[32m$(basename -- "$0") module -b \"\$HOME/build\"\e[0m - will specify a custom build directory and install a specific module use to that custom location"
      #
      echo -e "\n\e[32mmodule\e[0m - install a specific module to the default or defined build directory"
      echo -e "\n\e[1mSupported modules\e[0m"
      echo -e "\n\e[95mzlib\nicu\nopenssl\nboost_build\nboost\nqtbase\nqttools\nlibtorrent\nqbittorrent\e[0m"
      #
      echo -e "\n\e[1mPost build options\e[0m"
      echo -e "\nThe binary can be installed using the install argument."
      echo -e "\n\e[32m$(basename -- "$0") install\e[0m"
      echo -e "\nIf you installed to a specified build directory you need to specify that location using -b"
      echo -e "\n\e[32m$(basename -- "$0") install -b \"\$HOME/build\"\e[0m"
      #
      echo -e "\nThe installation directories depend on the user executing the script."
      echo -e "\nroot = \e[32m/usr/local\e[0m"
      echo -e "\nlocal = \e[32m\$HOME/bin\e[0m\n"
      exit 1
      ;;
    --) # end argument parsing
      shift
      break
      ;;
    -*|--*=) # unsupported flags
      echo -e "\nError: Unsupported flag - \e[31m$1\e[0m - use \e[32m-h\e[0m or \e[32m--help\e[0m to see the valid options\n" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done
#
## Set positional arguments in their proper place.
#
eval set -- "$PARAMS"
#
## The build and installation directory. If the argument -b is used to set a build dir that directory is set and used. If nothing is specifed or the switch is not used it defaults to the hardcoed ~/qbittorrent-build
#
[[ -n "$BUILD_DIR" ]] && export install_dir="$BUILD_DIR" || export install_dir="$HOME/qbittorrent-build"
#
## Echo the build directory.
#
echo -e "\n\e[1mInstall Prefix\e[0m : \e[32m$install_dir\e[0m"
#
## Some basic help
#
echo -e "\n\e[1mScript help\e[0m : \e[32m$(basename -- "$0") -h\e[0m"
#
## This is a list of all modules.
#
modules='^(all|bison|gawk|glibc|zlib|icu|openssl|boost_build|boost|qtbase|qttools|libtorrent|qbittorrent)$'
#
## The installation is modular. You can select the parts you want or need here or using ./scriptname module or install everything using ./scriptname all
#
[[ "$1" = 'all' ]] && skip_bison='no' || skip_bison='yes'
[[ "$1" = 'all' ]] && skip_gawk='no' || skip_gawk='yes'
[[ "$1" = 'all' ]] && skip_glibc='no' || skip_glibc='yes'
[[ "$1" = 'all' ]] && skip_zlib='no' || skip_zlib='yes'
[[ "$1" = 'all' ]] && skip_icu='no' || skip_icu='yes'
[[ "$1" = 'all' ]] && skip_openssl='no' || skip_openssl='yes'
[[ "$1" = 'all' ]] && skip_boost_build='no' || skip_boost_build='yes'
[[ "$1" = 'all' ]] && skip_boost='no' || skip_boost='yes'
[[ "$1" = 'all' ]] && skip_qtbase='no' || skip_qtbase='yes'
[[ "$1" = 'all' ]] && skip_qttools='no' || skip_qttools='yes'
[[ "$1" = 'all' ]] && skip_libtorrent='no' || skip_libtorrent='yes'
[[ "$1" = 'all' ]] && skip_qbittorrent='no' || skip_qbittorrent='yes'
#
## Set this to assume yes unless set to no by a dependency check.
#
deps_installed='yes'
#
## Check for required and optional dependencies
#
echo -e "\n\e[1mChecking if required core dependencies are installed\e[0m\n"
#
[[ "$(dpkg -s build-essential 2> /dev/null | grep -cow '^Status: install ok installed$')" -eq '1' ]] && echo -e "Dependency - \e[32mOK\e[0m - build-essential" || { deps_installed='no'; echo -e "Dependency - \e[31mNO\e[0m - build-essential"; }
[[ "$(dpkg -s pkg-config 2> /dev/null | grep -cow '^Status: install ok installed$')" -eq '1' ]] && echo -e "Dependency - \e[32mOK\e[0m - pkg-config" || { deps_installed='no'; echo -e "Dependency - \e[31mNO\e[0m - pkg-config"; }
[[ "$(dpkg -s automake 2> /dev/null | grep -cow '^Status: install ok installed$')" -eq '1' ]] && echo -e "Dependency - \e[32mOK\e[0m - automake" || { deps_installed='no'; echo -e "Dependency - \e[31mNO\e[0m - automake"; }
[[ "$(dpkg -s libtool 2> /dev/null | grep -cow '^Status: install ok installed$')" -eq '1' ]] && echo -e "Dependency - \e[32mOK\e[0m - libtool" || { deps_installed='no'; echo -e "Dependency - \e[31mNO\e[0m - libtool"; }
[[ "$(dpkg -s git 2> /dev/null | grep -cow '^Status: install ok installed$')" -eq '1' ]] && echo -e "Dependency - \e[32mOK\e[0m - git" || { deps_installed='no'; echo -e "Dependency - \e[31mNO\e[0m - git"; }
[[ "$(dpkg -s perl 2> /dev/null | grep -cow '^Status: install ok installed$')" -eq '1' ]] && echo -e "Dependency - \e[32mOK\e[0m - perl" || { deps_installed='no'; echo -e "Dependency - \e[31mNO\e[0m - perl"; }
[[ "$(dpkg -s python3 2> /dev/null | grep -cow '^Status: install ok installed$')" -eq '1' ]] && echo -e "Dependency - \e[32mOK\e[0m - python3" || { deps_installed='no'; echo -e "Dependency - \e[31mNO\e[0m - python3"; }
[[ "$(dpkg -s python3-dev 2> /dev/null | grep -cow '^Status: install ok installed$')" -eq '1' ]] && echo -e "Dependency - \e[32mOK\e[0m - python3-dev" || { deps_installed='no'; echo -e "Dependency - \e[31mNO\e[0m - python3-dev"; }
#
## Check if user is able to install the depedencies, if yes then do so, if no then exit.
#
if [[ "$deps_installed" = 'no' ]]; then
    if [[ "$(id -un)" = 'root' ]]; then
        #
        echo -e "\n\e[32mUpdating\e[0m\n"
        #
        set +e
        #
        apt update -y
        apt upgrade -y
        apt autoremove -y
        #
        set -e
        #
        [[ -f /var/run/reboot-required ]] && { echo -e "\n\e[31mThis machine requires a reboot to continue installation. Please reboot now.\e[0m\n"; exit; } || :
        #
        echo -e "\n\e[32mInstalling required dependencies\e[0m\n"
        #
        apt install -y build-essential pkg-config automake libtool git perl python3 python3-dev
        #
        echo -e "\n\e[32mDependencies installed!\e[0m"
        #
        deps_installed='yes'
        #
    else
        echo -e "\n\e[1mPlease request or install the missing core dependencies before using this script\e[0m"
        #
        echo -e '\napt install -y build-essential pkg-config automake libtool git perl python3 python3-dev\n'
        #
        exit
    fi
fi
#
## All checks passed echo
#
if [[ "$deps_installed" = 'yes' ]]; then
    echo -e "\n\e[1mGood, we have all the core dependencies installed, continuing to build\e[0m"
fi
#
## Set some python variables we need.
#
export python_version="$(python3 -V | awk '{ print $2 }')"
export python_short_version="$(echo "$python_version" | sed 's/\.[^.]*$//')"
export python_link_version="$(echo "$python_version" | cut -f1 -d'.')$(echo "$python_version" | cut -f2 -d'.')"
#
## post build install command via positional parameter.
#
if [[ "$1" = 'install' ]];then
    if [[ -f "$install_dir/bin/qbittorrent-nox" ]]; then
        #
        if [[ "$(id -un)" = 'root' ]]; then
            mkdir -p "/usr/local/bin"
            cp -rf "$install_dir/bin/qbittorrent-nox" "/usr/local/bin"
        else
            mkdir -p "$HOME/bin"
            cp -rf "$install_dir/bin/qbittorrent-nox" "$HOME/bin"
        fi
        #
        echo -e '\nqbittorrent-nox has been installed!\n'
        echo -e 'Run it using this command:\n'
        #
        [[ "$(id -un)" = 'root' ]] && echo -e '\e[32mqbittorrent-nox\e[0m\n' || echo -e '\e[32m~/bin/qbittorrent-nox\e[0m\n'
        #
        exit
    else
        echo -e "\nqbittorrent-nox has not been built to the defined install directory:\n"
        echo -e "\e[32m$install_dir\e[0m\n"
        echo -e "Please build it using the script first then install\n"
        #
        exit
    fi
fi
#
## Create the configured install directory.
#
[[ "$1" =~ $modules ]] && { mkdir -p "$install_dir"; echo 'using python : '"$python_short_version"' : /usr/bin/python'"$python_short_version"' : /usr/include/python'"$python_short_version"' : /usr/lib/python'"$python_short_version"' ;' > "$HOME/user-config.jam"; }
#
## Set lib and include directory paths based on install path.
#
export include_dir="$install_dir/include"
export lib_dir="$install_dir/lib"
#
## Set some build settings we need applied
#
custom_flags_set () {
    export CXXFLAGS="-std=c++14"
    export CPPFLAGS="-I$include_dir"
    export LDFLAGS="-Wl,--no-as-needed -L$lib_dir -lpthread -pthread"
}
#
custom_flags_reset () {
    export CXXFLAGS="-std=c++14"
    export CPPFLAGS=""
    export LDFLAGS=""
}
#
## Define some build specific variables
#
export PATH="$install_dir/bin:$HOME/bin${PATH:+:${PATH}}"
export LD_LIBRARY_PATH="-L$lib_dir"
export PKG_CONFIG_PATH="-L$lib_dir/pkgconfig"
export local_boost="--with-boost=$install_dir"
export local_openssl="--with-openssl=$install_dir"
#
## Define some URLs to download our apps. They are dynamic and set the most recent version or release.
#
export bison_url="http://ftp.gnu.org/gnu/bison/$(curl -sNL http://ftp.gnu.org/gnu/bison/ | grep -Eo 'bison-([0-9]{1,3}[.]?)([0-9]{1,3}[.]?)([0-9]{1,3}?)\.tar.gz' | sort -V | tail -1)"
#
export gawk_url="http://ftp.gnu.org/gnu/gawk/$(curl -sNL http://ftp.gnu.org/gnu/gawk/ | grep -Eo 'gawk-([0-9]{1,3}[.]?)([0-9]{1,3}[.]?)([0-9]{1,3}?)\.tar.gz' | sort -V | tail -1)"
#
# export glibc_url="http://ftp.gnu.org/gnu/libc/$(curl -sNL http://ftp.gnu.org/gnu/libc/ | grep -Eo 'glibc-([0-9]{1,3}[.]?)([0-9]{1,3}[.]?)([0-9]{1,3}?)\.tar.gz' | sort -V | tail -1)"
export glibc_url="http://ftp.gnu.org/gnu/libc/glibc-2.31.tar.gz"
#
export zlib_github_tag="$(curl -sNL https://github.com/madler/zlib/releases | grep -Eom1 'v1.2.([0-9]{1,2})')"
export zlib_url="https://github.com/madler/zlib/archive/$zlib_github_tag.tar.gz"
#
export icu_url="$(curl -sNL https://api.github.com/repos/unicode-org/icu/releases/latest | grep -Eom1 'ht(.*)icu4c(.*)-src.tgz')"
#
export openssl_github_tag="$(curl -sNL https://github.com/openssl/openssl/releases | grep -Eom1 'OpenSSL_1_1_([0-9][a-z])')"
export openssl_url="https://github.com/openssl/openssl/archive/$openssl_github_tag.tar.gz"
#
export boost_version="$(curl -sNL https://www.boost.org/users/download/ | sed -rn 's#(.*)e">Version (.*\.[0-9]{1,2})</s(.*)#\2#p')"
export boost_github_tag="boost-$boost_version"
export boost_build_url="https://github.com/boostorg/build/archive/$boost_github_tag.tar.gz"
export boost_url="https://dl.bintray.com/boostorg/release/$boost_version/source/boost_${boost_version//./_}.tar.gz"
#
export qt_version='5.15'
export qt_github_tag="$(curl -sNL https://github.com/qt/qtbase/releases | grep -Eom1 "v$qt_version.([0-9]{1,2})")"
#
export libtorrent_github_tag="$(curl -sNL https://api.github.com/repos/arvidn/libtorrent/releases/latest | sed -rn 's#(.*)"tag_name": "(.*)",#\2#p')"
#
export qbittorrent_github_tag="$(curl -sNL https://github.com/qbittorrent/qBittorrent/releases | grep -Eom1 'release-([0-9]{1,4}\.?)+')"
#
## bison
#
if [[ "$skip_bison" = 'no' ||  "$1" = 'bison' ]]; then
    #
    custom_flags_reset
    #
    echo -e "\n\e[32mInstalling bison\e[0m\n"
    #
    file_bison="$install_dir/bison.tar.gz"
    #
    [[ -f "$file_bison" ]] && rm -rf {"$install_dir/$(tar tf "$file_bison" | grep -Eom1 "(.*)[^/]")","$file_bison"}
    #
    wget -qO "$file_bison" "$bison_url"
    tar xf "$file_bison" -C "$install_dir"
    cd "$install_dir/$(tar tf "$file_bison" | head -1 | cut -f1 -d"/")"
    #
    ./configure --prefix="$install_dir"
    make -j$(nproc) CXXFLAGS="$CXXFLAGS" CPPFLAGS="$CPPFLAGS" LDFLAGS="$LDFLAGS"
    make install
else
    echo -e "\nSkipping \e[95mbison\e[0m module installation"
fi
#
## gawk
#
if [[ "$skip_gawk" = 'no' ||  "$1" = 'gawk' ]]; then
    #
    custom_flags_reset
    #
    echo -e "\n\e[32mInstalling gawk\e[0m\n"
    #
    file_gawk="$install_dir/gawk.tar.gz"
    #
    [[ -f "$file_gawk" ]] && rm -rf {"$install_dir/$(tar tf "$file_gawk" | grep -Eom1 "(.*)[^/]")","$file_gawk"}
    #
    wget -qO "$file_gawk" "$gawk_url"
    tar xf "$file_gawk" -C "$install_dir"
    cd "$install_dir/$(tar tf "$file_gawk" | head -1 | cut -f1 -d"/")"
    #
    ./configure --prefix="$install_dir"
    make -j$(nproc) CXXFLAGS="$CXXFLAGS" CPPFLAGS="$CPPFLAGS" LDFLAGS="$LDFLAGS"
    make install
else
    [[ "$skip_bison" = 'no' ]] || [[ "$skip_bison" = 'yes' && "$1" =~ $modules ]] && echo -e "\nSkipping \e[95mgawk\e[0m module installation"
    [[ "$skip_bison" = 'yes' && ! "$1" =~ $modules ]] && echo -e "Skipping \e[95mgawk\e[0m module installation"
fi
#
## glibc static
#
if [[ "$skip_glibc" = 'no' ]] || [[ "$1" = 'glibc' ]]; then
    #
    custom_flags_reset
    #
    echo -e "\n\e[32mInstalling glibc\e[0m\n"
    #
    file_glibc="$install_dir/glibc.tar.xz"
    #
    [[ -f "$file_glibc" ]] && rm -rf {"$install_dir/$(tar tf "$file_glibc" | grep -Eom1 "(.*)[^/]")","$file_glibc"}
    #
    wget -qO "$file_glibc" "$glibc_url"
    tar xf "$file_glibc" -C "$install_dir"
    mkdir -p "$install_dir/$(tar tf "$file_glibc" | head -1 | cut -f1 -d"/")/build"
    cd "$install_dir/$(tar tf "$file_glibc" | head -1 | cut -f1 -d"/")/build"
    #
    "$install_dir/$(tar tf "$file_glibc" | head -1 | cut -f1 -d"/")/configure" --prefix="$HOME/qbittorrent-build" --enable-static-nss
    make -j$(nproc)
    make install
else
    [[ "$skip_gawk" = 'no' ]] || [[ "$skip_gawk" = 'yes' && "$1" =~ $modules ]] && echo -e "\nSkipping \e[95mglibc\e[0m module installation"
    [[ "$skip_gawk" = 'yes' && ! "$1" =~ $modules ]] && echo -e "Skipping \e[95mglibc\e[0m module installation"
fi
#
## zlib installation
#
if [[ "$skip_zlib" = 'no' ||  "$1" = 'zlib' ]]; then
    #
    custom_flags_set
    #
    echo -e "\n\e[32mInstalling zlib\e[0m\n"
    #
    file_zlib="$install_dir/zlib.tar.gz"
    #
    [[ -f "$file_zlib" ]] && rm -rf {"$install_dir/$(tar tf "$file_zlib" | grep -Eom1 "(.*)[^/]")","$file_zlib"}
    #
    wget -qO "$file_zlib" "$zlib_url"
    tar xf "$file_zlib" -C "$install_dir"
    cd "$install_dir/$(tar tf "$file_zlib" | head -1 | cut -f1 -d"/")"
    #
    ./configure --prefix="$install_dir" --static
    make -j$(nproc) CXXFLAGS="$CXXFLAGS" CPPFLAGS="$CPPFLAGS" LDFLAGS="$LDFLAGS"
    make install
else
    [[ "$skip_glibc" = 'no' ]] || [[ "$skip_glibc" = 'yes' && "$1" =~ $modules ]] && echo -e "\nSkipping \e[95mzlib\e[0m module installation"
    [[ "$skip_glibc" = 'yes' && ! "$1" =~ $modules ]] && echo -e "Skipping \e[95mzlib\e[0m module installation"
fi
#
## ICU installation
#
if [[ "$skip_icu" = 'no' || "$1" = 'icu' ]]; then
    #
    custom_flags_set
    #
    echo -e "\n\e[32mInstalling icu\e[0m\n"
    #
    file_icu="$install_dir/icu.tar.gz"
    #
    [[ -f "$file_icu" ]] && rm -rf {"$install_dir/$(tar tf "$file_icu" | grep -Eom1 "(.*)[^/]")","$file_icu"}
    #
    wget -qO "$file_icu" "$icu_url"
    tar xf "$file_icu" -C "$install_dir"
    cd "$install_dir/$(tar tf "$file_icu" | head -1 | cut -f1 -d"/")/source"
    #
    ./configure --prefix="$install_dir" --disable-shared --enable-static CXXFLAGS="$CXXFLAGS" CPPFLAGS="$CPPFLAGS" LDFLAGS="$LDFLAGS"
    make -j$(nproc)
    make install
else
    [[ "$skip_zlib" = 'no' ]] || [[ "$skip_zlib" = 'yes' && "$1" =~ $modules ]] && echo -e "\nSkipping \e[95micu\e[0m module installation"
    [[ "$skip_zlib" = 'yes' && ! "$1" =~ $modules ]] && echo -e "Skipping \e[95micu\e[0m module installation"
fi
#
## openssl installation
#
if [[ "$skip_openssl" = 'no' || "$1" = 'openssl' ]]; then
    #
    custom_flags_set
    #
    echo -e "\n\e[32mInstalling openssl\e[0m\n"
    #
    file_openssl="$install_dir/openssl.tar.gz"
    #
    [[ -f "$file_openssl" ]] && rm -rf {"$install_dir/$(tar tf "$file_openssl" | grep -Eom1 "(.*)[^/]")","$file_openssl"}
    #
    wget -qO "$file_openssl" "$openssl_url"
    tar xf "$file_openssl" -C "$install_dir"
    cd "$install_dir/$(tar tf "$file_openssl" | head -1 | cut -f1 -d"/")"
    #
    ./config --prefix="$install_dir" threads no-shared no-dso no-comp CXXFLAGS="$CXXFLAGS" CPPFLAGS="$CPPFLAGS" LDFLAGS="$LDFLAGS"
    make -j$(nproc)
    make install_sw install_ssldirs
else
    [[ "$skip_icu" = 'no' ]] || [[ "$skip_icu" = 'yes' && "$1" =~ $modules ]] && echo -e "\nSkipping \e[95mopenssl\e[0m module installation"
    [[ "$skip_icu" = 'yes' && ! "$1" =~ $modules ]] && echo -e "Skipping \e[95mopenssl\e[0m module installation"
fi
#
## boost build install
#
if [[ "$skip_boost_build" = 'no' ]] || [[ "$1" = 'boost_build' ]]; then
    #
    custom_flags_set
    #
    echo -e "\n\e[32mInstalling boost build\e[0m\n"
    #
    file_boost_build="$install_dir/build.tar.gz"
    #
    [[ -f "$file_boost_build" ]] && rm -rf {"$install_dir/$(tar tf "$file_boost_build" | grep -Eom1 "(.*)[^/]")","$file_boost_build"}
    #
    wget -qO "$file_boost_build" "$boost_build_url"
    tar xf "$file_boost_build" -C "$install_dir"
    cd "$install_dir/$(tar tf "$file_boost_build" | head -1 | cut -f1 -d"/")"
    #
    ./bootstrap.sh
    ./b2 install --prefix="$install_dir"
else
    [[ "$skip_openssl" = 'no' ]] || [[ "$skip_openssl" = 'yes' && "$1" =~ $modules ]] && echo -e "\nSkipping \e[95mboost_build\e[0m module installation"
    [[ "$skip_openssl" = 'yes' && ! "$1" =~ $modules ]] && echo -e "Skipping \e[95mboost_build\e[0m module installation"
fi
#
## boost libraries install
#
if [[ "$skip_boost" = 'no' ]] || [[ "$1" = 'boost' ]]; then
    #
    custom_flags_set
    #
    echo -e "\n\e[32mInstalling boost libraries\e[0m\n"
    #
    folder_boost="$install_dir/boost"
    #
    [[ -d "$folder_boost" ]] && rm -rf "$folder_boost"
    #
    git clone --branch "$boost_github_tag" --recursive -j$(nproc) --depth 1 https://github.com/boostorg/boost.git "$folder_boost"
    cd "$folder_boost"
    #
    ./bootstrap.sh
    "$install_dir/bin/b2" -j$(nproc) python="$python_short_version" variant=release threading=multi link=static runtime-link=static cxxstd=14 cxxflags="$CXXFLAGS" cflags="$CPPFLAGS" linkflags="$LDFLAGS" toolset=gcc install --prefix="$install_dir"
else
    [[ "$skip_boost_build" = 'no' ]] || [[ "$skip_boost_build" = 'yes' && "$1" =~ $modules ]] && echo -e "\nSkipping \e[95mboost\e[0m module installation"
    [[ "$skip_boost_build" = 'yes' && ! "$1" =~ $modules ]] && echo -e "Skipping \e[95mboost\e[0m module installation"
fi
#
## qt base install
#
if [[ "$skip_qtbase" = 'no' ]] || [[ "$1" = 'qtbase' ]]; then
    #
    custom_flags_set
    #
    echo -e "\n\e[32mInstalling QT Base\e[0m\n"
    #
    folder_qtbase="$install_dir/qtbase"
    #
    [[ -d "$folder_qtbase" ]] && rm -rf "$folder_qtbase"
    #
    git clone --branch "$qt_github_tag" --recursive -j$(nproc) --depth 1 https://github.com/qt/qtbase.git "$folder_qtbase"
    cd "$folder_qtbase"
    #
    ./configure -prefix "$install_dir" -openssl-linked -static -opensource -confirm-license -release -c++std c++14 -no-shared -no-opengl -no-dbus -no-widgets -no-gui -no-compile-examples -I "$include_dir" -L "$lib_dir" QMAKE_LFLAGS="$LDFLAGS"
    make -j$(nproc)
    make install
else
    [[ "$skip_boost" = 'no' ]] || [[ "$skip_boost" = 'yes' && "$1" =~ $modules ]] && echo -e "\nSkipping \e[95mqtbase\e[0m module installation"
    [[ "$skip_boost" = 'yes' && ! "$1" =~ $modules ]] && echo -e "Skipping \e[95mqtbase\e[0m module installation"
fi
#
## qt tools install
#
if [[ "$skip_qttools" = 'no' ]] || [[ "$1" = 'qttools' ]]; then
    #
    custom_flags_set
    #
    echo -e "\n\e[32mInstalling QT Tools\e[0m\n"
    #
    folder_qttools="$install_dir/qttools"
    #
    [[ -d "$folder_qttools" ]] && rm -rf "$folder_qttools"
    #
    git clone --branch "$qt_github_tag" --recursive -j$(nproc) --depth 1 https://github.com/qt/qttools.git "$folder_qttools"
    cd "$folder_qttools"
    #
    "$install_dir/bin/qmake" -set prefix "$install_dir"
    "$install_dir/bin/qmake" QMAKE_CXXFLAGS="-static" QMAKE_LFLAGS="-static"
    make -j$(nproc)
    make install
else
    [[ "$skip_qtbase" = 'no' ]] || [[ "$skip_qtbase" = 'yes' && "$1" =~ $modules ]] && echo -e "\nSkipping \e[95mqttools\e[0m module installation"
    [[ "$skip_qtbase" = 'yes' && ! "$1" =~ $modules ]] && echo -e "Skipping \e[95mqttools\e[0m module installation"
fi
#
## libtorrent install
#
if [[ "$skip_libtorrent" = 'no' ]] || [[ "$1" = 'libtorrent' ]]; then
    #
    custom_flags_set
    #
    echo -e "\n\e[32mInstalling Libtorrent\e[0m\n"
    #
    folder_libtorrent="$install_dir/libtorrent"
    #
    [[ -d "$folder_libtorrent" ]] && rm -rf "$folder_libtorrent"
    #
    git clone --branch "$libtorrent_github_tag" --recursive -j$(nproc) --depth 1 https://github.com/arvidn/libtorrent.git "$folder_libtorrent"
    cd "$folder_libtorrent"
    #
	echo "boost-build $install_dir/share/boost-build/src/kernel ;" > boost-build.jam
	#
    "$install_dir/bin/b2" -j$(nproc) python="$python_short_version" dht=on encryption=on crypto=openssl i2p=on extensions=on variant=release threading=multi link=static boost-link=static runtime-link=static cxxstd=14 cxxflags="$CXXFLAGS" cflags="$CPPFLAGS" linkflags="$LDFLAGS" toolset=gcc install --prefix="$install_dir"
else
    [[ "$skip_qttools" = 'no' ]] || [[ "$skip_qttools" = 'yes' && "$1" =~ $modules ]] && echo -e "\nSkipping \e[95mlibtorrent\e[0m module installation"
    [[ "$skip_qttools" = 'yes' && ! "$1" =~ $modules ]] && echo -e "Skipping \e[95mlibtorrent\e[0m module installation"
fi
#
## qBittorrent install (static)
#
if [[ "$skip_qbittorrent" = 'no' ]] || [[ "$1" = 'qbittorrent' ]]; then
    #
    custom_flags_set
    #
    echo -e "\n\e[32mInstalling qBittorrent\e[0m\n"
    #
    folder_qbittorrent="$install_dir/qbittorrent"
    #
    [[ -d "$folder_qbittorrent" ]] && rm -rf "$folder_qbittorrent"
    #
    git clone --branch "$qbittorrent_github_tag" --recursive -j$(nproc) --depth 1 https://github.com/qbittorrent/qBittorrent.git "$folder_qbittorrent"
    #
    cd "$folder_qbittorrent"
    #
    ./bootstrap.sh
    ./configure --prefix="$install_dir" "$local_boost" --disable-gui CXXFLAGS="$CXXFLAGS" CPPFLAGS="--static -static $CPPFLAGS" LDFLAGS="--static -static $LDFLAGS -l:libboost_system.a" openssl_CFLAGS="-I$include_dir" openssl_LIBS="-L$lib_dir -l:libcrypto.a -l:libssl.a" libtorrent_CFLAGS="-I$include_dir" libtorrent_LIBS="-L$lib_dir -ldl -l:libtorrent.a" zlib_CFLAGS="-I$include_dir" zlib_LIBS="-L$lib_dir -l:libz.a" QT_QMAKE="$install_dir/bin"
    #
    sed -i 's/-lboost_system//' conf.pri
    sed -i 's/-lcrypto//' conf.pri
    sed -i 's/-lssl//' conf.pri
    #
    make -j$(nproc)
    make install
else
    [[ "$skip_libtorrent" = 'no' ]] || [[ "$skip_libtorrent" = 'yes' && "$1" =~ $modules ]] && echo -e "\nSkipping \e[95mqbittorrent\e[0m module installation"
    [[ "$skip_libtorrent" = 'yes' && ! "$1" =~ $modules ]] && echo -e "Skipping \e[95mqbittorrent\e[0m module installation"
fi
#
## Cleanup and exit
#
if [[ "$SKIP_DELETE" = 'no' && -n "$1" ]]; then
    echo -e "\n\e[32mDeleting installation files\e[0m\n"
    #
    [[ -f "$file_bison" ]] && rm -rf {"$install_dir/$(tar tf "$file_bison" | grep -Eom1 "(.*)[^/]")","$file_bison"}
    [[ -f "$file_gawk" ]] && rm -rf {"$install_dir/$(tar tf "$file_gawk" | grep -Eom1 "(.*)[^/]")","$file_gawk"}
    [[ -f "$file_zlib" ]] && rm -rf {"$install_dir/$(tar tf "$file_zlib" | grep -Eom1 "(.*)[^/]")","$file_zlib"}
    [[ -f "$file_icu" ]] && rm -rf {"$install_dir/$(tar tf "$file_icu" | grep -Eom1 "(.*)[^/]")","$file_icu"}
    [[ -f "$file_openssl" ]] && rm -rf {"$install_dir/$(tar tf "$file_openssl" | grep -Eom1 "(.*)[^/]")","$file_openssl"}
    [[ -f "$file_boost_build" ]] && rm -rf {"$install_dir/$(tar tf "$file_boost_build" | grep -Eom1 "(.*)[^/]")","$file_boost_build"}
    [[ -d "$folder_boost" ]] && rm -rf "$folder_boost"
    [[ -d "$folder_qtbase" ]] && rm -rf "$folder_qtbase"
    [[ -d "$folder_qttools" ]] && rm -rf "$folder_qttools"
    [[ -d "$folder_libtorrent" ]] && rm -rf "$folder_libtorrent"
    [[ -f "$file_glibc" ]] && rm -rf {"$install_dir/$(tar tf "$file_glibc" | grep -Eom1 "(.*)[^/]")","$file_glibc"}
    [[ -d "$folder_qbittorrent" ]] && rm -rf "$folder_qbittorrent"
    [[ -f "$HOME/user-config.jam" ]] && rm -rf "$HOME/user-config.jam"
else
    [[ "$skip_qbittorrent" = 'no' ]] || [[ "$skip_qbittorrent" = 'yes' && "$1" =~ $modules ]] && echo -e "\nSkipping \e[95mDeletion\e[0m\n"
    [[ "$skip_qbittorrent" = 'yes' && ! "$1" =~ $modules ]] && echo -e "Skipping \e[95mDeletion\e[0m\n"
fi
#
##
#
exit
