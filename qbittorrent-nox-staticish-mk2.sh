#! /usr/bin/env bash
#
# Copyright 2019 by userdocs and contributors
#
# SPDX-License-Identifier: Apache-2.0
#
# @author - userdocs
#
# @contributors IceCodeNew
# 
# @credits - https://gist.github.com/notsure2
#
## https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
#
set -e
#
## Do not edit these variables. They set the default values to some critical variables.
#
WORKING_DIR="$(printf "$(dirname "$0")" | pwd)" # used for the cd commands to cd back to the working directory the script was executed from.
PARAMS=""
BUILD_DIR=""
SKIP_DELETE='no'
SKIP_ICU='yes'
GITHUB_TAG=''
HIGH_EFFICIENCY='no'
GIT_PROXY=''
CURL_PROXY=''
#
## This section controls our flags that we can pass to the script to modify some variables and behaviour.
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
    -icu|--icu)
      SKIP_ICU='no'
      shift
      ;;
    -m|--master)
      GITHUB_TAG='master'
      shift
      ;;
    -p|--proxy)
      export GIT_PROXY="-c http.sslVerify=false -c http.https://github.com.proxy=$2"
      export CURL_PROXY="-x $2"
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
modules='^(all|zlib|icu|openssl|boost_build|boost|qtbase|qttools|libtorrent|qbittorrent)$'
#
## The installation is modular. You can select the parts you want or need here or using ./scriptname module or install everything using ./scriptname all
#
[[ "$1" = 'all' ]] && skip_zlib='no' || skip_zlib='yes'
[[ "$1" = 'all' ]] && skip_icu="$SKIP_ICU" || skip_icu='yes'
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
[[ "$1" =~ $modules ]] && { mkdir -p "$install_dir/logs"; mkdir -p "$install_dir/completed"; echo 'using python : '"$python_short_version"' : /usr/bin/python'"$python_short_version"' : /usr/include/python'"$python_short_version"' : /usr/lib/python'"$python_short_version"' ;' > "$HOME/user-config.jam"; }
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
## Define some build specific variables
#
export PATH="$install_dir/bin:$HOME/bin${PATH:+:${PATH}}"
export LD_LIBRARY_PATH="-L$lib_dir"
export PKG_CONFIG_PATH="-L$lib_dir/pkgconfig"
export local_boost="--with-boost=$install_dir"
export local_openssl="--with-openssl=$install_dir"
#
## Curl
#
curl="curl --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 10 --retry-max-time 60 --retry-connrefused ${CURL_PROXY} -sNLk"
#
## Functions
#
download_file () {
    url_filename="${2}"
    [[ -n "$3" ]] && subdir="/$3" || subdir=""
    echo -e "\n\e[32mInstalling $1\e[0m\n"
    file_name="$install_dir/$1.tar.gz"
    [[ -f "$file_name" ]] && rm -rf {"$install_dir/$(tar tf "$file_name" | grep -Eom1 "(.*)[^/]")","$file_name"}
    ${curl} "${url_filename}" -o "$file_name"
    tar xf "$file_name" -C "$install_dir"
    cd "$install_dir/$(tar tf "$file_name" | head -1 | cut -f1 -d"/")${subdir}"
}
#
download_folder () {
    github_tag="${1}_github_tag"
    url_github="${2}"
    [[ -n "$3" ]] && subdir="/$3" || subdir=""
    echo -e "\n\e[32mInstalling $1\e[0m\n"
    folder_name="$install_dir/$1"
    [[ -d "$folder_name" ]] && rm -rf "$folder_name"
    git ${GIT_PROXY} clone --no-tags --single-branch --branch "${!github_tag}" --shallow-submodules --recurse-submodules -j$(nproc) --depth 1 "${url_github}" "${folder_name}"
    cd "${folder_name}${subdir}"
}
#
## a file deletion function
#
delete_function () {
    if [[ "$SKIP_DELETE" = 'no' ]]; then
        if [[ "$2" = 'last' ]]; then
            echo -e "\n\e[91mDeleting $1 installation files and folders\e[0m\n"
        else
            echo -e "\n\e[91mDeleting $1 installation files and folders\e[0m"
        fi
        #
        file_name="$install_dir/$1.tar.gz"
        folder_name="$install_dir/$1"
        [[ -f "$file_name" ]] && rm -rf {"$install_dir/$(tar tf "$file_name" | grep -Eom1 "(.*)[^/]")","$file_name"}
        [[ -d "$folder_name" ]] && rm -rf "$folder_name"
        cd "$WORKING_DIR"
    fi
    #
    if [[ "$SKIP_DELETE" = 'yes' ]]; then
        if [[ "$2" = 'last' ]]; then
            echo -e "\n\e[91mSkipping $1 deletion\e[0m\n"
        else
            echo -e "\n\e[91mSkipping $1 deletion\e[0m"
        fi
    fi
}
#
## Define some URLs to download our apps. They are dynamic and set the most recent version or release.
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
export boost_build_github_tag="boost-$boost_version"
export boost_url="https://dl.bintray.com/boostorg/release/$boost_version/source/boost_${boost_version//./_}.tar.gz"
export boost_url_status="$(curl -o /dev/null --silent --head --write-out '%{http_code}' https://dl.bintray.com/boostorg/release/$boost_version/source/boost_${boost_version//./_}.tar.gz)"
export boost_build_url="https://github.com/boostorg/build/archive/$boost_github_tag.tar.gz"
#
export qt_version='5.15'
export qtbase_github_tag="$(curl -sNL https://github.com/qt/qtbase/releases | grep -Eom1 "v$qt_version.([0-9]{1,2})")"
export qttools_github_tag="$(curl -sNL https://github.com/qt/qttools/releases | grep -Eom1 "v$qt_version.([0-9]{1,2})")"
#
export libtorrent_version='1.2'
if [[ "$GITHUB_TAG" = 'master' ]]; then
    export libtorrent_github_tag="RC_${libtorrent_version//./_}"
else
    export libtorrent_github_tag="$(curl -sNL https://github.com/arvidn/libtorrent/releases | grep -Eom1 "v$libtorrent_version.([0-9]{1,2})")"
fi
#
if [[ "$GITHUB_TAG" = 'master' ]]; then
    export qbittorrent_github_tag="master"
else
    export qbittorrent_github_tag="$(curl -sNL https://github.com/qbittorrent/qBittorrent/releases | grep -Eom1 'release-([0-9]{1,4}\.?)+')"
fi
#
## zlib installation
#
if [[ "$skip_zlib" = 'no' ||  "$1" = 'zlib' ]]; then
    custom_flags_set
    download_file "zlib" "$zlib_url"
    #
    ./configure --prefix="$install_dir" --static 2>&1 | tee "$install_dir/logs/zlib.log.txt"
    make -j$(nproc) CXXFLAGS="$CXXFLAGS" CPPFLAGS="$CPPFLAGS" LDFLAGS="$LDFLAGS" 2>&1 | tee -a "$install_dir/logs/zlib.log.txt"
    make install 2>&1 | tee -a "$install_dir/logs/zlib.log.txt"
    #
    delete_function "zlib"
else
    echo -e "\nSkipping \e[95mzlib\e[0m module installation"
fi
#
## ICU installation
#
if [[ "$skip_icu" = 'no' || "$1" = 'icu' ]]; then
    custom_flags_set
    download_file "icu" "$icu_url" "source"
    #
    ./configure --prefix="$install_dir" --disable-shared --enable-static CXXFLAGS="$CXXFLAGS" CPPFLAGS="$CPPFLAGS" LDFLAGS="$LDFLAGS" 2>&1 | tee "$install_dir/logs/icu.log.txt"
    make -j$(nproc) 2>&1 | tee -a "$install_dir/logs/icu.log.txt"
    make install 2>&1 | tee -a "$install_dir/logs/icu.log.txt"
    #
    delete_function "icu"
else
    [[ "$skip_zlib" = 'no' ]] || [[ "$skip_zlib" = 'yes' && "$1" =~ $modules ]] && echo -e "\nSkipping \e[95micu\e[0m module installation"
    [[ "$skip_zlib" = 'yes' && ! "$1" =~ $modules ]] && echo -e "Skipping \e[95micu\e[0m module installation"
fi
#
## openssl installation
#
if [[ "$skip_openssl" = 'no' || "$1" = 'openssl' ]]; then
    custom_flags_set
    download_file "openssl" "$openssl_url"
    #
    ./config --prefix="$install_dir" threads no-shared no-dso no-comp CXXFLAGS="$CXXFLAGS" CPPFLAGS="$CPPFLAGS" LDFLAGS="$LDFLAGS" 2>&1 | tee "$install_dir/logs/openssl.log.txt"
    make -j$(nproc) 2>&1 | tee -a "$install_dir/logs/openssl.log.txt"
    make install_sw install_ssldirs 2>&1 | tee -a "$install_dir/logs/openssl.log.txt"
    #
    delete_function "openssl"
else
    [[ "$skip_icu" = 'no' ]] || [[ "$skip_icu" = 'yes' && "$1" =~ $modules ]] && echo -e "\nSkipping \e[95mopenssl\e[0m module installation"
    [[ "$skip_icu" = 'yes' && ! "$1" =~ $modules ]] && echo -e "Skipping \e[95mopenssl\e[0m module installation"
fi
#
## boost build install
#
if [[ "$skip_boost_build" = 'no' ]] || [[ "$1" = 'boost_build' ]]; then
    custom_flags_set
    download_file "boost_build" "$boost_build_url"
    #
    ./bootstrap.sh 2>&1 | tee "$install_dir/logs/boost_build.log.txt"
    ./b2 install --prefix="$install_dir" 2>&1 | tee -a "$install_dir/logs/boost_build.log.txt"
    #
    delete_function "boost_build"
else
    [[ "$skip_openssl" = 'no' ]] || [[ "$skip_openssl" = 'yes' && "$1" =~ $modules ]] && echo -e "\nSkipping \e[95mboost_build\e[0m module installation"
    [[ "$skip_openssl" = 'yes' && ! "$1" =~ $modules ]] && echo -e "Skipping \e[95mboost_build\e[0m module installation"
fi
#
## boost libraries install
#
if [[ "$skip_boost" = 'no' ]] || [[ "$1" = 'boost' ]]; then
    custom_flags_set
    #
    if [[ "$boost_url_status" -eq '200' ]]; then
        download_file "boost" "$boost_url"
        mv -f "$install_dir/boost_${boost_version//./_}/" "$install_dir/boost"
    fi
    #
    if [[ "$boost_url_status" -eq '403' ]]; then
        download_folder "boost" "https://github.com/boostorg/boost.git"
    fi
    #
    ./bootstrap.sh 2>&1 | tee "$install_dir/logs/boost.log.txt"
    "$install_dir/bin/b2" -j$(nproc) python="$python_short_version" variant=release threading=multi link=static cxxstd=14 cxxflags="$CXXFLAGS" cflags="$CPPFLAGS" linkflags="$LDFLAGS" toolset=gcc install --prefix="$install_dir" 2>&1 | tee -a "$install_dir/logs/boost.log.txt"
else
    [[ "$skip_boost_build" = 'no' ]] || [[ "$skip_boost_build" = 'yes' && "$1" =~ $modules ]] && echo -e "\nSkipping \e[95mboost\e[0m module installation"
    [[ "$skip_boost_build" = 'yes' && ! "$1" =~ $modules ]] && echo -e "Skipping \e[95mboost\e[0m module installation"
fi
#
## qt base install
#
if [[ "$skip_qtbase" = 'no' ]] || [[ "$1" = 'qtbase' ]]; then
    custom_flags_set
    download_folder "qtbase" "https://github.com/qt/qtbase.git"
    #
    ./configure -prefix "$install_dir" -opensource -confirm-license -release -openssl-linked -static -c++std c++14 -no-feature-c++17 -no-feature-opengl -no-feature-dbus -no-feature-gui -no-feature-widgets -no-feature-testlib -no-compile-examples -I "$include_dir" -L "$lib_dir" QMAKE_LFLAGS="$LDFLAGS" 2>&1 | tee "$install_dir/logs/qtbase.log.txt"
    make -j$(nproc) 2>&1 | tee -a "$install_dir/logs/qtbase.log.txt"
    make install 2>&1 | tee -a "$install_dir/logs/qtbase.log.txt"
    #
    delete_function qtbase
else
    [[ "$skip_boost" = 'no' ]] || [[ "$skip_boost" = 'yes' && "$1" =~ $modules ]] && echo -e "\nSkipping \e[95mqtbase\e[0m module installation"
    [[ "$skip_boost" = 'yes' && ! "$1" =~ $modules ]] && echo -e "Skipping \e[95mqtbase\e[0m module installation"
fi
#
## qt tools install
#
if [[ "$skip_qttools" = 'no' ]] || [[ "$1" = 'qttools' ]]; then
    custom_flags_set
    download_folder "qttools" "https://github.com/qt/qttools.git"
    #
    "$install_dir/bin/qmake" -set prefix "$install_dir" 2>&1 | tee "$install_dir/logs/qttools.log.txt"
    "$install_dir/bin/qmake" 2>&1 | tee -a "$install_dir/logs/qttools.log.txt"
    make -j$(nproc) 2>&1 | tee -a "$install_dir/logs/qttools.log.txt"
    make install 2>&1 | tee -a "$install_dir/logs/qttools.log.txt"
    #
    delete_function qttools
else
    [[ "$skip_qtbase" = 'no' ]] || [[ "$skip_qtbase" = 'yes' && "$1" =~ $modules ]] && echo -e "\nSkipping \e[95mqttools\e[0m module installation"
    [[ "$skip_qtbase" = 'yes' && ! "$1" =~ $modules ]] && echo -e "Skipping \e[95mqttools\e[0m module installation"
fi
#
## libtorrent install
#
if [[ "$skip_libtorrent" = 'no' ]] || [[ "$1" = 'libtorrent' ]]; then
    if [[ ! -d "$install_dir/boost" ]]; then
        echo -e "\n\e[91mWarning\e[0m - You must install the boost module before you can use the libtorrent module"
    else
        custom_flags_set
        download_folder "libtorrent" "https://github.com/arvidn/libtorrent.git"
        #
        export BOOST_ROOT="$install_dir/boost"
        export BOOST_INCLUDEDIR="$install_dir/boost"
        export BOOST_BUILD_PATH="$install_dir/boost"
        #
        "$install_dir/bin/b2" -j$(nproc) python="$python_short_version" dht=on encryption=on crypto=openssl i2p=on extensions=on variant=release threading=multi link=static boost-link=static runtime-link=static cxxstd=14 cxxflags="$CXXFLAGS" cflags="$CPPFLAGS" linkflags="$LDFLAGS" toolset=gcc install --prefix="$install_dir" 2>&1 | tee "$install_dir/logs/libtorrent.log.txt"
        #
        delete_function boost
        delete_function libtorrent
    fi
else
    [[ "$skip_qttools" = 'no' ]] || [[ "$skip_qttools" = 'yes' && "$1" =~ $modules ]] && echo -e "\nSkipping \e[95mlibtorrent\e[0m module installation"
    [[ "$skip_qttools" = 'yes' && ! "$1" =~ $modules ]] && echo -e "Skipping \e[95mlibtorrent\e[0m module installation"
fi
#
## qBittorrent install (static)
#
if [[ "$skip_qbittorrent" = 'no' ]] || [[ "$1" = 'qbittorrent' ]]; then
    custom_flags_set
    download_folder "qbittorrent" "https://github.com/qbittorrent/qBittorrent.git"
    #
    ./bootstrap.sh 2>&1 | tee "$install_dir/logs/qbittorrent.log.txt"
    ./configure --prefix="$install_dir" "$local_boost" --disable-gui CXXFLAGS="$CXXFLAGS" CPPFLAGS="$CPPFLAGS" LDFLAGS="$LDFLAGS -l:libboost_system.a" openssl_CFLAGS="-I$include_dir" openssl_LIBS="-L$lib_dir -l:libcrypto.a -l:libssl.a" libtorrent_CFLAGS="-I$include_dir" libtorrent_LIBS="-L$lib_dir -l:libtorrent.a" zlib_CFLAGS="-I$include_dir" zlib_LIBS="-L$lib_dir -l:libz.a" QT_QMAKE="$install_dir/bin" 2>&1 | tee -a "$install_dir/logs/qbittorrent.log.txt"
    #
    sed -i 's/-lboost_system//' conf.pri
    sed -i 's/-lcrypto//' conf.pri
    sed -i 's/-lssl//' conf.pri
    #
    make -j$(nproc)
    make install
    #
    [[ -f "$install_dir/bin/qbittorrent-nox" ]] && cp -f "$install_dir/bin/qbittorrent-nox" "$install_dir/completed/qbittorrent-nox"
    #
    delete_function qbittorrent last
else
    [[ "$skip_libtorrent" = 'no' ]] || [[ "$skip_libtorrent" = 'yes' && "$1" =~ $modules ]] && echo -e "\nSkipping \e[95mqbittorrent\e[0m module installation\n"
    [[ "$skip_libtorrent" = 'yes' && ! "$1" =~ $modules ]] && echo -e "Skipping \e[95mqbittorrent\e[0m module installation\n"
fi
#
## Exit the script.
#
exit
