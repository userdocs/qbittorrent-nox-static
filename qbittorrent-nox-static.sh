#!/bin/bash
#
# cSpell:includeRegExp #.*
#
# Copyright 2020 by userdocs and contributors
#
# SPDX-License-Identifier: Apache-2.0
#
# @author - userdocs
#
# @contributors IceCodeNew Stanislas boredazfcuk AdvenT. guillaumedsde inochisa angristan xNihil0 Jercik voidtao
#
# https://github.com/userdocs/qbittorrent-nox-static/graphs/contributors
#
# @credits - https://gist.github.com/notsure2 https://github.com/c0re100/qBittorrent-Enhanced-Edition
#
# Script Formatting - https://marketplace.visualstudio.com/items?itemName=foxundermoon.shell-format
#
#################################################################################################################################################
# Script version = Major minor patch
#################################################################################################################################################
script_version="2.2.2"
#################################################################################################################################################
# Set some script features - https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
#################################################################################################################################################
set -a
#################################################################################################################################################
# Unset some variables to set defaults.
#################################################################################################################################################
unset qbt_skip_delete qbt_git_proxy qbt_curl_proxy qbt_install_dir qbt_working_dir qbt_modules_test qbt_python_version
unset qbt_cflags qbt_cxxflags_consumed qbt_cppflags_consumed qbt_ldflags_consumed
#################################################################################################################################################
# Declare our associative arrays
#################################################################################################################################################
# Associative arrays
declare -gA multi_arch_options qbt_test_tools qbt_core_deps qbt_deps_delete
declare -gA qbt_modules_delete skip_modules qbt_modules_install qbt_privileges_required
declare -gA github_url github_tag app_version source_archive_url qbt_workflow_archive_url
declare -gA qbt_workflow_override source_default qbt_activated_modules
# Indexed arrays
declare -ga qbt_modules_order qbt_modules_install_processed qbt_modules_selected_compare
#################################################################################################################################################
# Color me up Scotty - define some color values to use as variables in the scripts.
#################################################################################################################################################
color_red="\e[31m" color_red_light="\e[91m"
color_green="\e[32m" color_green_light="\e[92m"
color_yellow="\e[33m" color_yellow_light="\e[93m"
color_blue="\e[34m" color_blue_light="\e[94m"
color_magenta="\e[35m" color_magenta_light="\e[95m"
color_cyan="\e[36m" color_cyan_light="\e[96m"

text_bold="\e[1m" text_dim="\e[2m" text_underlined="\e[4m" text_blink="\e[5m" text_newline="\n"

unicode_red_circle="\e[31m\U2B24\e[0m" unicode_red_light_circle="\e[91m\U2B24\e[0m"
unicode_green_circle="\e[32m\U2B24\e[0m" unicode_green_light_circle="\e[92m\U2B24\e[0m"
unicode_yellow_circle="\e[33m\U2B24\e[0m" unicode_yellow_light_circle="\e[93m\U2B24\e[0m"
unicode_blue_circle="\e[34m\U2B24\e[0m" unicode_blue_light_circle="\e[94m\U2B24\e[0m"
unicode_magenta_circle="\e[35m\U2B24\e[0m" unicode_magenta_light_circle="\e[95m\U2B24\e[0m"
unicode_cyan_circle="\e[36m\U2B24\e[0m" unicode_cyan_light_circle="\e[96m\U2B24\e[0m"
unicode_grey_circle="\e[37m\U2B24\e[0m" unicode_grey_light_circle="\e[97m\U2B24\e[0m"

color_end="\e[0m"
#################################################################################################################################################
# Function to test color and show outputs in the terminal
#################################################################################################################################################
_color_test() {
	# Check if the terminal supports color output
	if [[ -t 1 ]]; then
		color_array=("${color_red}red" "${color_red_light}light red" "${color_green}green" "${color_green_light}light green" "${color_yellow}yellow" "${color_yellow_light}light yellow" "${color_blue}blue" "${color_blue_light}light blue" "${color_magenta}magenta" "${color_magenta_light}light magenta" "${color_cyan}cyan" "${color_cyan_light}light cyan")
		formatting_array=("${text_bold}Text Bold" "${text_dim}Text Dim" "${text_underlined}Text Underline" "${text_newline}New line" "${text_blink}Text Blink")
		unicode_array=("${unicode_red_circle}" "${unicode_red_light_circle}" "${unicode_green_circle}" "${unicode_green_light_circle}" "${unicode_yellow_circle}" "${unicode_yellow_light_circle}" "${unicode_blue_circle}" "${unicode_blue_light_circle}" "${unicode_magenta_circle}" "${unicode_magenta_light_circle}" "${unicode_cyan_circle}" "${unicode_cyan_light_circle}" "${unicode_grey_circle}" "${unicode_grey_light_circle}")
		printf '\n'
		for colors in "${color_array[@]}" "${formatting_array[@]}" "${unicode_array[@]}"; do
			printf '%b\n' "${colors}${color_end}"
		done
		printf '\n'
		exit
	else
		echo "The terminal does not support color output."
		exit
	fi
}
[[ ${1} == "ctest" ]] && _color_test # ./scriptname.sh ctest
#######################################################################################################################################################
# Get script basename and full path
#######################################################################################################################################################
script_full_path="$(readlink -f "${BASH_SOURCE[0]}")"
script_parent_path="${script_full_path%/*}"
script_basename="${script_full_path##*/}"
#######################################################################################################################################################
# Function to source /etc/os-release and get info from it on demand.
#######################################################################################################################################################
get_os_info() {
	# shellcheck source=/dev/null
	if source /etc/os-release &> /dev/null; then
		printf "%s" "${!1%_*}" # the expansion part is specific to the Alpine VERSION_ID format 1.2.3_alpha but won't break anything in Debian based format e.g. 12/24.04
	else
		printf "%s" "unknown" # This will make the script exit on the version check and provide useful reason.
	fi
}
#######################################################################################################################################################
# Checks to see if we are on a supported OS and release.
#######################################################################################################################################################
os_id="$(get_os_info ID)"                                    # Get the ID for this OS.
os_version_codename="$(get_os_info VERSION_CODENAME)"        # Get the codename for this OS. Note, Alpine does not have a unique codename.
os_version_id="$(get_os_info VERSION_ID)"                    # Get the version number for this codename, for example: 10, 20.04, 3.12.4
[[ ${os_id} =~ ^(alpine)$ ]] && os_version_codename="alpine" # If alpine, set the codename to alpine. We check for min v3.10 later with codenames.

if [[ ${os_id} =~ ^(debian|ubuntu)$ ]]; then
	# dpkg --print-architecture give amd64/arm64 and arch gives x86_64/aarch64
	os_arch="$(dpkg --print-architecture)"
elif [[ ${os_id} =~ ^(alpine)$ ]]; then
	# apk --print-arch gives x86_64/aarch64
	os_arch="$(apk --print-arch)"
fi

# Check against allowed codenames or if the codename is alpine version greater than 3.10
if [[ ! ${os_version_codename} =~ ^(alpine|trixie|noble)$ ]] || [[ ${os_version_codename} =~ ^(alpine)$ && "$(apk version -t "${os_version_id}" "3.18")" == "<" ]]; then
	printf '\n%b\n\n' " ${unicode_red_circle} ${color_yellow} This is not a supported OS. There is no reason to continue.${color_end}"
	printf '%b\n\n' " id: ${text_dim}${color_yellow_light}${os_id}${color_end} codename: ${text_dim}${color_yellow_light}${os_version_codename}${color_end} version: ${text_dim}${color_red_light}${os_version_id}${color_end}"
	printf '%b\n\n' " ${unicode_yellow_circle} ${text_dim}These are the supported platforms${color_end}"
	printf '%b\n' " ${color_magenta_light}Debian${color_end} - ${color_blue_light}trixie${color_end}"
	printf '%b\n' " ${color_magenta_light}Ubuntu${color_end} - ${color_blue_light}noble${color_end}"
	printf '%b\n\n' " ${color_magenta_light}Alpine${color_end} - ${color_blue_light}3.18${color_end} ${text_dim}or greater${color_end}"
	exit
fi
#######################################################################################################################################################
# Source env vars from a file if it exists but it will be overridden by switches and flags passed to the script
#######################################################################################################################################################
if [[ -f "${script_parent_path}/.qbt_env" ]]; then
	printf '\n%b\n' " ${unicode_magenta_circle} Sourcing ${color_blue_light}.qbt_env${color_end} file - ${color_red_light}This will override your settings!${color_end}"
	# shellcheck source=/dev/null
	source "${script_parent_path}/.qbt_env"
fi
#######################################################################################################################################################
# Multi arch stuff - Define all available multi arches we use from here https://github.com/userdocs/qbt-musl-cross-make#readme
#######################################################################################################################################################
multi_arch_options["default"]="default"
multi_arch_options["aarch64"]="aarch64"
multi_arch_options["armel"]="armel"
multi_arch_options["armhf"]="armhf"
multi_arch_options["armv7"]="armv7"
multi_arch_options["x86"]="x86"
multi_arch_options["x86_64"]="x86_64"
multi_arch_options["mips"]="mips"
multi_arch_options["mipsel"]="mipsel"
multi_arch_options["mips64"]="mips64"
multi_arch_options["mips64el"]="mips64el"
multi_arch_options["powerpc"]="powerpc"
multi_arch_options["ppc64el"]="ppc64el"
multi_arch_options["s390x"]="s390x"
multi_arch_options["riscv64"]="riscv64"
multi_arch_options["loongarch64"]="loongarch64"
#######################################################################################################################################################
# This function sets some default values we use but whose values can be overridden by certain flags or exported as variables before running the script
#######################################################################################################################################################
_set_default_values() {
	# For debian based docker deploys to not get prompted to set the timezone.
	if [[ ${os_id} =~ ^(debian|ubuntu)$ ]]; then
		export DEBIAN_FRONTEND="noninteractive"
		export TZ="Europe/London"
	fi

	# If set to yes the script behaves like qbittorrent-nox-static.sh and automatically install core deps if it has the privileges and any are required.
	qbt_legacy_mode="${qbt_legacy_mode:-yes}"
	# hide certain options by default to not confuse on first run. Lots of options are not really needed for a basic build.
	qbt_advanced_view="${qbt_advanced_view:-yes}"

	# qbt mcm docker images - these env settings tell the script that the host env is the cross build containers
	# Otherwise the script thinks the cross build container host is native and applies the wrong settings.
	QBT_MCM_DOCKER="${QBT_MCM_DOCKER:-}"
	QBT_MCM_TARGET="${QBT_MCM_TARGET:-}"
	QBT_CROSS_NAME="${QBT_CROSS_NAME:-}"

	# Set the working dir to our current location and all things well be relative to this location.
	qbt_working_dir="$(pwd)"

	# Used with printf. Use the qbt_working_dir variable but the ${HOME} path is replaced with a literal ~
	qbt_working_dir_short="${qbt_working_dir/${HOME}/\~}"

	qbt_build_dir="${qbt_build_dir:-qbt-build}" # Build directory

	# Install relative to the script location.
	qbt_install_dir="${qbt_working_dir}/${qbt_build_dir}"

	# Used with printf. Use the qbt_install_dir variable but the ${HOME} path is replaced with a literal ~
	qbt_install_dir_short="${qbt_install_dir/${HOME}/\~}"

	# Default to empty to use host native build tools. This way we can build on native arch on a supported OS and skip cross build toolchains
	# This will override .qbt_env qbt_cross_name setting.
	if [[ -n ${QBT_CROSS_NAME} ]]; then
		qbt_cross_name="${QBT_CROSS_NAME}"
	else
		qbt_cross_name="${qbt_cross_name:-default}"
	fi

	qbt_with_qemu="${qbt_with_qemu:-yes}"

	# module management - We can choose to install normal zlib (motley) or zlib-ng. For now defaulting to zlib due to a arch detection bug in zlib-ng
	qbt_zlib_type=${qbt_zlib_type:-zlib}

	# The default build configuration is qmake + qt5, qbt_build_tool=cmake or -c will make qt6 and cmake default
	qbt_build_tool="${qbt_build_tool:-cmake}"

	# Default to host - we are not really using this for anything other than what it defaults to so no need to set it.
	qbt_cross_target="${qbt_cross_target:-${os_id}}"

	# yes to create debug build to use with gdb - disables stripping - for some reason libtorrent b2 builds are 200MB or larger. qbt_build_debug=yes or -d
	qbt_build_debug="${qbt_build_debug:-no}"

	# github actions workflows - use https://github.com/userdocs/qbt-workflow-files/releases/latest instead of direct downloads from various source locations.
	qbt_workflow_files="${qbt_workflow_files:-no}"

	# Provide a git username and repo in this format - username/repo
	# In this repo the structure needs to be like this /patches/libtorrent/1.2.11/patch and/or /patches/qbittorrent/4.3.1/patch
	# your patch file will be automatically fetched and loaded for those matching tags.
	qbt_patches_url="${qbt_patches_url:-userdocs/qbittorrent-nox-static}"

	# testing = easy way to switch to test qbt-musl-cross-make-test builds via an env in the workflow.
	qbt_mcm_url="${qbt_mcm_url:-userdocs/qbt-musl-cross-make}"

	# Default to this version of libtorrent is no tag or branch is specified. qbt_libtorrent_version=1.2 or -lt v1.2.18
	qbt_libtorrent_version="${qbt_libtorrent_version:-2.0}"

	# Use release Jamfile unless we need a specific fix from the relevant RC branch.
	# Using this can also break builds when non backported changes are present which will require a custom jamfile
	qbt_libtorrent_master_jamfile="${qbt_libtorrent_master_jamfile:-no}"

	# Strip symbols by default as we need full debug builds to be useful gdb to backtrace so stripping is a sensible default optimization.
	qbt_optimise_strip="${qbt_optimise_strip:-yes}"

	# Github actions specific - Build revisions - The workflow will set this dynamically so that the urls are not hardcoded to a single repo
	qbt_revision_url="${qbt_revision_url:-userdocs/qbittorrent-nox-static}"

	# Provide a path to check for cached local git repos and use those instead. Priority over workflow files.
	qbt_cache_dir="${qbt_cache_dir%/}"

	# Env setting for the icu tag
	qbt_skip_icu="${qbt_skip_icu:-yes}"

	if [[ ${qbt_with_qemu} == "yes" ]] || [[ ${qbt_with_qemu} == "no" && ${qbt_host_deps} == "yes" ]]; then
		qbt_modules_delete["icu_host_deps"]="true"
		qbt_modules_delete["qtbase_host_deps"]="true"
		qbt_modules_delete["qttools_host_deps"]="true"
	fi

	if [[ ${qbt_with_qemu} == "no" ]]; then
		if [[ ${qbt_skip_icu} == "yes" ]]; then
			qbt_modules_delete["icu_host_deps"]="true"
		fi
	fi

	# Default to expecting qemu to be present for cross builds.
	# yes will use the _qbt_host_deps function to pull in this prebuilt dependency package https://github.com/userdocs/qbt-host-deps
	qbt_host_deps="${qbt_host_deps:-no}"
	# Where are the deps installed to relative to qbt_install_dir
	qbt_host_deps_path="${qbt_install_dir}/host_deps"
	# Which repo is hosting them.
	qbt_host_deps_repo="${qbt_host_deps_repo:-userdocs/qbt-host-deps}"

	# dependency version management - Env setting for the boost tag
	if [[ ${qbt_libtorrent_version} == "1.2" || ${qbt_libtorrent_tag} =~ ^(v1\.2\.|RC_1_2) ]]; then
		qbt_boost_tag="${qbt_boost_tag:-boost-1.86.0}"
	else
		qbt_boost_tag="${qbt_boost_tag:-}"
	fi

	# module management - libtorrent v1.2 is the module that requires iconv otherwise it's not needed.
	_libtorrent_v2_iconv_check

	# Env setting for the libtorrent tag
	qbt_libtorrent_tag="${qbt_libtorrent_tag:-}"

	# Env setting for the Qt tag
	qbt_qt_tag="${qbt_qt_tag:-}"

	# Env setting for the qbittorrent tag
	qbt_qbittorrent_tag="${qbt_qbittorrent_tag:-}"

	# We are only using python3 but it's easier to just change this if we need to for some reason.
	qbt_python_version="3"

	# provide gcc flags for the build - this is not used by default but can be set to provide custom flags for the build.
	qbt_optimise="${qbt_optimise:-no}"

	# The default is 17 but can be manually defined via the env qbt_standard - this will be overridden by the _set_cxx_standard function in specific cases
	qbt_standard="${qbt_standard:-20}" qbt_cxx_standard="c++${qbt_standard}"

	# Get the local users $PATH before we isolate the script by setting HOME to the install dir in the _set_build_directory function.
	qbt_local_paths="$PATH"

	# The Alpine repository we use for package sources
	CDN_URL="http://dl-cdn.alpinelinux.org/alpine/edge/main" # for alpine

	# Dynamic tests to change settings based on the use of qmake,cmake,strip and debug
	if [[ ${qbt_build_debug} == "yes" ]]; then
		qbt_optimise_strip="no"
		qbt_cmake_debug='ON'
		qbt_libtorrent_debug='debug-symbols=on'
		qbt_qbittorrent_debug='--enable-debug'
		qbt_cmake_build_type="Debug"
		qbt_openssl_build_type="--debug"
	else
		qbt_cmake_debug='OFF'
		qbt_cmake_build_type="Release"
		qbt_openssl_build_type="--release"
	fi

	# module management - staticish builds - remove glibc module so it links to system glibc
	if [[ ${qbt_static_ish:=no} == "yes" ]]; then
		if [[ ${os_id} =~ ^(debian|ubuntu)$ ]]; then qbt_modules_delete["glibc"]="true"; fi
		if [[ ${qbt_cross_name} != "default" ]]; then
			printf '\n%b\n\n' " ${unicode_red_light_circle} You cannot use the ${color_blue_light}-si${color_end} flag with cross compilation${color_end}"
			exit
		fi
	fi

	# Dynamic tests to change settings based on the use of qmake,cmake,strip and debug
	case "${qbt_qt_version}" in
		5)
			if [[ ${qbt_build_tool} != 'cmake' ]]; then
				qbt_build_tool="qmake"
				qbt_use_qt6="OFF"
			fi
			;;&
		6)
			qbt_build_tool="cmake"
			qbt_use_qt6="ON"
			;;&
		"")
			[[ ${qbt_build_tool} == 'cmake' ]] && qbt_qt_version="6" || qbt_qt_version="5"
			;;&
		*)
			[[ ! ${qbt_qt_version} =~ ^(5|6)$ ]] && qbt_workflow_files="no"
			[[ ${qbt_build_tool} == 'qmake' && ${qbt_qt_version} =~ ^6 ]] && qbt_build_tool="cmake"
			[[ ${qbt_build_tool} == 'cmake' && ${qbt_qt_version} =~ ^5 ]] && qbt_build_tool="cmake" qbt_qt_version="6"
			[[ ${qbt_build_tool} == 'cmake' && ${qbt_qt_version} =~ ^6 ]] && qbt_use_qt6="ON"
			;;
	esac

	# If we are cross building then bootstrap the cross build tools we need for the target arch else set native arch and remove the debian cross build tools
	if [[ ${multi_arch_options[${qbt_cross_name}]} == "${qbt_cross_name}" && ${qbt_cross_name} != "default" ]]; then
		_multi_arch info_bootstrap
	else
		cross_arch="$(uname -m)"
		qbt_deps_delete["crossbuild-essential-${cross_arch}"]="true"
	fi
	#######################################################################################################################################################
	# Create some associative arrays to use with checks to establish, modules, dependencies, privileges and required tools for the script to run.
	#######################################################################################################################################################

	# Define our list of available modules in a associative array for checks and a indexed array for order.
	qbt_modules_install["all"]="true" && qbt_modules_order=("all")
	qbt_modules_install["install"]="true" && qbt_modules_order+=("install")
	qbt_modules_install["glibc"]="true" && qbt_modules_order+=("glibc")
	qbt_modules_install["zlib"]="true" && qbt_modules_order+=("zlib")
	qbt_modules_install["iconv"]="true" && qbt_modules_order+=("iconv")
	qbt_modules_install["icu_host_deps"]="true" && qbt_modules_order+=("icu_host_deps")
	qbt_modules_install["icu"]="true" && qbt_modules_order+=("icu")
	qbt_modules_install["openssl"]="true" && qbt_modules_order+=("openssl")
	qbt_modules_install["boost"]="true" && qbt_modules_order+=("boost")
	qbt_modules_install["libtorrent"]="true" && qbt_modules_order+=("libtorrent")
	# qbt_modules_install["double_conversion"]="true" && qbt_modules_order+=("double_conversion")
	qbt_modules_install["qtbase_host_deps"]="true" && qbt_modules_order+=("qtbase_host_deps")
	qbt_modules_install["qtbase"]="true" && qbt_modules_order+=("qtbase")
	qbt_modules_install["qttools_host_deps"]="true" && qbt_modules_order+=("qttools_host_deps")
	qbt_modules_install["qttools"]="true" && qbt_modules_order+=("qttools")
	qbt_modules_install["qbittorrent"]="true" && qbt_modules_order+=("qbittorrent")

	# Define our list of privilege checks
	qbt_privileges_required["root"]="false"
	qbt_privileges_required["sudo"]="false"

	# Define our list of required test tools to performs basic script functions
	qbt_test_tools["curl"]="false"
	qbt_test_tools["bash"]="false"
	qbt_test_tools["git"]="false"

	# Define our list of required dependencies per supported OS for the script to run
	if [[ ${os_id} =~ ^(alpine)$ ]]; then # Alpine specific dependencies
		qbt_modules_delete["glibc"]="true"

		if [[ -z ${qbt_cache_dir} ]]; then
			qbt_deps_delete["coreutils"]="true"
			qbt_deps_delete["gpg"]="true"
		fi

		qbt_core_deps["autoconf"]="false"
		qbt_core_deps["build-base"]="false"
		qbt_core_deps["coreutils"]="false"
		qbt_core_deps["cmake"]="false"
		qbt_core_deps["ninja-build"]="false"
		qbt_core_deps["ninja-is-really-ninja"]="false"
		qbt_core_deps["gpg"]="false"
		qbt_core_deps["linux-headers"]="false"
		qbt_core_deps["pkgconf"]="false"
		qbt_core_deps["py${qbt_python_version}-numpy"]="false"
		qbt_core_deps["py${qbt_python_version}-numpy-dev"]="false"
		qbt_core_deps["ttf-freefont"]="false"
		qbt_core_deps["xz"]="false"
		# qbt_core_deps["musl-dbg"]="false"
		# qbt_core_deps["linux-headers"]="false"

		if [[ ${qbt_host_deps} == "yes" ]] || [[ ${qbt_with_qemu} == "yes" && ${qbt_cross_name} != "default" ]]; then
			qbt_core_deps["file"]="false"
			qbt_core_deps["fortify-headers"]="false"
			qbt_core_deps["libc-dev"]="false"
			qbt_core_deps["make"]="false"
			qbt_core_deps["patch"]="false"

			qbt_deps_delete["build-base"]="false"
		fi
	fi

	if [[ ${os_id} =~ ^(debian|ubuntu)$ ]]; then # Debian specific dependencies
		if [[ -z ${qbt_cache_dir} ]]; then
			qbt_deps_delete["autopoint"]="true"
			qbt_deps_delete["gperf"]="true"
		fi

		if [[ -z ${qbt_cache_dir} ]]; then
			qbt_deps_delete["autopoint"]="true"
			qbt_deps_delete["gperf"]="true"
		fi

		qbt_core_deps["autopoint"]="false"
		qbt_core_deps["bison"]="false"
		qbt_core_deps["build-essential"]="false"
		qbt_core_deps["cmake"]="false"
		qbt_core_deps["crossbuild-essential-${cross_arch}"]="false"
		qbt_core_deps["gawk"]="false"
		qbt_core_deps["gettext"]="false"
		qbt_core_deps["gperf"]="false"
		qbt_core_deps["ninja-build"]="false"
		qbt_core_deps["openssl"]="false"
		qbt_core_deps["pkg-config"]="false"
		qbt_core_deps["python${qbt_python_version}-numpy"]="false"
		qbt_core_deps["texinfo"]="false"
		qbt_core_deps["unzip"]="false"
		qbt_core_deps["xz-utils"]="false"

		if [[ ${qbt_host_deps} == "yes" ]] || [[ ${qbt_with_qemu} == "yes" && ${qbt_cross_name} != "default" ]]; then
			qbt_core_deps["libc6-dev"]="false"
			qbt_core_deps["make"]="false"
			qbt_core_deps["patch"]="false"

			qbt_deps_delete["build-essential"]="false"
		fi
	fi

	# Deps with same package name across Alpine and Debian based systems

	qbt_core_deps["automake"]="false"
	qbt_core_deps["bash"]="false"
	qbt_core_deps["curl"]="false"
	qbt_core_deps["git"]="false"
	qbt_core_deps["graphviz"]="false"
	qbt_core_deps["libtool"]="false"
	qbt_core_deps["perl"]="false"
	qbt_core_deps["python${qbt_python_version}"]="false"
	qbt_core_deps["python${qbt_python_version}-dev"]="false"
	qbt_core_deps["re2c"]="false"

	# remove this module by default unless provided as a first argument to the script.
	if [[ ${1} != 'install' ]]; then
		qbt_modules_delete["install"]="true"
	fi

	# Don't remove the icu module if it was provided as a positional parameter.
	if [[ ${*} =~ ([[:space:]]|^)"icu"([[:space:]]|$) ]]; then
		qbt_skip_icu="no"
	fi

	# Skip icu by default unless the -i flag is provided.
	if [[ ${qbt_skip_icu} != "no" ]]; then
		qbt_modules_delete["icu"]="true"
	fi

	# Configure default dependencies and modules if cmake is not specified
	if [[ ${qbt_build_tool} != 'cmake' ]]; then
		qbt_deps_delete["cmake"]="true"
		qbt_deps_delete["graphviz"]="true"
		qbt_deps_delete["ninja-build"]="true"
		qbt_deps_delete["ninja-is-really-ninja"]="true"
		qbt_deps_delete["re2c"]="true"
		qbt_deps_delete["ttf-freefont"]="true"
		qbt_deps_delete["unzip"]="true"

		qbt_modules_delete["double_conversion"]="true"

	else
		if [[ ${qbt_skip_icu} != "no" ]]; then
			qbt_modules_delete["icu"]="true"
		fi
	fi
}
#######################################################################################################################################################
# These functions set some build conditions dynamically based on the libtorrent versions, qt version and qbittorrent combinations
#######################################################################################################################################################
_qt_std_cons() {
	if [[ ${qbt_qt_version} == "6" ]]; then
		printf "yes"
		return
	fi
	printf "no"
}

_os_std_cons() {
	if [[ ${os_version_codename} =~ ^(alpine|trixie|noble)$ ]]; then
		printf "yes"
		return
	fi
	printf "no"
}

_libtorrent_std_cons() {
	if [[ ${github_tag[libtorrent]} =~ ^(RC_1_2|RC_2_0)$ ]]; then
		printf "yes"
		return
	fi

	if [[ ${github_tag[libtorrent]} =~ ^v1\.2\. && "$(_semantic_version "${github_tag[libtorrent]/v/}")" -ge "$(_semantic_version "1.2.19")" ]]; then
		printf "yes"
		return
	fi
	if [[ ${github_tag[libtorrent]} =~ ^v2\.0\. && "$(_semantic_version "${github_tag[libtorrent]/v/}")" -ge "$(_semantic_version "2.0.10")" ]]; then
		printf "yes"
		return
	fi
	printf 'no'
}

_qbittorrent_std_cons() {
	if [[ ${github_tag[qbittorrent]} == "master" ]]; then
		printf "yes"
		return
	fi

	if [[ ${github_tag[qbittorrent]} =~ ^release- && "$(_semantic_version "${github_tag[qbittorrent]/release-/}")" -ge "$(_semantic_version "4.6.0")" ]]; then
		printf "yes"
		return
	fi
	printf 'no'
}

_qbittorrent_build_cons() {
	if [[ ${github_tag[qbittorrent]} == "master" ]]; then
		printf "yes"
		return
	fi

	if [[ ${github_tag[qbittorrent]} == "v5_0_x" ]]; then
		printf "yes"
		return
	fi

	if [[ ${github_tag[qbittorrent]} =~ ^release- && "$(_semantic_version "${github_tag[qbittorrent]/release-/}")" -ge "$(_semantic_version "5.0.0")" ]]; then
		printf "yes"
		return
	fi
	printf 'no'
}

_set_cxx_standard() {
	if [[ "$(_qt_std_cons)" == "yes" && "$(_os_std_cons)" == "yes" && "$(_libtorrent_std_cons)" == "yes" && "$(_qbittorrent_std_cons)" == "yes" ]]; then
		qbt_standard="20" qbt_cxx_standard="c++${qbt_standard}"
	else
		qbt_standard="17" qbt_cxx_standard="c++${qbt_standard}"
	fi
}

_set_build_cons() {
	if [[ "$(_qbittorrent_build_cons)" == "yes" && ${qbt_qt_version} == "5" ]]; then
		printf '\n%b\n\n' " ${text_blink}${unicode_red_light_circle}${color_end} ${color_yellow}qBittorrent ${color_magenta}${github_tag[qbittorrent]}${color_yellow} does not support ${color_red}Qt5${color_yellow}. Please use ${color_green}Qt6${color_yellow} or a qBittorrent ${color_green}v4${color_yellow} tag.${color_end}"
		exit_script="yes"
	elif [[ "$(_qbittorrent_build_cons)" == "yes" && "$(_os_std_cons)" == "no" ]]; then
		printf '\n%b\n\n' " ${text_blink}${unicode_red_light_circle}${color_end} ${color_yellow}qBittorrent ${color_magenta}${github_tag[qbittorrent]}${color_yellow} does not support less than ${color_red}c++20${color_yellow}. Please use an OS with a more modern compiler for v5${color_end}"
		exit_script="yes"
	fi

	if [[ ${exit_script} == "yes" ]]; then
		if [[ -n ${GITHUB_REPOSITORY} ]]; then touch disable-qt5; fi
		if [[ -d ${release_info_dir} ]]; then touch "${release_info_dir}/disable-qt5"; fi # qbittorrent v5 transition - workflow specific
		exit
	fi
}

_libtorrent_v2_iconv_check() {
	# iconv is only need for libtorrent v1 so we can ignore it for v2
	if [[ ${qbt_libtorrent_version} =~ ^2\. || ${github_tag[libtorrent]} =~ ^(v2\.|RC_2_) ]]; then
		qbt_modules_delete["iconv"]="true"
	else
		qbt_modules_delete["iconv"]="false"
	fi
}
#######################################################################################################################################################
# _print_env
#######################################################################################################################################################
_print_env() {
	printf '\n%b\n\n' " ${unicode_yellow_circle} Default env settings${color_end}"
	[[ $qbt_advanced_view == "yes" ]] && printf '%b\n' " ${color_yellow_light}  qbt_zlib_type=\"${color_green_light}${qbt_zlib_type}${color_yellow_light}\"${color_end}"
	[[ $qbt_advanced_view == "yes" ]] && printf '%b\n' " ${color_yellow_light}  qbt_skip_icu=\"${color_green_light}${qbt_skip_icu}${color_yellow_light}\"${color_end}"
	[[ $qbt_advanced_view == "yes" ]] && printf '%b\n' " ${color_yellow_light}  qbt_boost_tag=\"${color_green_light}${github_tag[boost]}${color_yellow_light}\"${color_end}"
	printf '%b\n' " ${color_yellow_light}  qbt_libtorrent_version=\"${color_green_light}${qbt_libtorrent_version}${color_yellow_light}\"${color_end}"
	[[ $qbt_advanced_view == "yes" ]] && printf '%b\n' " ${color_yellow_light}  qbt_libtorrent_tag=\"${color_green_light}${github_tag[libtorrent]}${color_yellow_light}\"${color_end}"
	[[ $qbt_advanced_view == "yes" ]] && printf '%b\n' " ${color_yellow_light}  qbt_libtorrent_master_jamfile=\"${color_green_light}${qbt_libtorrent_master_jamfile}${color_yellow_light}\"${color_end}"
	[[ $qbt_advanced_view == "yes" ]] && printf '%b\n' " ${color_yellow_light}  qbt_qt_version=\"${color_green_light}${qbt_qt_version}${color_yellow_light}\"${color_end}"
	[[ $qbt_advanced_view == "yes" ]] && printf '%b\n' " ${color_yellow_light}  qbt_qt_tag=\"${color_green_light}${github_tag[qtbase]}${color_yellow_light}\"${color_end}"
	printf '%b\n' " ${color_yellow_light}  qbt_qbittorrent_tag=\"${color_green_light}${github_tag[qbittorrent]}${color_yellow_light}\"${color_end}"
	[[ $qbt_advanced_view == "yes" ]] && printf '%b\n' " ${color_yellow_light}  qbt_build_dir=\"${color_green_light}${qbt_build_dir}${color_yellow_light}\"${color_end}"
	[[ $qbt_advanced_view == "yes" ]] && printf '%b\n' " ${color_yellow_light}  qbt_build_tool=\"${color_green_light}${qbt_build_tool}${color_yellow_light}\"${color_end}"
	printf '%b\n' " ${color_yellow_light}  qbt_cross_name=\"${color_green_light}${qbt_cross_name}${color_yellow_light}\"${color_end}"
	[[ $qbt_advanced_view == "yes" ]] && printf '%b\n' " ${color_yellow_light}  qbt_mcm_url=\"${color_green_light}${qbt_mcm_url}${color_yellow_light}\"${color_end}"
	[[ $qbt_advanced_view == "yes" ]] && printf '%b\n' " ${color_yellow_light}  qbt_patches_url=\"${color_green_light}${qbt_patches_url}${color_yellow_light}\"${color_end}"
	[[ $qbt_advanced_view == "yes" ]] && printf '%b\n' " ${color_yellow_light}  qbt_workflow_files=\"${color_green_light}${qbt_workflow_files}${color_yellow_light}\"${color_end}"
	[[ $qbt_advanced_view == "yes" ]] && printf '%b\n' " ${color_yellow_light}  qbt_cache_dir=\"${color_green_light}${qbt_cache_dir}${color_yellow_light}\"${color_end}"
	[[ $qbt_advanced_view == "yes" ]] && printf '%b\n' " ${color_yellow_light}  qbt_optimise_strip=\"${color_green_light}${qbt_optimise_strip}${color_yellow_light}\"${color_end}"
	[[ $qbt_advanced_view == "yes" ]] && printf '%b\n' " ${color_yellow_light}  qbt_build_debug=\"${color_green_light}${qbt_build_debug}${color_yellow_light}\"${color_end}"
	[[ $qbt_advanced_view == "yes" ]] && printf '%b\n' " ${color_yellow_light}  qbt_standard=\"${color_green_light}${qbt_standard}${color_yellow_light}\"${color_end}"
	[[ $qbt_advanced_view == "yes" ]] && printf '%b\n' " ${color_yellow_light}  qbt_static_ish=\"${color_green_light}${qbt_static_ish}${color_yellow_light}\"${color_end}"
	[[ $qbt_advanced_view == "yes" ]] && printf '%b\n' " ${color_yellow_light}  qbt_optimise=\"${color_green_light}${qbt_optimise}${color_yellow_light}\"${color_end}"
	[[ $qbt_advanced_view == "yes" ]] && printf '%b\n' " ${color_yellow_light}  qbt_with_qemu=\"${color_green_light}${qbt_with_qemu}${color_yellow_light}\"${color_end}"
	[[ $qbt_advanced_view == "yes" ]] && printf '%b\n' " ${color_yellow_light}  qbt_host_deps=\"${color_green_light}${qbt_host_deps}${color_yellow_light}\"${color_end}"
	[[ $qbt_advanced_view == "yes" ]] && printf '%b\n' " ${color_yellow_light}  qbt_host_deps_repo=\"${color_green_light}${qbt_host_deps_repo}${color_yellow_light}\"${color_end}"
	[[ $qbt_advanced_view == "yes" ]] && printf '%b\n' " ${color_yellow_light}  qbt_legacy_mode=\"${color_green_light}${qbt_legacy_mode}${color_yellow_light}\"${color_end}"
	printf '%b\n' " ${color_yellow_light}  qbt_advanced_view=\"${color_green_light}${qbt_advanced_view}${color_yellow_light}\"${color_end}"
	printf '\n'
}
#######################################################################################################################################################
# This function converts a version string to a number for comparison purposes.
#######################################################################################################################################################
_semantic_version() {
	local test_array
	read -ra test_array < <(printf "%s" "${@//./ }" | sed 's/[^0-9]//g')
	printf "%d%03d%03d%03d" "${test_array[@]}"
}
#######################################################################################################################################################
# Script Version check
#######################################################################################################################################################
_script_version() {
	script_version_remote="$(_curl -sL "${script_url}" | sed -rn 's|^script_version="(.*)"$|\1|p')"

	if [[ "$(_semantic_version "${script_version}")" -lt "$(_semantic_version "${script_version_remote}")" ]]; then
		printf '\n%b\n' " ${text_blink}${unicode_red_circle}${color_end} Script update available! Versions - ${color_yellow_light}local:${color_red_light}${script_version}${color_end} ${color_yellow_light}remote:${color_green_light}${script_version_remote}${color_end}"
		printf '\n%b\n' " ${unicode_green_circle} curl -sLo ${BASH_SOURCE[0]} https://git.io/qbstatic${color_end}"
	elif [[ "$(_semantic_version "${script_version}")" -gt "$(_semantic_version "${script_version_remote}")" ]]; then
		printf '\n%b\n' " ${unicode_green_circle} Script version: ${color_red_light}${script_version}-dev${color_end}"
	else
		printf '\n%b\n' " ${unicode_green_circle} Script version: ${color_green_light}${script_version}${color_end}"
	fi
}
#######################################################################################################################################################
# This function will check for a list of defined dependencies from the qbt_core_deps array. Apps like python3-dev are dynamically set
#######################################################################################################################################################
_check_dependencies() {
	local pkgman=()
	local command_test_tool=()
	local command_install_deps=()
	local command_update_upgrade_os=()
	local install_simulation=()

	_privilege_check() {
		printf '\n%b\n' " ${unicode_blue_light_circle} ${text_bold}Checking: ${color_red_light}available privileges${color_end}"

		if [[ "$(id -un 2> /dev/null)" == 'root' ]]; then
			printf '\n%b\n' " $unicode_green_circle ${color_red_light}root${color_end}"
			qbt_privileges_required["root"]="true"
			command_privilege=()
		else
			printf '\n%b\n' " $unicode_red_circle ${color_red_light}root${color_end}"
		fi

		if sudo -n true &> /dev/null; then
			printf '%b\n' " $unicode_green_circle ${color_red_light}sudo${color_end}"
			qbt_privileges_required["sudo"]="true"
			command_privilege=("sudo")
		else
			printf '%b\n' " $unicode_red_circle ${color_red_light}sudo${color_end}"
		fi

		if [[ $os_id =~ (debian|ubuntu) ]]; then
			pkgman+=("${command_privilege[@]}" "dpkg" "-s")
			command_test_tool+=("${command_privilege[@]}" "dpkg" "-s")
			command_install_deps+=("${command_privilege[@]}" "apt-get" "install" "-y")
			command_update_upgrade_os+=("${command_privilege[@]}" "bash" "-c" "apt-get update && apt-get upgrade -y && apt-get autoremove -y")
			install_simulation+=("${command_privilege[@]}" "apt" "install" "--simulate")
		elif [[ $os_id == "alpine" ]]; then
			pkgman+=("${command_privilege[@]}" "apk" "info" "-e" "--no-cache")
			command_test_tool+=("${command_privilege[@]}" "apk" "info" "-e" "--no-cache")
			command_install_deps+=("${command_privilege[@]}" "apk" "add" "-u" "--no-cache" "--repository=${CDN_URL}")
			command_update_upgrade_os+=("${command_privilege[@]}" "bash" "-c" "apk update --no-cache && apk upgrade --no-cache --repository=${CDN_URL} && apk fix")
			install_simulation+=("${command_privilege[@]}" "apk" "add" "--simulate" "--no-cache")
		fi
	}

	_check_tools_work() {
		local tool="${1}"
		local tool_type="${2}"
		local run_type="${3}"
		_command_test() {
			if [[ $tool_type == "test_tools" ]]; then
				command -v "${tool}"
			elif [[ $tool_type == "build_tools" ]]; then
				"${command_test_tool[@]}" "${tool}"
			fi
		}

		if _command_test &> /dev/null; then
			if [[ ${run_type} != "silent" ]]; then
				printf "%b\n" " $unicode_green_circle ${color_yellow}${1}${color_end}"
			fi
			return 0
		else
			if [[ ${run_type} != "silent" ]]; then
				printf "%b\n" " $unicode_red_circle ${color_yellow}${1}${color_end}"
			fi
			return 1
		fi
	}

	_check_dependency_status() {
		local silent="${1:-}"

		filtered_params=()
		for pparam in "$@"; do
			if [[ $pparam != "silent" ]]; then
				filtered_params+=("$pparam")
			fi
		done && unset pparam

		[[ ${silent} != 'silent' ]] && printf '\n%b\n\n' " ${unicode_blue_light_circle} ${text_bold}Checking: ${color_yellow}test${color_end}"

		while IFS= read -r qbt_tt; do
			if _check_tools_work "${qbt_tt}" "test_tools" "${silent}"; then
				qbt_test_tools["${qbt_tt}"]="true"
				unset "build_tools[${qbt_tt}]"
			fi
		done < <(printf '%s\n' "${!qbt_test_tools[@]}" | sort)

		# remove packages in the qbt_deps_delete arrays from the qbt_core_deps array

		for qbt_dd in "${!qbt_deps_delete[@]}"; do
			unset "qbt_core_deps[${qbt_dd}]"
		done && unset qbt_dd

		# remove test_tools packages in the qbt_test_tools array from the qbt_core_deps array if available via command -v
		for qbt_tt in "${!qbt_test_tools[@]}"; do
			if [[ ${qbt_test_tools[$qbt_tt]} == "true" ]]; then
				unset "qbt_core_deps[$qbt_tt]"
			fi
		done && unset qbt_tt

		[[ ${silent} != 'silent' ]] && printf '\n%b\n\n' " ${unicode_blue_light_circle} ${text_bold}Checking: ${color_magenta}core${color_end}"

		# This checks over the qbt_core_deps array for the OS specified dependencies to see if they are installed
		while IFS= read -r pkg; do

			pkgman() { "${pkgman[@]}" "${pkg}"; }

			if pkgman > /dev/null 2>&1; then
				[[ ${silent} != 'silent' ]] && printf '%b\n' " ${unicode_green_circle} ${color_magenta}${pkg}${color_end}"
				qbt_core_deps["${pkg}"]="true"
			else
				if [[ -n ${pkg} ]]; then
					[[ ${silent} != 'silent' ]] && printf '%b\n' " ${unicode_red_circle} ${color_magenta}${pkg}${color_end}"
					qbt_core_deps_sorted+=("$pkg")
					qbt_core_deps["${pkg}"]="false"
				fi
			fi
		done < <(printf '%s\n' "${!qbt_core_deps[@]}" | sort)
	}

	_privilege_check

	_check_dependency_status "${@}"

	if [[ ${qbt_privileges_required["root"]} == "true" || ${qbt_privileges_required["sudo"]} == "true" ]]; then

		if [[ ${qbt_core_deps[*]} =~ "false" ]]; then
			printf '\n%b\n\n' " $unicode_blue_circle ${color_blue}Info:${color_end} $script_full_path"

			if ! "${install_simulation[@]}" "${!qbt_test_tools[@]}" &> /dev/null; then
				printf '%b\n' " $unicode_blue_circle ${color_blue_light}$script_basename${color_end} ${color_magenta}update${color_end} ------------ update host - package simulation failed"
			fi

			if [[ ${qbt_test_tools[*]} =~ "false" ]]; then
				printf '%b\n' " $unicode_blue_circle ${color_blue_light}$script_basename${color_end} ${color_yellow}install_test${color_end} ------ installs minimum required tools to run tests"
			fi

			printf '%b\n' " $unicode_blue_circle ${color_blue_light}$script_basename${color_end} ${color_magenta}install_core${color_end} ------ installs required build tools to use script"

			if ! "${install_simulation[@]}" "${!qbt_test_tools[@]}" &> /dev/null; then
				printf '%b\n' " $unicode_blue_circle ${color_blue_light}$script_basename${color_end} ${color_green_light}bootstrap_deps${color_end} ---- ${color_magenta}update${color_end} + ${color_yellow}install_test${color_end} + ${color_magenta}install_core${color_end}"
			else
				printf '%b\n' " $unicode_blue_circle ${color_blue_light}$script_basename${color_end} ${color_green_light}bootstrap_deps${color_end} ---- ${color_yellow}install_test${color_end} + ${color_magenta}install_core${color_end}"
			fi
		fi
	else
		printf '\n%b\n\n' " $unicode_red_circle ${color_yellow}Warning${color_end}: No root or sudo privileges detected. Nothing to do"
		printf '%b\n' " $unicode_red_circle ${color_yellow}Warning${color_end}: ${color_magenta}test_tools${color_end} are required to access basic features of the script.${color_end}"
	fi

	if [[ ${qbt_test_tools[*]} =~ "false" ]]; then
		printf '\n%b\n' " $unicode_red_circle ${color_yellow}Warning:${color_end} Missing required ${color_magenta}test_tools${color_end}"
	fi

	if [[ ${qbt_core_deps[*]} =~ "false" ]]; then
		printf '\n%b\n' " $unicode_red_circle ${color_yellow}Warning:${color_end} Missing required components of ${color_magenta}install_core${color_end}"
	fi

	# Check if user is able to install the dependencies, if yes then do so, if no then exit.
	if [[ ${qbt_privileges_required["root"]} == "true" || ${qbt_privileges_required["sudo"]} == "true" ]]; then

		_update_os() {
			printf '\n%b\n\n' " ${unicode_blue_light_circle} ${color_green}Updating${color_end}"
			"${command_update_upgrade_os[@]}"
			# needed to use these functions in the -bs flags
			declare -fx _update_os
		}

		_install_tools() {
			# We don't want to run update every time. Only if the the installation command cannot work without an update being run first
			if ! "${install_simulation[@]}" "${!qbt_test_tools[@]}" &> /dev/null; then _update_os; fi

			if [[ ${1} == "test" ]]; then
				printf '\n%b\n\n' " ${unicode_blue_light_circle}${color_green} Installing test dependencies${color_end}"
			elif [[ ${1} == "core" ]]; then
				printf '\n%b\n\n' " ${unicode_blue_light_circle}${color_green} Installing core dependencies${color_end}"
			fi

			if [[ ${1} == "test" ]]; then
				for qbt_tt in "${!qbt_test_tools[@]}"; do
					if [[ $qbt_tt != "root" && $qbt_tt != "sudo" ]]; then
						"${command_install_deps[@]}" "$qbt_tt"
					fi
				done && unset qbt_tt
			fi

			if [[ ${1} == "core" ]]; then
				"${command_install_deps[@]}" "${qbt_core_deps_sorted[@]}"
			fi
			# needed to use these functions in the -bs flags
			declare -fx _install_tools
		}

		if [[ $* =~ ([[:space:]]|^)(update)([[:space:]]|$) ]]; then
			_update_os
		fi

		if [[ $* =~ ([[:space:]]|^)(install_test)([[:space:]]|$) ]]; then
			_install_tools test
		fi

		if [[ $* =~ ([[:space:]]|^)(install_core)([[:space:]]|$) ]]; then
			_install_tools core
		fi

		# qbt_legacy_mode = qbittorrent-nox-static.sh emulation and will make this script behave like qbittorrent-nox-static.sh where it does not
		# require user interaction to attempt to install dependencies if it has the required privileges
		if [[ ${qbt_legacy_mode} == "yes" && ${qbt_core_deps[*]} =~ "false" ]] || [[ $* =~ ([[:space:]]|^)(bootstrap_deps)([[:space:]]|$) ]]; then
			_update_os
			_install_tools core
		fi

		_check_dependency_status silent "${@}"
	else
		printf '\n%b\n' " ${text_bold}Please request or install the missing core dependencies before using this script${color_end}"
		if [[ ${os_id} =~ ^(alpine)$ ]]; then
			printf '\n%b\n\n' " ${color_red_light}apk add${color_end} ${qbt_core_deps_sorted[*]}"
		elif [[ ${os_id} =~ ^(debian|ubuntu)$ ]]; then
			printf '\n%b\n\n' " ${color_red_light}apt-get install -y${color_end} ${qbt_core_deps_sorted[*]}"
		fi
		exit
	fi

	if [[ ${qbt_test_tools[*]} =~ "false" ]]; then
		printf '\n'
		exit
	fi

	for qbt_mi in "${!qbt_modules_install[@]}"; do
		if [[ ${filtered_params[*]} =~ ([[:space:]]|^)${qbt_mi}([[:space:]]|$) ]]; then
			if [[ ${qbt_core_deps[*]} =~ "false" ]]; then
				printf '\n'
				exit
			fi
		fi
	done && unset qbt_mi

	if [[ ! ${qbt_core_deps[*]} =~ "false" ]]; then
		printf '\n%b\n' " ${unicode_green_circle}${text_bold} Dependencies: All checks passed, continuing to build${color_end}"
	fi

	declare -a qbt_modules_excluded=("debug" "update" "install_test" "install_core" "bootstrap" "bootstrap_deps")
	for arg in "${@}"; do
		if [[ ! ${qbt_modules_excluded[*]} =~ ([[:space:]]|^)(${arg})([[:space:]]|$) ]]; then
			declare -ga filtered_check_dependency_args+=("$arg")
		fi
	done
}
#######################################################################################################################################################
# This is a command test function: _cmd exit 1
#######################################################################################################################################################
_cmd() {
	if ! "${@}"; then
		printf '\n%b\n\n' " The command: ${color_red_light}${*}${color_end} failed"
		exit 1
	fi
}
#######################################################################################################################################################
# This is a command test function to test build commands for failure
#######################################################################################################################################################
# shellcheck disable=SC2317,SC2329
_post_command() {
	outcome=("${PIPESTATUS[@]}")
	[[ -n ${1} ]] && command_type="${1}"
	if [[ ${outcome[*]} =~ [1-9] ]]; then
		printf '\n%b\n' " ${unicode_red_circle}${color_red} Error:${color_end} The ${command_type:-tested} command produced an exit code greater than 0 - Check the logs ${color_end}"
		printf '\n%b\n' " ${unicode_yellow_circle}${color_yellow} Warning:${color_end} Developers can be easily startled or confused by wild issues, if you are seeing this warning and cannot resolve the issue yourself, please open an issue at this repo first:"
		printf '\n%b\n\n' " ${unicode_blue_circle}${color_blue_light} https://github.com/userdocs/qbittorrent-nox-static/issues ${color_end}"
		exit 1
	fi
}
#######################################################################################################################################################
# This function is to test a directory exists before attempting to cd and fail with and exit code if it doesn't.
#######################################################################################################################################################
_pushd() {
	# folder creation handled in _download function
	if ! pushd "$@" &> /dev/null; then
		printf '\n%b\n' "This directory does not exist. There is a problem"
		printf '\n%b\n\n' "${color_red_light}${1}${color_end}"
		exit 1
	fi
}

_popd() {
	if ! popd &> /dev/null; then
		printf '%b\n' "This directory does not exist. There is a problem"
		exit 1
	fi
}
#######################################################################################################################################################
# This function makes sure the log directory and path required exists for tee
#######################################################################################################################################################
_tee() {
	[[ $# -eq 1 && ${1%/*} =~ / ]] && mkdir -p "${1%/*}"
	[[ $# -eq 2 && ${2%/*} =~ / ]] && mkdir -p "${2%/*}"
	command tee "$@"
}
#######################################################################################################################################################
# error functions
#######################################################################################################################################################
_error_tag() {
	[[ ${github_tag[*]} =~ error_tag ]] && {
		printf '\n'
		exit
	}
}
#######################################################################################################################################################
# _curl test download functions - default is no proxy - _curl is a test function and _curl_curl is the command function
#######################################################################################################################################################
_curl_curl() {
	"$(type -P curl)" -sNL4fq --connect-timeout 5 --retry 5 --retry-delay 5 --retry-max-time 25 "${qbt_curl_proxy[@]}" "${@}"
}

_curl() {
	if ! _curl_curl "${@}"; then
		return 1
	fi
}
#######################################################################################################################################################
# git test download functions - default is no proxy - git is a test function and _git_git is the command function
#######################################################################################################################################################
_git_git() {
	"$(type -P git)" "${qbt_git_proxy[@]}" "${@}"
}

_git() {
	if [[ ${2} == '-t' ]]; then
		git_test_cmd=("${1}" "${2}" "${3}")
	else
		[[ ${9} =~ https:// ]] && git_test_cmd=("${9}")   # 9th place in our download folder function for qttools
		[[ ${11} =~ https:// ]] && git_test_cmd=("${11}") # 11th place in our download folder function
	fi

	if ! _curl -fIL "${git_test_cmd[@]}" &> /dev/null; then
		printf '\n%b\n\n' " ${color_yellow}Git test 1: There is an issue with your proxy settings or network connection${color_end}"
		exit
	fi

	status="$(
		_git_git ls-remote -qht --refs --exit-code "${git_test_cmd[@]}" &> /dev/null
		printf "%s" "${?}"
	)"

	if [[ ${2} == '-t' && ${status} -eq '0' ]]; then
		printf '%b\n' "${3}"
	elif [[ ${2} == '-t' && ${status} -ge '1' ]]; then
		printf '%b\n' 'error_tag'
	else
		if ! _git_git "${@}"; then
			printf '\n%b\n\n' " ${color_yellow}Git test 2: There is an issue with your proxy settings or network connection${color_end}"
			exit
		fi
	fi
}

_test_git_ouput() {
	if [[ ${1} == 'error_tag' ]]; then
		printf '\n%b\n' " ${text_blink}${unicode_red_light_circle}${color_end} ${color_yellow}The provided ${2} tag ${color_red}${3}${color_end}${color_yellow} is not valid${color_end}"
	fi
}
#######################################################################################################################################################
# Boost URL test function
#######################################################################################################################################################
_boost_url() {
	local boost_asset_type="release"
	local boost_archiveio_asset="${github_tag[boost]//[-\.]/_}"

	if [[ ${github_tag[boost]} =~ \.beta ]]; then
		boost_asset_type="beta"
		boost_archiveio_asset="${boost_archiveio_asset/_beta/_b}"
	fi

	local boost_url_array=(
		"https://github.com/boostorg/boost/releases/download/${github_tag[boost]}/${github_tag[boost]}-b2-nodocs.tar.xz"
		"https://archives.boost.io/${boost_asset_type}/${github_tag[boost]#boost-}/source/${boost_archiveio_asset}.tar.gz"
	)

	for url in "${boost_url_array[@]}"; do
		if _curl -sfLI "${url}" &> /dev/null; then
			boost_url_status="200"
			source_archive_url[boost]="${url}"
			source_default[boost]="file"
			break
		else
			boost_url_status="403"
			source_default[boost]="folder"
		fi
	done
}
#######################################################################################################################################################
# Debug stuff
#######################################################################################################################################################
_debug() {
	if [[ ${script_debug_urls} == "yes" ]]; then
		printf '\n%b\n\n' " ${unicode_magenta_circle} ${color_yellow_light}github_url${color_end}"
		while IFS= read -r github_url_sorted; do
			for n in "${github_url_sorted[@]}"; do
				printf '%b\n' " ${color_green_light}$n${color_end}: ${color_blue_light}${github_url[$n]}${color_end}"
			done
		done < <(printf '%s\n' "${!github_url[@]}" | sort)

		printf '\n%b\n\n' " ${unicode_magenta_circle} ${color_yellow_light}github_tag${color_end}"
		while IFS= read -r github_tag_sorted; do
			for n in "${github_tag_sorted[@]}"; do
				printf '%b\n' " ${color_green_light}$n${color_end}: ${color_blue_light}${github_tag[$n]}${color_end}"
			done
		done < <(printf '%s\n' "${!github_tag[@]}" | sort)

		printf '\n%b\n\n' " ${unicode_magenta_circle} ${color_yellow_light}app_version${color_end}"
		while IFS= read -r app_version_sorted; do
			for n in "${app_version_sorted[@]}"; do
				printf '%b\n' " ${color_green_light}$n${color_end}: ${color_blue_light}${app_version[$n]}${color_end}"
			done
		done < <(printf '%s\n' "${!app_version[@]}" | sort)

		printf '\n%b\n\n' " ${unicode_magenta_circle} ${color_yellow_light}source_archive_url${color_end}"
		while IFS= read -r source_archive_url_sorted; do
			for n in "${source_archive_url_sorted[@]}"; do
				printf '%b\n' " ${color_green_light}$n${color_end}: ${color_blue_light}${source_archive_url[$n]}${color_end}"
			done
		done < <(printf '%s\n' "${!source_archive_url[@]}" | sort)

		printf '\n%b\n\n' " ${unicode_magenta_circle} ${color_yellow_light}qbt_workflow_archive_url${color_end}"
		while IFS= read -r qbt_workflow_archive_url_sorted; do
			for n in "${qbt_workflow_archive_url_sorted[@]}"; do
				printf '%b\n' " ${color_green_light}$n${color_end}: ${color_blue_light}${qbt_workflow_archive_url[$n]}${color_end}"
			done
		done < <(printf '%s\n' "${!qbt_workflow_archive_url[@]}" | sort)

		printf '\n%b\n\n' " ${unicode_magenta_circle} ${color_yellow_light}source_default${color_end}"
		while IFS= read -r source_default_sorted; do
			for n in "${source_default_sorted[@]}"; do
				printf '%b\n' " ${color_green_light}$n${color_end}: ${color_blue_light}${source_default[$n]}${color_end}"
			done
		done < <(printf '%s\n' "${!source_default[@]}" | sort)

		printf '\n%b\n' " ${unicode_magenta_circle} ${color_yellow_light}Tests${color_end}"
		printf '\n%b\n' " ${color_green_light}boost_url_status:${color_end} ${color_blue_light}${boost_url_status}${color_end}"
		printf '%b\n' " ${color_green_light}test_url_status:${color_end} ${color_blue_light}${test_url_status}${color_end}"

		printf '\n'
		exit
	fi
}
#######################################################################################################################################################
# This function sets some compiler flags globally - b2 settings are set in the ~/user-config.jam  set in the _installation_modules function
#######################################################################################################################################################
# Define common flag sets - hardening is prioritized over performance.
# https://best.openssf.org/Compiler-Hardening-Guides/Compiler-Options-Hardening-Guide-for-C-and-C++.html#tldr-what-compiler-options-should-i-use
_custom_flags() {

	# Dynamic tests to change settings based on the use of qmake,cmake,strip and debug
	if [[ ${qbt_build_debug} == "yes" ]]; then
		# Debug builds always get priority
		qbt_strip_qmake='-nostrip'
		qbt_strip_flags='-g'
		qbt_optimise_gcc="-Og -g" # https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html#index-Og
		qbt_optimise_linker="-Wl,-O0"
	elif [[ ${qbt_optimise_strip} == "yes" ]]; then
		# Only strip if not debugging
		qbt_strip_qmake='strip'
		qbt_strip_flags='-s'
		qbt_optimise_gcc="-O3"
		qbt_optimise_linker="-Wl,-O1"
	else
		# defaults if both are set to no
		qbt_strip_qmake='-nostrip'
		qbt_strip_flags=''
		qbt_optimise_gcc="-Og -g" # https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html#index-Og
		qbt_optimise_linker="-Wl,-O0"
	fi

	# Compiler optimization flags (for CFLAGS/CXXFLAGS)
	qbt_optimization_flags="${qbt_optimise_gcc} -pipe -fdata-sections -ffunction-sections -fPIC"
	# Preprocessor only flags - _FORTIFY_SOURCE=3 has been in the GNU C Library (glibc) since version 2.34
	qbt_preprocessor_flags="-U_FORTIFY_SOURCE -D_GLIBCXX_ASSERTIONS"

	# If Alpine add it since it does not break anything.
	if [[ ${os_id} =~ ^(alpine)$ ]]; then
		qbt_preprocessor_flags+=" -D_FORTIFY_SOURCE=3"
	fi

	# Glibc 2.41 changed -D_FORTIFY_SOURCE to be internal. Having it breaks the build.
	if [[ ${os_id} =~ ^(debian|ubuntu)$ ]]; then
		# if os is debian based then check glibc version is less than 241 to add the flag
		if ((${app_version[glibc]/\./} < 241)); then
			qbt_preprocessor_flags+=" -D_FORTIFY_SOURCE=3"
		fi
	fi

	# Security flags for compiler
	qbt_security_flags="-fstack-clash-protection -fstack-protector-strong -fno-plt -fno-delete-null-pointer-checks -fno-strict-overflow -fno-strict-aliasing -ftrivial-auto-var-init=zero -fexceptions"
	# Warning control
	qbt_warning_flags="-w"
	# Linker specific flags
	qbt_linker_flags="${qbt_optimise_linker},--as-needed,--sort-common,-z,nodlopen,-z,noexecstack,-z,now,-z,relro,-z,--no-copy-dt-needed-entries,--build-id"

	#######################################################################################################################################################
	# GCC and CHOST info start
	#######################################################################################################################################################

	if [[ -n ${qbt_cross_host} ]]; then
		# If a valid multiarch target is set qbt_cross_host will not be null and will provide the correct triple for the host platform alpine/debian via the _multi_arch function
		gcc_command=("${qbt_cross_host}-gcc")
	else
		# else just use the one in the path. Which will also work for native hosts and qbt-mcm docker images.
		gcc_command=("gcc")
	fi

	if "${gcc_command[@]}" -dumpspecs &> /dev/null; then
		gcc_version="$("${gcc_command[@]}" -dumpversion | cut -d. -f1)"
	fi

	# Defaults - if no qbt_cross_host use defaults in path
	export CHOST=""
	export CC="gcc"
	export AR="ar"
	export CXX="g++"

	# Defaults - if qbt_cross_host is set then use qbt_cross_host
	if [[ -n ${qbt_cross_host} ]]; then
		export CHOST="${qbt_cross_host}"
		export CC="${qbt_cross_host}-gcc"
		export AR="${qbt_cross_host}-ar"
		export CXX="${qbt_cross_host}-g++"
	fi

	# If cross compiling (qbt_cross_host is set) without qemu make sure the _host_deps modules use host gcc to build native build deps for icu/qtbase cross building
	if [[ ${app_name} =~ "_host_deps" ]]; then
		export CHOST=""
		export CC="/usr/bin/gcc"
		export AR="/usr/bin/ar"
		export CXX="/usr/bin/g++"
	fi

	#######################################################################################################################################################
	# GCC and CHOST info end
	#######################################################################################################################################################

	if [[ ${gcc_version} -ge 13 ]]; then
		qbt_security_flags+=" -fstrict-flex-arrays=3"
	fi

	if [[ ${os_arch} =~ ^(amd64|x86_64)$ && ${qbt_cross_name} == "default" ]]; then
		qbt_security_flags+=" -fcf-protection=full"
	fi

	if [[ ${os_arch} =~ ^(arm64|aarch64)$ && ${qbt_cross_name} == "default" ]]; then
		qbt_security_flags+=" -mbranch-protection=standard"
	fi

	if [[ ${os_id} =~ ^(alpine)$ ]] && [[ -z ${qbt_cross_name} || ${qbt_cross_name} == "default" ]]; then
		if [[ ! ${app_name} =~ ^(openssl)$ ]]; then
			qbt_optimization_flags+=" -flto=auto -fno-fat-lto-objects"
			qbt_linker_flags+=" -Wl,-flto -fuse-linker-plugin"
		fi
	fi

	# include headers
	if [[ ${os_id} =~ ^(alpine)$ ]]; then
		qbt_include_headers="-I/usr/include/fortify -I${include_dir}"
	else
		qbt_include_headers="-I${include_dir}"
	fi

	# if qbt_optimise=yes then set -march=native for non cross builds - see --o | --optimise
	if [[ $qbt_optimise == "yes" ]]; then
		qbt_optimise_march="-march=native"
	fi

	# Dynamic tests to change settings based on the use of qmake,cmake,strip and debug
	if [[ ${qbt_optimise_strip} == "yes" && ${qbt_build_debug} == "no" ]]; then
		qbt_strip_qmake='strip'
		qbt_strip_flags='-s'
	else
		qbt_strip_qmake='-nostrip'
		qbt_strip_flags='-g'
	fi

	# Static linking specific
	if [[ ${qbt_static_ish} == "yes" ]]; then
		qbt_static_flags=""
	else
		qbt_static_flags="-static --static"
	fi

	# If you set and export your own flags in the env that the script is run, they will be appended to the defaults
	# This is done via these checks and the flags are set in the _custom_flags_set function and it avoids duplication
	[[ -z ${qbt_cflags_consumed} ]] && qbt_cflags="${CFLAGS}" qbt_cflags_consumed="yes"
	[[ -z ${qbt_cxxflags_consumed} ]] && qbt_cxxflags="${CXXFLAGS}" qbt_cxxflags_consumed="yes"
	[[ -z ${qbt_cppflags_consumed} ]] && qbt_cppflags="${CPPFLAGS}" qbt_cppflags_consumed="yes"
	[[ -z ${qbt_ldflags_consumed} ]] && qbt_ldflags="${LDFLAGS}" qbt_ldflags_consumed="yes"

	_custom_flags_set() {
		CFLAGS="${qbt_include_headers} ${qbt_optimization_flags} ${qbt_security_flags} -pthread ${qbt_static_flags} ${qbt_optimise_march} ${qbt_cflags:-}"
		CXXFLAGS="${qbt_include_headers} ${qbt_optimization_flags} ${qbt_security_flags} ${qbt_warning_flags} -std=${qbt_cxx_standard} -pthread ${qbt_static_flags} ${qbt_optimise_march} ${qbt_cxxflags:-}"
		CPPFLAGS="${qbt_include_headers} ${qbt_preprocessor_flags} ${qbt_warning_flags} ${qbt_cppflags:-}"

		# Only set linker flags for final executables, not for libraries
		if [[ ${app_name} =~ ^(icu|boost|qtbase|qbittorrent)$ ]]; then
			LDFLAGS="-L${lib_dir} ${qbt_strip_flags} -pthread ${qbt_optimise_march} ${qbt_static_flags} ${qbt_linker_flags} ${qbt_ldflags:-}"
		else
			LDFLAGS="-L${lib_dir} ${qbt_strip_flags} -pthread ${qbt_optimise_march} ${qbt_ldflags:-}"
		fi
	}

	_custom_flags_reset() {
		CFLAGS="${qbt_optimization_flags} ${qbt_security_flags} ${qbt_optimise_march} ${qbt_cflags:-}"
		CXXFLAGS="${qbt_optimization_flags} ${qbt_security_flags} ${qbt_warning_flags} -std=${qbt_cxx_standard} ${qbt_optimise_march} ${qbt_cxxflags:-}"
		CPPFLAGS="${qbt_preprocessor_flags} ${qbt_warning_flags} ${qbt_cppflags:-}"
	}

	if [[ ${app_name} =~ ^(glibc)$ ]]; then
		_custom_flags_reset
	else
		_custom_flags_set
	fi

	if [[ ${qbt_build_tool} == "qmake" && ${app_name} =~ ^(boost)$ ]]; then
		if [[ ${qbt_cross_name} == "default" ]]; then
			printf '%s\n' "using gcc : : g++ : <cflags>\"${CFLAGS}\" <cxxflags>\"${CXXFLAGS}\" <linkflags>\"${LDFLAGS}\" ;" > "${HOME}/user-config.jam"
			printf '%s\n' "using python : ${python_short_version} : /usr/bin/python${python_short_version} : /usr/include/python${python_short_version} : /usr/lib/python${python_short_version} ;" >> "${HOME}/user-config.jam"
		else
			printf '%s\n' "using gcc : ${qbt_cross_boost#gcc-} : ${qbt_cross_host}-g++ : <cflags>\"${CFLAGS}\" <cxxflags>\"${CXXFLAGS}\" <linkflags>\"${LDFLAGS}\" ;" > "${HOME}/user-config.jam"
			printf '%s\n' "using python : ${python_short_version} : /usr/bin/python${python_short_version} : /usr/include/python${python_short_version} : /usr/lib/python${python_short_version} ;" >> "${HOME}/user-config.jam"
		fi
	fi
}
#######################################################################################################################################################
# This function installs a completed static build of qbittorrent-nox to the /usr/local/bin for root or ${HOME}/bin for non root
#######################################################################################################################################################
_install_qbittorrent() {
	if [[ -f "${qbt_install_dir}/completed/qbittorrent-nox" ]]; then
		case "$2" in
			root)
				method="${2}"
				mkdir_command=("${command_privilege[@]}" "mkdir" "-p" "/usr/local/bin")
				install_command=("${command_privilege[@]}" "cp" "-rf" "${qbt_install_dir}/completed/qbittorrent-nox" "/usr/local/bin")
				chmod_command=("${command_privilege[@]}" "chmod" "+x" "-R" "/usr/local/bin/qbittorrent-nox")
				chown_command=()
				;;
			custom)
				method="${2}"
				if [[ -z ${3} ]]; then
					printf '\n%b\n\n' " ${unicode_red_circle} Provide a path as the third arugment${color_end}"
					exit 1
				fi

				mkdir_command=("${command_privilege[@]}" "mkdir" "-p" "${3}")
				install_command=("${command_privilege[@]}" "cp" "-rf" "${qbt_install_dir}/completed/qbittorrent-nox" "${3}")
				chmod_command=("${command_privilege[@]}" "chmod" "+x" "-R" "${3}/qbittorrent-nox")

				# Check if path is relative or within user's home directory
				# if yes then chown file as the local user nor sudo or root
				if [[ ! ${3} =~ ^/ ]] || [[ ${3} =~ ^"${LOCAL_USER_HOME}" ]]; then
					chown_command=("${command_privilege[@]}" "chown" "$(id -nu):$(id -ng)" "-R" "${3}")
				fi
				;;
			*)
				method="local"
				mkdir_command=("mkdir" "-p" "${LOCAL_USER_HOME}/bin")
				install_command=("cp" "-rf" "${qbt_install_dir}/completed/qbittorrent-nox" "${LOCAL_USER_HOME}/bin")
				chmod_command=("chmod" "+x" "-R" "${LOCAL_USER_HOME}/bin/qbittorrent-nox")
				chown_command=()
				;;
		esac

		"${mkdir_command[@]}" || exit 1
		"${install_command[@]}" || exit 1
		"${chmod_command[@]}" || exit 1

		# Only run chown when it has been set (avoids syntax error when empty)
		if ((${#chown_command[@]})); then
			"${chown_command[@]}" || exit 1
		fi

		printf '\n%b\n' " ${unicode_blue_light_circle} qbittorrent-nox has been installed!${color_end}"

		printf '\n%b\n' " ${unicode_yellow_light_circle} Installed using method: ${color_cyan}${method}${color_end}"
		printf '\n%b\n' " ${unicode_yellow_light_circle} Installed using command: ${color_cyan}${install_command[*]}${color_end}"

		printf '\n%b\n' " Run it using this command:"

		# Determine the local user's PATH for checking (prefer preserved paths if available)
		local_path="${qbt_local_paths:-$PATH}"

		# Determine the install dir based on method
		case "${method}" in
			local)
				install_dir="${LOCAL_USER_HOME}/bin"
				;;
			custom)
				install_dir="${3}"
				# Expand leading ~ to the local user's home for comparison
				[[ ${install_dir} == "~"* ]] && install_dir="${install_dir/#\~/${LOCAL_USER_HOME}}"
				;;
			root)
				install_dir="/usr/local/bin"
				;;
		esac

		# Normalize (remove trailing slash)
		install_dir="${install_dir%/}"

		# If install_dir is in PATH, we can run by name; otherwise, show the full path
		if [[ ":${local_path}:" == *":${install_dir}:"* ]]; then
			run_cmd="qbittorrent-nox"
		else
			run_cmd="${install_dir}/qbittorrent-nox"
		fi

		printf '\n%b\n\n' " ${color_green}${run_cmd}${color_end}"
		exit
	else
		printf '\n%b\n\n' " ${unicode_red_circle} qbittorrent-nox has not been built to the defined install directory:"
		printf '\n%b\n' "${color_green}${qbt_install_dir_short}/completed${color_end}"
		printf '\n%b\n\n' "Please build it using the script first then install"
		exit
	fi
}
#######################################################################################################################################################
# URL test for normal use and proxy use - make sure we can reach google.com before processing the URL functions
#######################################################################################################################################################
_test_url() {
	test_url_status="$(_curl -o /dev/null --head --write-out '%{http_code}' "https://github.com")"
	if [[ ${test_url_status} -eq "200" ]]; then
		printf '\n%b\n' " ${unicode_green_circle} Test URL = ${color_green}passed${color_end}"
	else
		printf '\n%b\n\n' " ${unicode_red_circle} ${color_yellow}Test URL failed:${color_end} ${color_yellow_light}There could be an issue with your proxy settings or network connection${color_end}"
		exit
	fi
}
#######################################################################################################################################################
# The _qbt_host_deps function will pull in a statically (musl) prebuilt dependency package to allow cross building qt6 without needing qemu.
# It will install a qt6 host platform prebuilt version for native tooling used during the cmake cross build of qt6.
# This mostly solves the issue of using containers in Github workflows where you cannot modify the how image before the container is deployed.
#
# Since the package is synced to the workflow file releases it can also be used to speed up building as it fulfills dependency requirements.
# qbt_host_deps_build: build against these deps to speed up the cross building process. Otherwise
# qbt_host_deps: all modules required for qtbase/qttools so you only need to build boost/libtorrent/qbittorrent
#######################################################################################################################################################
_qbt_host_deps() {
	if [[ ${qbt_host_deps} == "yes" && ${qbt_cross_name} != "default" ]]; then
		if [[ ${os_arch} =~ ^(amd64|x86_64)$ ]]; then
			host_arch="x86_64"
		elif [[ ${os_arch} =~ ^(arm64|aarch64)$ ]]; then
			host_arch="aarch64"
		else
			printf '\n%b\n' " ${unicode_red_circle} Unsupported host architecture for prebuilt dependencies."
			printf '%b\n\n' " ${unicode_red_circle} Only x86_64 or aarch64 hosts supported for cross-building"
			exit 1
		fi

		if [[ ${qbt_host_deps} == "yes" ]]; then
			if [[ ${qbt_skip_icu} == "yes" ]]; then
				qbt_host_deps_url="https://github.com/${qbt_host_deps_repo}/releases/latest/download/${host_arch}-host-deps.tar.xz"
			else
				qbt_host_deps_url="https://github.com/${qbt_host_deps_repo}/releases/latest/download/${host_arch}-icu-host-deps.tar.xz"
			fi
		fi

		source_default["${qbt_host_deps_url##*/}"]="file"
		source_archive_url["${qbt_host_deps_url##*/}"]="${qbt_host_deps_url}"
		qbt_workflow_archive_url["${qbt_host_deps_url##*/}"]="${qbt_host_deps_url}"
		qbt_workflow_override["${qbt_host_deps_url##*/}"]="no"
		source_type="source"
		_download "${qbt_host_deps_url##*/}"
	fi
}
#######################################################################################################################################################
# This function sets the build and installation directory. If the argument -b is used to set a build directory that directory is set and used.
# If nothing is specified or the switch is not used it defaults to the hard-coded path relative to the scripts location - qbittorrent-build
#######################################################################################################################################################
_set_build_directory() {
	if [[ -n ${qbt_build_dir} ]]; then
		if [[ ${qbt_build_dir} =~ ^/ ]]; then
			qbt_install_dir="${qbt_build_dir}"
			qbt_install_dir_short="${qbt_install_dir/${HOME}/\~}"
		else
			qbt_install_dir="${qbt_working_dir}/${qbt_build_dir}"
			qbt_install_dir_short="${qbt_working_dir_short}/${qbt_build_dir}"
		fi
	fi

	# Set lib and include directory paths based on install path.
	include_dir="${qbt_install_dir}/include"
	lib_dir="${qbt_install_dir}/lib"

	# Define some build specific variables
	LOCAL_USER_HOME="${HOME}" # Get the local user's home dir path before we contain HOME to the build dir.
	HOME="${qbt_install_dir}"
	PATH="${qbt_install_dir}/bin${PATH:+:${qbt_local_paths}}"
	PKG_CONFIG_PATH="${lib_dir}/pkgconfig"
}
#######################################################################################################################################################
# This function is where we set your URL and github tag info that we use with other functions.
#######################################################################################################################################################
_set_module_urls() {
	# Update check url for the _script_version function
	script_url="https://raw.githubusercontent.com/userdocs/qbittorrent-nox-static/master/qbt-nox-static.bash"
	##########################################################################################################################################################
	# Configure the github_url associative array for all the applications this script uses and we call them as ${github_url[app_name]}
	##########################################################################################################################################################
	if [[ ${os_id} =~ ^(debian|ubuntu)$ ]]; then
		github_url[glibc]="https://sourceware.org/git/glibc.git"
	fi

	if [[ ${qbt_zlib_type} == "zlib" ]]; then
		github_url[zlib]="https://github.com/madler/zlib.git"
	elif [[ ${qbt_zlib_type} == "zlib-ng" ]]; then
		github_url[zlib]="https://github.com/zlib-ng/zlib-ng.git"
	fi

	github_url[iconv]="https://git.savannah.gnu.org/git/libiconv.git"
	github_url[icu]="https://github.com/unicode-org/icu.git"
	github_url[double_conversion]="https://github.com/google/double-conversion.git"
	github_url[openssl]="https://github.com/openssl/openssl.git"
	github_url[boost]="https://github.com/boostorg/boost.git"
	github_url[libtorrent]="https://github.com/arvidn/libtorrent.git"
	github_url[qtbase]="https://github.com/qt/qtbase.git"
	github_url[qttools]="https://github.com/qt/qttools.git"
	github_url[qbittorrent]="https://github.com/qbittorrent/qBittorrent.git"
	##########################################################################################################################################################
	# Configure the github_tag associative array for all the applications this script uses and we call them as ${github_tag[app_name]}
	##########################################################################################################################################################
	if [[ ${os_id} =~ ^(debian|ubuntu)$ ]]; then
		github_tag[glibc]="$(_git_git ls-remote -q -t --refs "${github_url[glibc]}" | awk '/glibc-/{sub("refs/tags/", "");sub("(.*)(cvs|fedora)(.*)", ""); if($2 ~ /^glibc-[0-9]+\.[0-9]+$/) print $2 }' | awk '!/^$/' | sort -rV | head -n1)"
	fi
	github_tag[zlib]="develop" # same for zlib and zlib-ng
	#github_tag[iconv]="$(_git_git ls-remote -q -t --refs "${github_url[iconv]}" | awk '{sub("refs/tags/", "");sub("(.*)(-[^0-9].*)(.*)", ""); print $2 }' | awk '!/^$/' | sort -rV | head -n 1)"
	github_tag[iconv]="v$(_curl "https://github.com/userdocs/qbt-workflow-files/releases/latest/download/dependency-version.json" | sed -rn 's|(.*)"iconv": "(.*)",|\2|p')"
	github_tag[icu]="$(_git_git ls-remote -q -t --refs "${github_url[icu]}" | awk '/\/release-/{sub("refs/tags/", "");sub("(.*)(-[^0-9].*)(.*)", ""); print $2 }' | awk '!/^$/' | sort -rV | head -n 1)"
	github_tag[double_conversion]="$(_git_git ls-remote -q -t --refs "${github_url[double_conversion]}" | awk '/v/{sub("refs/tags/", "");sub("(.*)(v6|rc|alpha|beta)(.*)", ""); print $2 }' | awk '!/^$/' | sort -rV | head -n 1)"
	github_tag[openssl]="$(_git_git ls-remote -q -t --refs "${github_url[openssl]}" | awk '/openssl/{sub("refs/tags/", "");sub("(.*)(v6|rc|alpha|beta)(.*)", ""); print $2 }' | awk '!/^$/' | sort -rV | head -n1)"
	github_tag[boost]=$(_git_git ls-remote -q -t --refs "${github_url[boost]}" | awk '{sub("refs/tags/", "");sub("(.*)(rc|alpha|beta|-bgl)(.*)", ""); print $2 }' | awk '!/^$/' | sort -rV | head -n 1)
	github_tag[libtorrent]="$(_git_git ls-remote -q -t --refs "${github_url[libtorrent]}" | awk '/'"v${qbt_libtorrent_version}"'/{sub("refs/tags/", "");sub("(.*)(-[^0-9].*)(.*)", ""); print $2 }' | awk '!/^$/' | sort -rV | head -n 1)"
	github_tag[qtbase]="$(_git_git ls-remote -q -t --refs "${github_url[qtbase]}" | awk '/'"v${qbt_qt_version}"'/{sub("refs/tags/", "");sub("(.*)(-a|-b|-r)", ""); print $2 }' | awk '!/^$/' | sort -rV | head -n 1)"
	github_tag[qttools]="$(_git_git ls-remote -q -t --refs "${github_url[qttools]}" | awk '/'"v${qbt_qt_version}"'/{sub("refs/tags/", "");sub("(.*)(-a|-b|-r)", ""); print $2 }' | awk '!/^$/' | sort -rV | head -n 1)"
	github_tag[qbittorrent]="$(_git_git ls-remote -q -t --refs "${github_url[qbittorrent]}" | awk '{sub("refs/tags/", "");sub("(.*)(-[^0-9].*|rc|alpha|beta)(.*)", ""); print $2 }' | awk '!/^$/' | sort -rV | head -n 1)"
	##########################################################################################################################################################
	# Configure the app_version associative array for all the applications this script uses and we call them as ${app_version[app_name]}
	##########################################################################################################################################################
	if [[ ${os_id} =~ ^(debian|ubuntu)$ ]]; then
		app_version[glibc]="${github_tag[glibc]#glibc-}"
	fi

	if [[ ${qbt_zlib_type} == "zlib" ]]; then
		app_version[zlib]="$(_curl "https://raw.githubusercontent.com/madler/zlib/${github_tag[zlib]}/zlib.h" | sed -rn 's|#define ZLIB_VERSION "(.*)"|\1|p' | sed 's/-.*//g')"
	elif [[ ${qbt_zlib_type} == "zlib-ng" ]]; then
		app_version[zlib]="$(_curl "https://raw.githubusercontent.com/zlib-ng/zlib-ng/${github_tag[zlib]}/zlib.h.in" | sed -rn 's|#define ZLIB_VERSION "(.*)"|\1|p' | sed 's/\.zlib-ng//g')"
	fi

	app_version[iconv]="${github_tag[iconv]#v}"
	app_version[icu]="${github_tag[icu]#release-}"
	app_version[double_conversion]="${github_tag[double_conversion]#v}"
	app_version[openssl]="${github_tag[openssl]#openssl-}"
	app_version[boost]="${github_tag[boost]#boost-}"
	app_version[libtorrent]="${github_tag[libtorrent]#v}"
	app_version[qtbase]="$(printf '%s' "${github_tag[qtbase]#v}" | sed 's/-lts-lgpl//g')"
	app_version[qttools]="$(printf '%s' "${github_tag[qttools]#v}" | sed 's/-lts-lgpl//g')"
	app_version[qbittorrent]="${github_tag[qbittorrent]#release-}"
	##########################################################################################################################################################
	# Configure the source_archive_url associative array for all the applications this script uses and we call them as ${source_archive_url[app_name]}
	##########################################################################################################################################################
	if [[ ${os_id} =~ ^(debian|ubuntu)$ ]]; then
		source_archive_url[glibc]="https://ftpmirror.gnu.org/gnu/libc/${github_tag[glibc]}.tar.xz"
	fi

	if [[ ${qbt_zlib_type} == "zlib" ]]; then
		source_archive_url[zlib]="https://github.com/madler/zlib/archive/refs/heads/develop.tar.gz"
	elif [[ ${qbt_zlib_type} == "zlib-ng" ]]; then
		source_archive_url[zlib]="https://github.com/zlib-ng/zlib-ng/archive/refs/heads/develop.tar.gz"
	fi

	source_archive_url[iconv]="https://ftpmirror.gnu.org/gnu/libiconv/$(grep -Eo 'libiconv-([0-9]{1,3}[.]?)([0-9]{1,3}[.]?)([0-9]{1,3}?)\.tar.gz' <(_curl https://ftpmirror.gnu.org/gnu/libiconv/) | sort -V | tail -1)"
	source_archive_url[icu]="https://github.com/unicode-org/icu/releases/download/${github_tag[icu]}/icu4c-${app_version[icu]/-/_}-src.tgz"
	source_archive_url[double_conversion]="https://github.com/google/double-conversion/archive/refs/tags/${github_tag[double_conversion]}.tar.gz"
	source_archive_url[openssl]="https://github.com/openssl/openssl/releases/download/${github_tag[openssl]}/${github_tag[openssl]}.tar.gz"
	_boost_url # function to test and set the boost url and more
	source_archive_url[libtorrent]="https://github.com/arvidn/libtorrent/releases/download/${github_tag[libtorrent]}/libtorrent-rasterbar-${github_tag[libtorrent]#v}.tar.gz"

	read -ra qt_version_short_array <<< "${app_version[qtbase]//\./ }"
	qt_version_short="${qt_version_short_array[0]}.${qt_version_short_array[1]}"

	if [[ ${qbt_qt_version} =~ ^6 ]]; then
		source_archive_url[qtbase]="https://download.qt.io/official_releases/qt/${qt_version_short}/${app_version[qtbase]}/submodules/qtbase-everywhere-src-${app_version[qtbase]}.tar.xz"
		source_archive_url[qttools]="https://download.qt.io/official_releases/qt/${qt_version_short}/${app_version[qttools]}/submodules/qttools-everywhere-src-${app_version[qttools]}.tar.xz"
	else
		source_archive_url[qtbase]="https://download.qt.io/official_releases/qt/${qt_version_short}/${app_version[qtbase]}/submodules/qtbase-everywhere-opensource-src-${app_version[qtbase]}.tar.xz"
		source_archive_url[qttools]="https://download.qt.io/official_releases/qt/${qt_version_short}/${app_version[qttools]}/submodules/qttools-everywhere-opensource-src-${app_version[qttools]}.tar.xz"
	fi

	source_archive_url[qbittorrent]="https://github.com/qbittorrent/qBittorrent/archive/refs/tags/${github_tag[qbittorrent]}.tar.gz"
	##########################################################################################################################################################
	# Configure the qbt_workflow_archive_url associative array for all the applications this script uses and we call them as ${qbt_workflow_archive_url[app_name]}
	##########################################################################################################################################################
	if [[ ${os_id} =~ ^(debian|ubuntu)$ ]]; then
		qbt_workflow_archive_url[glibc]="https://github.com/userdocs/qbt-workflow-files/releases/latest/download/glibc.${github_tag[glibc]#glibc-}.tar.xz"
	fi

	if [[ ${qbt_zlib_type} == "zlib" ]]; then
		qbt_workflow_archive_url[zlib]="https://github.com/userdocs/qbt-workflow-files/releases/latest/download/zlib.tar.xz"
	elif [[ ${qbt_zlib_type} == "zlib-ng" ]]; then
		qbt_workflow_archive_url[zlib]="https://github.com/userdocs/qbt-workflow-files/releases/latest/download/zlib-ng.tar.xz"
	fi

	qbt_workflow_archive_url[iconv]="https://github.com/userdocs/qbt-workflow-files/releases/latest/download/iconv.tar.xz"
	qbt_workflow_archive_url[icu]="https://github.com/userdocs/qbt-workflow-files/releases/latest/download/icu.tar.xz"
	qbt_workflow_archive_url[double_conversion]="https://github.com/userdocs/qbt-workflow-files/releases/latest/download/double_conversion.tar.xz"
	qbt_workflow_archive_url[openssl]="https://github.com/userdocs/qbt-workflow-files/releases/latest/download/openssl.tar.xz"
	qbt_workflow_archive_url[boost]="https://github.com/userdocs/qbt-workflow-files/releases/latest/download/boost.tar.xz"
	qbt_workflow_archive_url[libtorrent]="https://github.com/userdocs/qbt-workflow-files/releases/latest/download/libtorrent.${github_tag[libtorrent]/v/}.tar.xz"
	qbt_workflow_archive_url[qtbase]="https://github.com/userdocs/qbt-workflow-files/releases/latest/download/qt${qbt_qt_version:0:1}base.tar.xz"
	qbt_workflow_archive_url[qttools]="https://github.com/userdocs/qbt-workflow-files/releases/latest/download/qt${qbt_qt_version:0:1}tools.tar.xz"
	qbt_workflow_archive_url[qbittorrent]="https://github.com/userdocs/qbt-workflow-files/releases/latest/download/qbittorrent.tar.xz"
	##########################################################################################################################################################
	# Configure workflow override options
	##########################################################################################################################################################
	if [[ ${os_id} =~ ^(debian|ubuntu)$ ]]; then
		qbt_workflow_override[glibc]="no"
	fi
	qbt_workflow_override[zlib]="no"
	qbt_workflow_override[iconv]="no"
	qbt_workflow_override[icu]="no"
	qbt_workflow_override[double_conversion]="no"
	qbt_workflow_override[openssl]="no"
	qbt_workflow_override[boost]="no"
	qbt_workflow_override[libtorrent]="no"
	qbt_workflow_override[qtbase]="no"
	qbt_workflow_override[qttools]="no"
	qbt_workflow_override[qbittorrent]="no"
	##########################################################################################################################################################
	# Configure the default source type we use for the download function
	##########################################################################################################################################################
	if [[ ${os_id} =~ ^(debian|ubuntu)$ ]]; then
		source_default[glibc]="file"
	fi
	source_default[zlib]="file"
	source_default[iconv]="file"
	source_default[icu]="file"
	source_default[double_conversion]="file"
	source_default[openssl]="file"
	source_default[boost]="file"
	source_default[libtorrent]="file"
	source_default[qtbase]="file"
	source_default[qttools]="file"
	source_default[qbittorrent]="file"
	##########################################################################################################################################################
	#
	##########################################################################################################################################################
	return
}
#######################################################################################################################################################
# A function to take the associative array qbt_modules_install and sort it, after being processed, into  a sorted indexed array
#######################################################################################################################################################
_sort_modules() {
	if [[ ${#qbt_modules_install_processed[@]} -eq 0 ]]; then
		for qbt_mo in "${qbt_modules_order[@]}"; do
			if [[ -v qbt_modules_install["$qbt_mo"] ]]; then
				qbt_modules_install_processed+=("$qbt_mo")
			fi
		done && unset qbt_mo
	fi
}
#######################################################################################################################################################
# This function verifies the module names from the array qbt_modules_install in the default values function.
#######################################################################################################################################################
_installation_modules() {
	# Delete modules - using the qbt_modules_delete array to unset them from the qbt_modules_install array
	for qbt_md in "${!qbt_modules_delete[@]}"; do
		if [[ ${qbt_modules_delete["$qbt_md"]} == "true" ]]; then
			unset "qbt_modules_install[${qbt_md}]"
		fi
	done && unset qbt_md

	# For any modules params passed, test that they exist in the qbt_modules_install array or set qbt_modules_test to fail
	for passed_params in "${@}"; do
		if [[ ! ${!qbt_modules_install[*]} =~ ([[:space:]]|^)(${passed_params})([[:space:]]|$) ]]; then
			qbt_modules_test="fail"
		fi
	done
	unset passed_params

	if [[ ${qbt_modules_test} != 'fail' && ${#} -ne '0' ]]; then
		unset "qbt_modules_install[all]" # Remove all the modules from the qbt_modules_install array before we process it
		_sort_modules                    # Call the sort function to sort the associative array qbt_modules_install into an sorted indexed array so the installation order is correct
		if [[ ${1} != "all" ]]; then
			read -ra qbt_modules_selected_compare <<< "${qbt_modules_install_processed[@]}"
			for selected in "${@}"; do
				qbt_activated_modules["${selected}"]="yes"
			done && unset selected
			qbt_modules_install_processed=("${@}")
		fi

		for modules_skip in "${qbt_modules_install_processed[@]}"; do
			skip_modules["${modules_skip}"]="no"
		done && unset modules_skip

		# Create the directories we need.
		mkdir -p "${qbt_install_dir}/logs"
		mkdir -p "${PKG_CONFIG_PATH}"
		mkdir -p "${qbt_install_dir}/completed"

		# Set some python variables we need.
		python_major="$(python"${qbt_python_version}" -c "import sys; print(sys.version_info[0])")"
		python_minor="$(python"${qbt_python_version}" -c "import sys; print(sys.version_info[1])")"
		python_short_version="${python_major}.${python_minor}"

		# printf the build directory.
		printf '\n%b\n' " ${unicode_yellow_circle}${text_bold} Install Prefix${color_end} : ${color_cyan_light}${qbt_install_dir_short}${color_end}"

		# Some basic help
		printf '\n%b\n' " ${unicode_yellow_circle}${text_bold} Script help${color_end} : ${color_cyan_light}${qbt_working_dir_short}/${script_basename}${color_end} ${color_blue_light}-h${color_end}"
	else
		_sort_modules
	fi
}
#######################################################################################################################################################
# This function will test to see if a Jamfile patch file exists via the variable patches_github_url for the tag used.
#######################################################################################################################################################
_apply_patches() {
	[[ -n ${1} ]] && app_name="${1}"
	# Start to define the default master branch we will use by transforming the app_version[libtorrent] variable to underscores. The result is dynamic and can be: RC_1_0, RC_1_1, RC_1_2, RC_2_0 and so on.
	default_jamfile="${app_version[libtorrent]//./\_}"

	# Remove everything after second underscore. Occasionally the tag will be short, like v2.0 so we need to make sure not remove the underscore if there is only one present.
	if [[ $(grep -o '_' <<< "${default_jamfile}" | wc -l) -le 1 ]]; then
		default_jamfile="RC_${default_jamfile}"
	elif [[ $(grep -o '_' <<< "${default_jamfile}" | wc -l) -ge 2 ]]; then
		default_jamfile="RC_${default_jamfile%_*}"
	fi

	if [[ ${app_name} == "bootstrap" ]]; then
		_sort_modules
		for module_patch in "${qbt_modules_install_processed[@]}"; do
			[[ -n ${app_version["${module_patch}"]} ]] && mkdir -p "${qbt_install_dir}/patches/${module_patch}/${app_version["${module_patch}"]}/source"
		done && unset module_patch

		printf '\n%b\n\n' " ${unicode_yellow_circle} Using the defaults, these directories have been created:${color_end}"

		for patch_info in "${qbt_modules_install_processed[@]}"; do
			[[ -n ${app_version["${patch_info}"]} ]] && printf '%b\n' " ${color_cyan_light} ${qbt_install_dir_short}/patches/${patch_info}/${app_version["${patch_info}"]}${color_end}"
		done && unset patch_info

		printf '\n%b\n' " ${unicode_cyan_circle} If a patch file, named ${color_cyan_light}patch${color_end} is found in these directories it will be applied to the relevant module with a matching tag."
	else
		patch_dir="${qbt_install_dir}/patches/${app_name}/${app_version[${app_name}]}"

		# local
		patch_file="${patch_dir}/patch"
		patch_url_file="${patch_dir}/url" # A file with a url to raw patch info
		# remote
		qbt_patches_url_branch="$(_git_git ls-remote -q --symref "https://github.com/${qbt_patches_url}" HEAD | awk '/^ref:/{sub("refs/heads/", "", $2); print $2}')"
		# qbt_patches_url_branch="$(_curl -sL "https://github.com/${qbt_patches_url}" | sed -n 's/.*"defaultBranch":"\([^"]*\)".*/\1/p')"
		patch_file_remote="https://raw.githubusercontent.com/${qbt_patches_url}/${qbt_patches_url_branch}/patches/${app_name}/${app_version[${app_name}]}"

		if [[ ${app_name} == "libtorrent" ]]; then
			patch_jamfile="${patch_dir}/Jamfile"
			patch_jamfile_url="https://raw.githubusercontent.com/${qbt_patches_url}/${qbt_patches_url_branch}/patches/${app_name}/${app_version[${app_name}]}/Jamfile"
		fi

		# Order of patch file preference
		# 1. Local patch file - A custom patch file in the module version folder matching the build configuration
		# 2. Local url file - A custom url to a raw patch file in the module version folder matching the build configuration
		# 3. Remote patch file using the patch_file_remote/patch - A custom url to a raw patch file
		# 4. Remote url file using patch_file_remote/url - A url to a raw patch file in the patch repo

		[[ ${source_default[${app_name}]} == "folder" && ! -d "${qbt_cache_dir}/${app_name}" ]] && printf '\n' # cosmetics

		_patch_url() {
			patch_url="$(< "${patch_url_file}")"
			if _curl --create-dirs "${patch_url}" -o "${patch_file}"; then
				printf '%b\n\n' " ${unicode_green_circle} ${color_red}Patching${color_end} from ${color_red_light}remote:url${color_end} - ${color_magenta_light}${app_name}${color_end} ${color_yellow_light}${app_version[${app_name}]}${color_end} - ${color_yellow_light}${patch_url}${color_end}"
			fi
		}

		if [[ -f ${patch_file} ]]; then # If the patch file exists in the module version folder matching the build configuration then use this.
			printf '%b\n\n' " ${unicode_green_circle} ${color_red}Patching${color_end} from ${color_red_light}local:patch${color_end} - ${color_magenta_light}${app_name}${color_end} ${color_yellow_light}${app_version[${app_name}]}${color_end} - ${color_cyan_light}${patch_file}${color_end}"
		elif [[ -f ${patch_url_file} ]]; then # If a remote URL file exists in the module version folder matching the build configuration then use this to create the patch file for the next check
			_patch_url
		else # Else check that if there is a remotely host patch file available in the patch repo
			if _curl --create-dirs "${patch_file_remote}/patch" -o "${patch_file}"; then
				printf '%b\n\n' " ${unicode_green_circle} ${color_red}Patching${color_end} from ${color_red_light}remote:patch${color_end} - ${color_magenta_light}${app_name}${color_end} ${color_yellow_light}${app_version[${app_name}]}${color_end} - ${color_yellow_light}${patch_file_remote}/patch${color_end}"
			elif _curl --create-dirs "${patch_file_remote}/url" -o "${patch_url_file}"; then
				_patch_url
			fi
		fi

		# Libtorrent specific stuff
		if [[ ${app_name} == "libtorrent" ]]; then
			if [[ ${qbt_libtorrent_master_jamfile} == "yes" ]]; then
				_curl --create-dirs "https://raw.githubusercontent.com/arvidn/libtorrent/${default_jamfile}/Jamfile" -o "${qbt_dl_folder_path}/${patch_jamfile##*/}"
				printf '\n%b\n\n' " ${unicode_green_circle}${color_red} Using libtorrent branch master Jamfile file${color_end}"
			elif [[ -f "${patch_dir}/Jamfile" ]]; then
				cp -f "${patch_dir}/Jamfile" "${qbt_dl_folder_path}/${patch_jamfile##*/}"
				printf '%b\n\n' " ${unicode_green_circle}${color_red} Using existing custom Jamfile file${color_end}"
			else
				if _curl --create-dirs "${patch_jamfile_url}" -o "${qbt_dl_folder_path}/${patch_jamfile##*/}"; then
					printf '%b\n\n' " ${unicode_green_circle}${color_red} Using downloaded custom Jamfile file${color_end}"
				else
					printf '\n%b\n\n' " ${unicode_green_circle}${color_red} Using libtorrent ${github_tag[libtorrent]} Jamfile file${color_end}"
				fi
			fi
		fi

		# Patch files
		if [[ -f ${patch_file} ]]; then
			patch -p1 < "${patch_file}"
		fi

		# Copy modified files from source directory
		if [[ -d "${patch_dir}/source" && "$(ls -A "${patch_dir}/source")" ]]; then
			printf '%b\n\n' " ${unicode_red_circle} ${color_yellow_light}Copying files from patch source dir${color_end}"
			cp -rf "${patch_dir}/source/". "${qbt_dl_folder_path}/"
		fi
	fi
}
#######################################################################################################################################################
# A unified download function to handle the processing of various options and directions the script can take.
#######################################################################################################################################################
_download() {
	_pushd "${qbt_install_dir}"
	[[ -n ${1} ]] && app_name="${1}"

	if [[ ${app_name} =~ (_host_deps)$ ]]; then
		qbt_restore_host_deps="yes"
		app_name="${app_name/_host_deps/}"
	else
		qbt_restore_host_deps="no"
	fi

	# The location we download source archives and folders to
	qbt_dl_dir="${qbt_install_dir}"
	qbt_dl_file_path="${qbt_dl_dir}/${app_name}.tar.xz"
	qbt_dl_folder_path="${qbt_dl_dir}/${app_name}"

	if [[ ${qbt_workflow_files} == "no" ]] || [[ ${qbt_workflow_override[${app_name}]} == "yes" ]]; then
		qbt_dl_source_url="${source_archive_url[${app_name}]}"
		source_type="source"
	fi

	if [[ ${qbt_workflow_files} == "yes" && ${qbt_workflow_override[${app_name}]} == "no" ]]; then
		qbt_dl_source_url="${qbt_workflow_archive_url[${app_name}]}"
		[[ ${qbt_workflow_files} == "yes" ]] && source_type="workflow"
	fi

	[[ -n ${qbt_cache_dir} ]] && _cache_dirs
	[[ ${source_default[${app_name}]} == "file" ]] && _download_file
	[[ ${source_default[${app_name}]} == "folder" ]] && _download_folder

	return 0
}
#######################################################################################################################################################
#
#######################################################################################################################################################
_cache_dirs() {
	# If the path is not starting with / then make it a full path by prepending the qbt_working_dir path
	if [[ ! ${qbt_cache_dir} =~ ^/ ]]; then
		qbt_cache_dir="${qbt_working_dir}/${qbt_cache_dir}"
	fi

	qbt_dl_dir="${qbt_cache_dir}"
	qbt_dl_file_path="${qbt_dl_dir}/${app_name}.tar.xz"
	qbt_dl_folder_path="${qbt_dl_dir}/${app_name}"

	if [[ ${qbt_workflow_files} == "yes" && ${qbt_workflow_override[${app_name}]} == "no" ]]; then
		source_default["${app_name}"]="file"
	elif [[ ${qbt_cache_dir_options} == "bs" || -d ${qbt_dl_folder_path} ]]; then
		source_default["${app_name}"]="folder"
	fi

	return
}

_cache_dirs_qbt_env_copy() {
	if [[ -n ${qbt_cache_dir} && ! -f "${qbt_cache_dir}/.qbt_env" && -f "${script_parent_path}/.qbt_env" ]] || [[ ${qbt_cache_dir_options} == "bs" ]]; then
		if ! diff -q "${script_parent_path}/.qbt_env" "${qbt_cache_dir}/.qbt_env" &> /dev/null; then
			cp -f "${script_parent_path}/.qbt_env" "${qbt_cache_dir}/"
			[[ ${qbt_cache_dir_options} == "bs" ]] && printf '\n'
			printf '\n%b\n' " ${unicode_green_circle} Copied ${color_cyan_light}.qbt_env${color_end} to cache directory"
			[[ ${qbt_cache_dir_options} == "bs" ]] && printf '' || printf '\n'
		fi
	fi
}

_cache_dirs_qbt_env() {
	_cache_dirs_qbt_env_copy

	if [[ -n ${qbt_cache_dir} && -f "${qbt_cache_dir}/.qbt_env" && -f "${script_parent_path}/.qbt_env" ]]; then
		if ! diff -q "${script_parent_path}/.qbt_env" "${qbt_cache_dir}/.qbt_env" &> /dev/null; then
			# Get SHA256 checksums
			current_sha256=$(sha256sum "${script_parent_path}/.qbt_env" 2> /dev/null | cut -d' ' -f1 || echo "unavailable")
			cached_sha256=$(sha256sum "${qbt_cache_dir}/.qbt_env" 2> /dev/null | cut -d' ' -f1 || echo "unavailable")

			printf '%b\n\n' " ${unicode_yellow_circle} ${color_yellow}Warning:${color_end} Your ${color_cyan_light}.qbt_env${color_end} files are different"
			printf '%b\n' "   ${unicode_blue_light_circle} Current:  ${color_cyan_light}${script_parent_path}/.qbt_env${color_end}"
			printf '%b\n\n' "     ${text_dim}SHA256:   ${current_sha256}${color_end}"
			printf '%b\n' "   ${unicode_blue_light_circle} Cached:   ${color_cyan_light}${qbt_cache_dir}/.qbt_env${color_end} ${text_dim}(represents cached dependency versions)${color_end}"
			printf '%b\n\n' "     ${text_dim}SHA256:   ${cached_sha256}${color_end}"
			printf '%b\n\n' "   ${unicode_yellow_light_circle} The cached version tracks dependency versions for cached source files"
			printf '%b\n' "     When the main .qbt_env changes, cached files may need updating to match new versions"
			printf '\n%b\n' "   ${unicode_blue_light_circle} Run with ${color_blue_light}-cd ${qbt_cache_dir} bs${color_end} to update the cache with current dependency versions"
			printf '\n%b\n\n' "   ${unicode_blue_light_circle} Use ${color_blue_light}diff \"${script_parent_path}/.qbt_env\" \"${qbt_cache_dir}/.qbt_env\"${color_end} to see differences"
			exit 1
		fi
	fi
}
#######################################################################################################################################################
# This function is for downloading git releases based on their tag.
#######################################################################################################################################################
_download_folder() {
	# Set this to avoid some warning when cloning some modules
	_git_git config --global advice.detachedHead false

	# Remove the source files in the build directory if present before we download or copy them again
	[[ -d "${qbt_install_dir}/${app_name}" ]] && rm -rf "${qbt_install_dir}/${app_name:?}"
	[[ -d "${qbt_install_dir}/include/${app_name}" ]] && rm -rf "${qbt_install_dir}/include/${app_name:?}"

	# if there IS NOT and app_name cache directory present in the path provided and we are bootstrapping then use this echo
	if [[ ${qbt_cache_dir_options} == "bs" && ! -d ${qbt_dl_folder_path} ]]; then
		printf '\n%b\n\n' " ${unicode_blue_light_circle} Caching ${color_magenta_light}${app_name}${color_end} with tag ${color_yellow_light}${github_tag[${app_name}]}${color_end} to ${color_cyan_light}${color_cyan_light}${qbt_dl_folder_path}${color_end}${color_end} from ${color_yellow_light}${color_yellow_light}${github_url[${app_name}]}${color_end}"
	fi

	# if cache dir is on and the app_name folder does not exist then get folder via cloning default source
	if [[ ${qbt_cache_dir_options} != "bs" && ! -d ${qbt_dl_folder_path} ]]; then
		printf '\n%b\n\n' " ${unicode_blue_light_circle} Downloading ${color_magenta_light}${app_name}${color_end} with tag ${color_yellow_light}${github_tag[${app_name}]}${color_end} to ${color_cyan_light}${color_cyan_light}${qbt_dl_folder_path}${color_end}${color_end} from ${color_yellow_light}${color_yellow_light}${github_url[${app_name}]}${color_end}"
	fi

	if [[ ! -d ${qbt_dl_folder_path} ]]; then
		if [[ ${app_name} =~ qttools ]]; then
			_git clone --no-tags --single-branch --branch "${github_tag[${app_name}]}" -j"$(nproc)" --depth 1 "${github_url[${app_name}]}" "${qbt_dl_folder_path}"
			_pushd "${qbt_dl_folder_path}"
			git submodule update --force --recursive --init --remote --depth=1 --single-branch
			_popd
		else
			_git clone --no-tags --single-branch --branch "${github_tag[${app_name}]}" --shallow-submodules --recurse-submodules -j"$(nproc)" --depth 1 "${github_url[${app_name}]}" "${qbt_dl_folder_path}"
		fi
	fi

	# if there IS a app_name cache directory present in the path provided and we are bootstrapping then use this
	if [[ ${qbt_cache_dir_options} == "bs" && -d ${qbt_dl_folder_path} ]]; then
		printf '\n%b\n\n' " ${unicode_green_circle} ${color_blue_light}${app_name}${color_end} - Updating directory ${color_cyan_light}${qbt_dl_folder_path}${color_end}"
		_pushd "${qbt_dl_folder_path}"

		if git ls-remote -qh --refs --exit-code "${github_url[${app_name}]}" "${github_tag[${app_name}]}" &> /dev/null; then
			_git_git fetch origin "${github_tag[${app_name}]}:${github_tag[${app_name}]}" --no-tags --depth=1 --recurse-submodules --update-head-ok
		fi

		if git ls-remote -qt --refs --exit-code "${github_url[${app_name}]}" "${github_tag[${app_name}]}" &> /dev/null; then
			_git_git fetch origin tag "${github_tag[${app_name}]}" --no-tags --depth=1 --recurse-submodules --update-head-ok
		fi

		_git_git checkout "${github_tag[${app_name}]}"
		_popd
	fi

	if [[ ${qbt_cache_dir_options} != "bs" && -n ${qbt_cache_dir} && -d ${qbt_dl_folder_path} ]]; then
		printf '\n%b\n\n' " ${unicode_blue_light_circle} Copying ${color_magenta_light}${app_name}${color_end} from cache ${color_cyan_light}${qbt_cache_dir}/${app_name}${color_end} with tag ${color_yellow_light}${github_tag[${app_name}]}${color_end} to ${color_cyan_light}${qbt_install_dir}/${app_name}${color_end}"
		cp -rf "${qbt_dl_folder_path}" "${qbt_install_dir}/"
	fi

	if [[ ${qbt_cache_dir_options} != "bs" ]]; then
		mkdir -p "${qbt_install_dir}/${app_name}${sub_dir}"
		_pushd "${qbt_install_dir}/${app_name}${sub_dir}"
	fi

	_cache_dirs_qbt_env

	printf '%s' "${github_url[${app_name}]}" |& _tee "${qbt_install_dir}/logs/${app_name}_github_url.log" > /dev/null

	if [[ ${qbt_with_qemu} == "no" && ${qbt_restore_host_deps} == "yes" ]]; then
		app_name="${app_name}_host_deps"
	fi

	return
}
#######################################################################################################################################################
# This function is for downloading source code archives
#######################################################################################################################################################
_download_file() {
	if [[ -f ${qbt_dl_file_path} ]]; then
		# This checks that the archive is not corrupt or empty checking for a top level folder and exiting if there is no result i.e. the archive is empty - so that we do rm and empty substitution
		_cmd grep -Eqom1 "(.*)[^/]" <(tar tf "${qbt_dl_file_path}")
		# delete any existing extracted archives and archives
		rm -rf {"${qbt_install_dir:?}/$(tar tf "${qbt_dl_file_path}" | grep -Eom1 "(.*)[^/]")","${qbt_install_dir}/${app_name}.tar.xz"}
		[[ -d "${qbt_install_dir}/${app_name}" ]] && rm -rf "${qbt_install_dir}/${app_name:?}"
		[[ -d "${qbt_install_dir}/include/${app_name}" ]] && rm -rf "${qbt_install_dir}/include/${app_name:?}"
	fi

	if [[ ${qbt_cache_dir_options} != "bs" && ! -f ${qbt_dl_file_path} ]]; then
		printf '\n%b\n\n' " ${unicode_blue_light_circle} Downloading ${color_magenta_light}${app_name}${color_end} using ${color_yellow_light}${source_type}${color_end} files to ${color_cyan_light}${qbt_dl_file_path}${color_end} - ${color_yellow_light}${qbt_dl_source_url}${color_end}"
	elif [[ -n ${qbt_cache_dir} && ${qbt_cache_dir_options} == "bs" && ! -f ${qbt_dl_file_path} ]]; then
		printf '\n%b\n\n' " ${unicode_blue_light_circle} Caching ${color_magenta_light}${app_name}${color_end} ${color_yellow_light}${source_type}${color_end} files to ${color_cyan_light}${qbt_cache_dir}/${app_name}.tar.xz${color_end} - ${color_yellow_light}${qbt_dl_source_url}${color_end}"
	elif [[ -n ${qbt_cache_dir} && ${qbt_cache_dir_options} == "bs" && -f ${qbt_dl_file_path} ]]; then
		[[ ${qbt_cache_dir_options} == "bs" ]] && printf '\n%b\n' " ${unicode_blue_light_circle} Updating ${color_magenta_light}${app_name}${color_end} cached ${color_yellow_light}${source_type}${color_end} files from - ${color_cyan_light}${qbt_cache_dir}/${app_name}.tar.xz${color_end}"
	elif [[ -n ${qbt_cache_dir} && ${qbt_cache_dir_options} != "bs" && -f ${qbt_dl_file_path} ]]; then
		printf '\n%b\n\n' " ${unicode_blue_light_circle} Extracting ${color_magenta_light}${app_name}${color_end} cached ${color_yellow_light}${source_type}${color_end} files from - ${color_cyan_light}${qbt_cache_dir}/${app_name}.tar.xz${color_end}"
	fi

	# download the remote source file using curl
	if [[ ${qbt_cache_dir_options} == "bs" || ! -f ${qbt_dl_file_path} ]]; then
		_curl --create-dirs "${qbt_dl_source_url}" -o "${qbt_dl_file_path}"
	fi

	# Set the extracted dir name to a var to easily use or remove it
	qbt_dl_folder_path="${qbt_install_dir}/$(tar tf "${qbt_dl_file_path}" | head -1 | cut -f1 -d"/")"

	printf '%b\n' "${qbt_dl_source_url}" |& _tee "${qbt_install_dir}/logs/${app_name}_${source_type}_archive_url.log" > /dev/null

	tar_flags=("--strip-components=0")

	tar_additional_cmds+=("-C" "${qbt_install_dir}")

	if [[ ${qbt_cache_dir_options} != "bs" ]]; then
		_cmd tar xf "${qbt_dl_file_path}" "${tar_flags[@]}" "${tar_additional_cmds[@]}"
		# we don't need to cd into the boost if we download it via source archives

		mkdir -p "${qbt_dl_folder_path}${sub_dir}"
		_pushd "${qbt_dl_folder_path}${sub_dir}"
	fi

	_cache_dirs_qbt_env

	unset tar_additional_cmds

	if [[ ${qbt_with_qemu} == "no" && ${qbt_restore_host_deps} == "yes" ]]; then
		app_name="${app_name}_host_deps"
	fi

	return
}
#######################################################################################################################################################
# static lib link fix: check for *.so and *.a versions of a lib in the $lib_dir and change the *.so link to point to the static lib e.g. libdl.a
#######################################################################################################################################################
_fix_static_links() {
	log_name="${app_name}"
	mapfile -t library_list < <(find "${lib_dir}" -maxdepth 1 -type f -name '*.a' -exec basename {} \;)
	for file in "${library_list[@]}"; do
		ln -fsn "${file}" "${lib_dir}/${file%\.a}.so"
		printf '%b\n' "${lib_dir}/${file%\.a}.so changed to point to ${file}" |& _tee -a "${qbt_install_dir}/logs/${log_name}-fix-static-links.log" > /dev/null
	done
	return
}

_fix_multiarch_static_links() {
	if [[ -d "${qbt_install_dir}/${qbt_cross_host}" ]]; then
		log_name="${qbt_cross_host}"
		multiarch_lib_dir="${qbt_install_dir}/${qbt_cross_host}/lib"
		mapfile -t library_list < <(find "${multiarch_lib_dir}" -maxdepth 1 -type f -name '*.a' -exec basename {} \;)
		for file in "${library_list[@]}"; do
			ln -fsn "${file}" "${multiarch_lib_dir}/${file%\.a}.so"
			printf '%b\n' "${multiarch_lib_dir}/${file%\.a}.so changed to point to ${file}" |& _tee -a "${qbt_install_dir}/logs/${log_name}-fix-static-links.log" > /dev/null
		done
		return
	fi
}
#######################################################################################################################################################
# This function is for removing files and folders we no longer need
#######################################################################################################################################################
_delete_function() {
	if [[ ${qbt_skip_delete} != "yes" ]]; then
		printf '\n%b\n' " ${unicode_green_circle}${color_red_light} Deleting ${app_name} uncached installation files and folders${color_end}"
		[[ -f ${qbt_dl_file_path} ]] && rm -rf {"${qbt_install_dir:?}/$(tar tf "${qbt_dl_file_path}" | grep -Eom1 "(.*)[^/]")","${qbt_install_dir}/${app_name}.tar.xz"}
		[[ -d ${qbt_dl_folder_path} ]] && rm -rf "${qbt_install_dir}/${app_name:?}"
		_pushd "${qbt_working_dir}"
	else
		printf '\n%b\n' " ${unicode_yellow_circle}${color_red_light} Skipping ${app_name} deletion${color_end}"
	fi
}
#######################################################################################################################################################
# This function handles the Multi Arch dynamics of the script.
#######################################################################################################################################################
_multi_arch() {
	if [[ ${multi_arch_options[${qbt_cross_name}]} == "${qbt_cross_name}" && ${qbt_cross_name} != "default" ]]; then
		if [[ ${os_id} =~ ^(alpine|debian|ubuntu)$ ]]; then
			if [[ ${1} != "bootstrap" ]]; then
				printf '\n%b\n' " ${unicode_green_circle}${text_bold} Using multiarch:${color_end} ${color_yellow_light}arch:${color_end} ${color_blue_light}${qbt_cross_name}${color_end} ${color_yellow_light}host:${color_end} ${color_blue_light}${os_arch} ${os_id}${color_end} ${color_yellow_light}target:${color_end} ${color_blue_light}${qbt_cross_name} ${qbt_cross_target}${color_end}"
			fi
			case "${qbt_cross_name}" in
				armel)
					case "${qbt_cross_target}" in
						alpine)
							qbt_cross_host="arm-linux-musleabi"
							;;&
						debian | ubuntu)
							qbt_cross_host="arm-linux-gnueabi"
							;;&
						*)
							bitness="32"
							cross_arch="armel"
							qbt_cross_boost="gcc-arm"
							qbt_cross_openssl="linux-armv4"
							qbt_cross_qtbase="linux-arm-gnueabi-g++"
							;;
					esac
					;;
				armhf)
					case "${qbt_cross_target}" in
						alpine)
							cross_arch="armhf"
							qbt_cross_host="arm-linux-musleabihf"
							;;&
						debian | ubuntu)
							cross_arch="armel"
							qbt_cross_host="arm-linux-gnueabihf"
							;;&
						*)
							bitness="32"
							qbt_cross_boost="gcc-arm"
							qbt_cross_openssl="linux-armv4"
							qbt_cross_qtbase="linux-arm-gnueabi-g++"
							;;
					esac
					;;
				armv7)
					case "${qbt_cross_target}" in
						alpine)
							cross_arch="armv7"
							qbt_cross_host="armv7l-linux-musleabihf"
							;;&
						debian | ubuntu)
							cross_arch="armhf"
							qbt_cross_host="arm-linux-gnueabihf"
							;;&
						*)
							bitness="32"
							qbt_cross_boost="gcc-arm"
							qbt_cross_openssl="linux-armv4"
							qbt_cross_qtbase="linux-arm-gnueabi-g++"
							;;
					esac
					;;
				aarch64)
					case "${qbt_cross_target}" in
						alpine)
							cross_arch="aarch64"
							qbt_cross_host="aarch64-linux-musl"
							;;&
						debian | ubuntu)
							cross_arch="arm64"
							qbt_cross_host="aarch64-linux-gnu"
							;;&
						*)
							bitness="64"
							qbt_cross_boost="gcc-arm"
							qbt_cross_openssl="linux-aarch64"
							qbt_cross_qtbase="linux-aarch64-gnu-g++"
							;;
					esac
					;;
				x86_64)
					case "${qbt_cross_target}" in
						alpine)
							cross_arch="x86_64"
							qbt_cross_host="x86_64-linux-musl"
							;;&
						debian | ubuntu)
							cross_arch="amd64"
							qbt_cross_host="x86_64-linux-gnu"
							;;&
						*)
							bitness="64"
							qbt_cross_boost=""
							qbt_cross_openssl="linux-x86_64"
							qbt_cross_qtbase="linux-g++-64"
							;;
					esac
					;;
				x86)
					case "${qbt_cross_target}" in
						alpine)
							cross_arch="x86"
							qbt_cross_host="i686-linux-musl"
							;;&
						debian | ubuntu)
							cross_arch="i386"
							qbt_cross_host="i686-linux-gnu"
							;;&
						*)
							bitness="32"
							qbt_cross_openssl="linux-x86"
							qbt_cross_qtbase="linux-g++-32"
							;;
					esac
					;;
				s390x)
					case "${qbt_cross_target}" in
						alpine)
							qbt_cross_host="s390x-linux-musl"
							;;&
						debian | ubuntu)
							qbt_cross_host="s390x-linux-gnu"
							;;&
						*)
							cross_arch="s390x"
							bitness="64"
							qbt_cross_boost="gcc-s390x"
							qbt_cross_openssl="linux64-s390x"
							qbt_cross_qtbase="linux-g++-64"
							;;
					esac
					;;
				powerpc)
					case "${qbt_cross_target}" in
						alpine)
							qbt_cross_host="powerpc-linux-musl"
							;;&
						debian | ubuntu)
							qbt_cross_host="powerpc-linux-gnu"
							;;&
						*)
							bitness="32"
							cross_arch="powerpc"
							qbt_cross_boost="gcc-ppc"
							qbt_cross_openssl="linux-ppc"
							qbt_cross_qtbase="linux-g++-32"
							;;
					esac
					;;
				ppc64el)
					case "${qbt_cross_target}" in
						alpine)
							qbt_cross_host="powerpc64le-linux-musl"
							;;&
						debian | ubuntu)
							qbt_cross_host="powerpc64le-linux-gnu"
							;;&
						*)
							bitness="64"
							cross_arch="ppc64el"
							qbt_cross_boost="gcc-ppc64el"
							qbt_cross_openssl="linux-ppc64le"
							qbt_cross_qtbase="linux-g++-64"
							;;
					esac
					;;
				mips)
					case "${qbt_cross_target}" in
						alpine)
							qbt_cross_host="mips-linux-musl"
							;;&
						debian | ubuntu)
							qbt_cross_host="mips-linux-gnu"
							;;&
						*)
							bitness="32"
							cross_arch="mips"
							qbt_cross_boost="gcc-mips"
							qbt_cross_openssl="linux-mips32"
							qbt_cross_qtbase="linux-g++-32"
							;;
					esac
					;;
				mipsel)
					case "${qbt_cross_target}" in
						alpine)
							qbt_cross_host="mipsel-linux-musl"
							;;&
						debian | ubuntu)
							qbt_cross_host="mipsel-linux-gnu"
							;;&
						*)
							bitness="32"
							cross_arch="mipsel"
							qbt_cross_boost="gcc-mipsel"
							qbt_cross_openssl="linux-mips32"
							qbt_cross_qtbase="linux-g++-32"
							;;
					esac
					;;
				mips64)
					case "${qbt_cross_target}" in
						alpine)
							qbt_cross_host="mips64-linux-musl"
							;;&
						debian | ubuntu)
							qbt_cross_host="mips64-linux-gnuabi64"
							;;&
						*)
							bitness="64"
							cross_arch="mips64"
							qbt_cross_boost="gcc-mips64"
							qbt_cross_openssl="linux64-mips64"
							qbt_cross_qtbase="linux-g++-64"
							;;
					esac
					;;
				mips64el)
					case "${qbt_cross_target}" in
						alpine)
							qbt_cross_host="mips64el-linux-musl"
							;;&
						debian | ubuntu)
							qbt_cross_host="mips64el-linux-gnuabi64"
							;;&
						*)
							bitness="64"
							cross_arch="mips64el"
							qbt_cross_boost="gcc-mips64el"
							qbt_cross_openssl="linux64-mips64"
							qbt_cross_qtbase="linux-g++-64"
							;;
					esac
					;;
				riscv64)
					case "${qbt_cross_target}" in
						alpine)
							qbt_cross_host="riscv64-linux-musl"
							;;&
						debian | ubuntu)
							qbt_cross_host="riscv64-linux-gnu"
							;;&
						*)
							bitness="64"
							cross_arch="riscv64"
							qbt_cross_boost="gcc-riscv64"
							qbt_cross_openssl="linux64-riscv64"
							qbt_cross_qtbase="linux-g++-64"
							;;
					esac
					;;
				loongarch64)
					case "${qbt_cross_target}" in
						alpine)
							if [[ ${qbt_qt_version} == '6' ]]; then
								cross_arch="loongarch64"
								qbt_cross_host="loongarch64-linux-musl"
							else
								printf '\n%b\n\n' " ${unicode_red_circle} The arch ${color_yellow_light}${qbt_cross_name}${color_end} can only be cross built on an Alpine Host with qt6"
								exit
							fi
							;;&
						debian | ubuntu)
							printf '\n%b\n\n' " ${unicode_red_circle} The arch ${color_yellow_light}${qbt_cross_name}${color_end} can only be cross built on and Alpine Host with qt6"
							exit
							;;&
						*)
							bitness="64"
							qbt_cross_boost="gcc-loongarch64"
							qbt_cross_openssl="linux64-loongarch64"
							qbt_cross_qtbase="linux-g++-64"
							;;
					esac
					;;
			esac

			[[ ${1} == 'info_bootstrap' ]] && return

			mkdir -p "${qbt_install_dir}/logs"

			if [[ ${1} == 'bootstrap' || ${qbt_cache_dir_options} == "bs" ]] && [[ -f "${qbt_cache_dir:-${qbt_install_dir}}/${qbt_cross_host}.tar.gz" ]]; then
				rm -f "${qbt_cache_dir:-${qbt_install_dir}}/${qbt_cross_host}.tar.gz"
			fi

			if [[ ${qbt_cross_target} =~ ^(alpine)$ ]]; then
				if [[ ${os_arch} == "aarch64" ]]; then
					qbt_mcm_toolchain_prefix="aarch64"
				elif [[ ${os_arch} == "x86_64" ]]; then
					qbt_mcm_toolchain_prefix="x86_64"
				else
					printf '\n%b\n' " ${unicode_red_circle} We can only crossbuild from a x86_64 or aarch64 host"
					exit
				fi

				if [[ ${QBT_MCM_DOCKER} != "YES" ]]; then
					if [[ ${1} == "bootstrap" || ${qbt_cache_dir_options} == "bs" || ! -f "${qbt_cache_dir:-${qbt_install_dir}}/${qbt_cross_host}.tar.gz" ]]; then
						printf '\n%b\n' " ${unicode_blue_light_circle} Downloading ${color_magenta_light}${qbt_cross_host}.tar.gz${color_end} cross tool chain - ${color_cyan_light}https://github.com/${qbt_mcm_url}/releases/latest/download/${qbt_mcm_toolchain_prefix}-${qbt_cross_host}.tar.xz${color_end}"
						_curl --create-dirs "https://github.com/${qbt_mcm_url}/releases/latest/download/${qbt_mcm_toolchain_prefix}-${qbt_cross_host}.tar.xz" -o "${qbt_cache_dir:-${qbt_install_dir}}/${qbt_cross_host}.tar.gz"
					fi

					if [[ -f "${qbt_install_dir}/.active-toolchain-info" ]]; then
						if [[ $(cat "${qbt_install_dir}/.active-toolchain-info") == "${qbt_cross_host}.tar.gz" ]]; then
							if "${qbt_install_dir}/bin/${qbt_cross_host}-gcc" -v &> /dev/null; then
								skip_toolchain_extract="yes"
							fi
						fi
					fi

					if [[ ${skip_toolchain_extract} == "yes" ]]; then
						printf '\n%b\n' " ${unicode_blue_light_circle} Extracted ${color_magenta_light}${qbt_cross_host}.tar.gz${color_end} cross tool chain - ${color_cyan_light}${qbt_cache_dir:-${qbt_install_dir}}/${qbt_cross_host}.tar.xz${color_end}"
					else
						printf '\n%b\n' " ${unicode_blue_light_circle} Extracting ${color_magenta_light}${qbt_cross_host}.tar.gz${color_end} cross tool chain - ${color_cyan_light}${qbt_cache_dir:-${qbt_install_dir}}/${qbt_cross_host}.tar.xz${color_end}"
						tar xf "${qbt_cache_dir:-${qbt_install_dir}}/${qbt_cross_host}.tar.gz" --strip-components=1 -C "${qbt_install_dir}"
						printf '%s\n' "${qbt_cross_host}.tar.gz" > "${qbt_install_dir}/.active-toolchain-info"
					fi

					_pushd "${qbt_install_dir}/bin"
					for f in "${qbt_cross_host}"-*; do
						ln -fsn "$f" "${f#"${qbt_cross_host}-"}"
					done
					_popd

					_fix_multiarch_static_links "${qbt_cross_host}"
				fi

			fi

			if [[ ${qbt_host_deps} == "yes" ]] || [[ ${qbt_with_qemu} == "no" ]]; then
				qbt_use_host_deps="yes"
			fi

			multi_glibc=("--host=${qbt_cross_host}") # ${multi_glibc[@]}
			multi_iconv=("--host=${qbt_cross_host}") # ${multi_iconv[@]}

			if [[ ${qbt_use_host_deps} == "yes" ]]; then
				multi_icu=("--host=${qbt_cross_host}" "-with-cross-build=${qbt_host_deps_path}")
			fi

			multi_openssl=("./Configure" "${qbt_cross_openssl}") # ${multi_openssl[@]}
			multi_qtbase=("-xplatform" "${qbt_cross_qtbase}")    # ${multi_qtbase[@]}

			if [[ ${qbt_build_tool} == 'cmake' ]]; then
				multi_libtorrent=("-D CMAKE_CXX_COMPILER=${qbt_cross_host}-g++")        # ${multi_libtorrent[@]}
				multi_double_conversion=("-D CMAKE_CXX_COMPILER=${qbt_cross_host}-g++") # ${multi_double_conversion[@]}
				multi_qtbase=("-D CMAKE_CXX_COMPILER=${qbt_cross_host}-g++")            # ${multi_qtbase[@]}
				multi_qttools=("-D CMAKE_CXX_COMPILER=${qbt_cross_host}-g++")           # ${multi_qttools[@]}
				multi_qbittorrent=("-D CMAKE_CXX_COMPILER=${qbt_cross_host}-g++")       # ${multi_qbittorrent[@]}

				if [[ ${qbt_use_host_deps} == "yes" ]]; then
					multi_qtbase+=("-D QT_HOST_PATH=${qbt_host_deps_path}")
				fi
			else
				multi_libtorrent=("toolset=${qbt_cross_boost:-gcc}") # ${multi_libtorrent[@]}
				multi_qbittorrent=("--host=${qbt_cross_host}")       # ${multi_qbittorrent[@]}
			fi
			return
		else
			printf '\n%b\n\n' " ${unicode_red_circle} Multiarch only works with Alpine Linux (native or docker)${color_end}"
			exit
		fi
	else
		if [[ -n ${qbt_cross_name} && ${qbt_cross_name} == "default" ]]; then
			multi_openssl=("./config") # ${multi_openssl[@]}
			return
		else
			printf '\n%b\n\n' " ${unicode_red_circle} ${qbt_cross_name} is not a valid cross name option from this list:${color_end}"

			while IFS= read -r qcn; do
				for n in "${qcn[@]}"; do
					printf '   %s\n' "$qcn"
				done
			done < <(printf '%s\n' "${!multi_arch_options[@]}" | sort)

			printf '\n'
			exit
		fi
	fi
}
#######################################################################################################################################################
# Github Actions release info
#######################################################################################################################################################
_release_info() {
	_error_tag

	printf '\n%b\n' " ${unicode_green_circle} ${color_yellow_light}Release bootstrapped${color_end}"

	release_info_dir="${qbt_install_dir}/release_info"

	mkdir -p "${release_info_dir}"

	cat > "${release_info_dir}/tag.md" <<- TAG_INFO
		${github_tag[qbittorrent]}_${github_tag[libtorrent]}
	TAG_INFO

	cat > "${release_info_dir}/title.md" <<- TITLE_INFO
		qbittorrent ${app_version[qbittorrent]} libtorrent ${app_version[libtorrent]}
	TITLE_INFO

	if _git_git ls-remote -t --exit-code "https://github.com/${qbt_revision_url}.git" "${github_tag[qbittorrent]}_${github_tag[libtorrent]}" &> /dev/null; then
		if grep -q '"name": "dependency-version.json"' < <(_curl "https://api.github.com/repos/${qbt_revision_url}/releases/tags/${github_tag[qbittorrent]}_${github_tag[libtorrent]}"); then
			until _curl "https://github.com/${qbt_revision_url}/releases/download/${github_tag[qbittorrent]}_${github_tag[libtorrent]}/dependency-version.json" > "${release_info_dir}/remote-dependency-version.json"; do
				printf '%b\n' "Waiting for dependency-version.json URL."
				sleep 2
			done

			remote_revision_version="$(sed -rn 's|(.*)"revision": "(.*)"|\2|p' < "${release_info_dir}/remote-dependency-version.json")"
			rm -f "${release_info_dir}/remote-dependency-version.json"
			qbt_revision_version="$((remote_revision_version + 1))"
		fi
	fi

	# Dependency version info
	printf '%b\n' "{\n  \"openssl\": \"${app_version[openssl]}\",\n  \"boost\": \"${app_version[boost]}\",\n  \"libtorrent_${qbt_libtorrent_version//\./_}\": \"${app_version[libtorrent]}\",\n  \"qt${qt_version_short_array[0]}\": \"${app_version[qtbase]}\",\n  \"qbittorrent\": \"${app_version[qbittorrent]}\",\n  \"revision\": \"${qbt_revision_version:-0}\"\n}" > "${release_info_dir}/qt${qt_version_short_array[0]}-dependency-version.json"

	[[ ${qbt_workflow_files} == "no" ]] && source_text="source files - direct"
	[[ ${qbt_workflow_files} == "yes" ]] && source_text="source files - workflows: [qbt-workflow-files](https://github.com/userdocs/qbt-workflow-files/releases/latest)"

	cat > "${release_info_dir}/qt${qt_version_short_array[0]}-${qbt_cross_name}-release.md" <<- RELEASE_INFO
		## Build info

		|           Components           |           Version           |
		| :----------------------------: | :-------------------------: |
		|          Qbittorrent           | ${app_version[qbittorrent]} |
		| Qt${qt_version_short_array[0]} |   ${app_version[qtbase]}    |
		|           Libtorrent           | ${app_version[libtorrent]}  |
		|             Boost              |    ${app_version[boost]}    |
		|            OpenSSL             |   ${app_version[openssl]}   |
		|        ${qbt_zlib_type}        |    ${app_version[zlib]}     |
		|            revision            | ${qbt_revision_version:-0}  |

		## Architecture and build info

		> [!NOTE]
		> ${source_text}
		>
		> These builds were created on Alpine linux using [custom prebuilt musl toolchains](https://github.com/userdocs/qbt-musl-cross-make/releases/latest) for:

		## Docker containers

		This project does not provider containers for these binaries. It provides a binary that other projects use to do that.

		An example project thats provides a complete solution: https://hotio.dev/containers/qbittorrent/

		- [libtorrent versions](https://github.com/userdocs/qbittorrent-nox-static?tab=readme-ov-file#libtorrent-versions) \`v1.2\` and \`2.0\` builds in a single container
		- Tracks [build revisions](https://github.com/userdocs/qbittorrent-nox-static?tab=readme-ov-file#revisions) for critical patches and dependency updates.
		- wireguard vpn configuration - https://hotio.dev/containers/qbittorrent/#wireguard

	RELEASE_INFO

	{
		printf '\n%s\n' "|  Crossarch  | Alpine Cross build files | Arch config |                                                             Tuning                                                              |"
		printf '%s\n' "| :---------: | :----------------------: | :---------: | :-----------------------------------------------------------------------------------------------------------------------------: |"
		[[ ${multi_arch_options[${qbt_cross_name}]} == armel ]] && printf '%s\n' "|    armel    |    arm-linux-musleabi    |   armv5te   |                       --with-arch=armv5te --with-tune=arm926ej-s --with-float=soft --with-abi=aapcs-linux                       |"
		[[ ${multi_arch_options[${qbt_cross_name}]} == armhf ]] && printf '%s\n' "|    armhf    |   arm-linux-musleabihf   |   armv6zk   |              --with-arch=armv6kz --with-tune=arm1176jzf-s --with-fpu=vfpv2 --with-float=hard --with-abi=aapcs-linux             |"
		[[ ${multi_arch_options[${qbt_cross_name}]} == armv7 ]] && printf '%s\n' "|    armv7    | armv7l-linux-musleabihf  |   armv7-a   | --with-arch=armv7-a --with-tune=generic-armv7-a --with-fpu=vfpv3-d16 --with-float=hard --with-abi=aapcs-linux --with-mode=thumb |"
		[[ ${multi_arch_options[${qbt_cross_name}]} == aarch64 ]] && printf '%s\n' "|   aarch64   |    aarch64-linux-musl    |   armv8-a   |                                               --with-arch=armv8-a --with-abi=lp64                                               |"
		[[ ${multi_arch_options[${qbt_cross_name}]} == x86_64 ]] && printf '%s\n' "|   x86_64    |    x86_64-linux-musl     |    amd64    |                                                               N/A                                                               |"
		[[ ${multi_arch_options[${qbt_cross_name}]} == x86 ]] && printf '%s\n' "|     x86     |     i686-linux-musl      |    i686     |                                        --with-arch=pentium-m --with-fpmath=sse --with-tune=generic --enable-cld                 |"
		[[ ${multi_arch_options[${qbt_cross_name}]} == s390x ]] && printf '%s\n' "|    s390x    |     s390x-linux-musl     |    zEC12    |                  --with-arch=z196 --with-tune=zEC12 --with-zarch --with-long-double-128 --enable-decimal-float                  |"
		[[ ${multi_arch_options[${qbt_cross_name}]} == powerpc ]] && printf '%s\n' "|   powerpc   |    powerpc-linux-musl    |     ppc     |                                          --enable-secureplt --enable-decimal-float=no                                           |"
		[[ ${multi_arch_options[${qbt_cross_name}]} == ppc64el ]] && printf '%s\n' "| powerpc64le |  powerpc64le-linux-musl  |    ppc64    |                 --with-abi=elfv2 --enable-secureplt --enable-decimal-float=no --enable-targets=powerpcle-linux                  |"
		[[ ${multi_arch_options[${qbt_cross_name}]} == mips ]] && printf '%s\n' "|    mips     |     mips-linux-musl      |    mips32     |                               --with-arch=mips32 --with-mips-plt --with-float=soft --with-abi=32                                |"
		[[ ${multi_arch_options[${qbt_cross_name}]} == mipsel ]] && printf '%s\n' "|   mipsel    |    mipsel-linux-musl     |   mips32    |                                -with-arch=mips32 --with-mips-plt --with-float=soft --with-abi=32                                |"
		[[ ${multi_arch_options[${qbt_cross_name}]} == mips64 ]] && printf '%s\n' "|   mips64    |    mips64-linux-musl     |   mips64    |                      --with-arch=mips3 --with-tune=mips64 --with-mips-plt --with-float=soft --with-abi=64                       |"
		[[ ${multi_arch_options[${qbt_cross_name}]} == mips64el ]] && printf '%s\n' "|  mips64el   |   mips64el-linux-musl    |   mips64    |                      --with-arch=mips3 --with-tune=mips64 --with-mips-plt --with-float=soft --with-abi=64                       |"
		[[ ${multi_arch_options[${qbt_cross_name}]} == riscv64 ]] && printf '%s\n' "|   riscv64   |    riscv64-linux-musl    |   rv64gc    |                                 --with-arch=rv64gc --with-abi=lp64d --enable-autolink-libatomic                                 |"
		[[ ${multi_arch_options[${qbt_cross_name}]} == loongarch64 ]] && printf '%s\n' "|   loongarch64   |    loongarch64-linux-musl    |   la64v1.0    |                                --with-arch=la64v1.0 --with-abi=lp64d                                 |"
		printf '\n'
	} >> "${release_info_dir}/qt${qt_version_short_array[0]}-${qbt_cross_name}-release.md"
	return
}
#######################################################################################################################################################
# This is first help section that for triggers that do not require any processing and only provide a static result whe using help
#######################################################################################################################################################
while (("${#}")); do
	case ${1} in
		-b | --build-directory)
			if [[ -n $2 ]]; then
				qbt_build_dir="${2}"
				shift 2
			else
				printf '\n%b\n\n' " ${unicode_red_circle} You must provide a directory path when using ${color_blue_light}-b${color_end}"
				exit
			fi
			;;
		-bs-c | --bootstrap-cmake)
			qbt_build_tool="cmake"
			params1+=("-bs-c")
			shift
			;;
		-c | --cmake)
			qbt_build_tool="cmake"
			shift
			;;
		-d | --debug)
			qbt_build_debug="yes"
			shift
			;;
		-cd | --cache-directory)
			qbt_cache_dir="${2%/}"
			if [[ -n ${3} && ${3} =~ (^rm$|^bs$) ]]; then
				qbt_cache_dir_options="${3}"

				_cache_dirs_qbt_env_copy

				if [[ ${3} == "rm" ]]; then
					[[ -d ${qbt_cache_dir} ]] && rm -rf "${qbt_cache_dir}"
					printf '\n%b\n\n' " ${unicode_red_circle} Cache directory removed: ${color_cyan_light}${qbt_cache_dir}${color_end}"
					exit
				fi
				shift 3
			else
				shift 2
			fi
			;;
		-i | --icu)
			qbt_skip_icu="no"
			if [[ ${qbt_skip_icu} == "no" ]]; then
				qbt_modules_delete["icu"]="false"
			fi
			shift
			;;
		-ma | --multi-arch)
			if [[ -n ${2} && ${multi_arch_options[${2}]} == "${2}" ]]; then
				qbt_cross_name="${2}"
				shift 2
			else
				printf '\n%b\n\n' " ${unicode_red_circle} You must provide a valid arch option when using${color_end} ${color_blue_light}-ma${color_end}"
				unset "multi_arch_options[default]"
				for arches in "${multi_arch_options[@]}"; do
					printf '%b\n' " ${unicode_blue_light_circle} ${arches}${color_end}"
				done
				printf '\n%b\n\n' " ${unicode_green_circle} Example usage:${color_blue_light} -ma aarch64${color_end}"
				exit
			fi
			;;
		-p | --proxy)
			qbt_git_proxy=("-c" "http.sslVerify=false" "-c" "http.https://github.com.proxy=${2}")
			qbt_curl_proxy=("--proxy-insecure" "-x" "${2}")
			shift 2
			;;
		-o | --optimise)
			if [[ -z ${qbt_cross_name} ]] || [[ ${qbt_cross_name} == "default" ]]; then
				qbt_optimise="yes"
				shift 1
			else
				printf '\n%b\n\n' " ${unicode_red_light_circle} You cannot use the ${color_blue_light}-o${color_end} flag with cross compilation"
				exit
			fi
			;;
		-q | --qmake)
			qbt_build_tool="--qmake"
			shift
			;;
		-s | --strip)
			qbt_optimise_strip="yes"
			shift
			;;
		-bs-e | --bootstrap-env)
			printf '\n%b\n\n' " ${unicode_green_light_circle} A template .qbt_env has been created${color_end}"
			_print_env | sed -e '1,/qbt/{ /qbt/!d }' -e 's/\x1B\[93m//g' -e 's/\x1B\[92m//g' -e 's/\x1B\[0m//g' -e 's/^[[:space:]]*//' -e '/^$/d' > .qbt_env
			exit
			;;
		-si | --static-ish)
			if [[ -z ${qbt_cross_name} ]] || [[ ${qbt_cross_name} == "default" ]]; then
				qbt_static_ish="yes"
				shift
			else
				printf '\n%b\n\n' " ${unicode_red_light_circle} You cannot use the ${color_blue_light}-si${color_end} flag with cross compilation${color_end}"
				exit
			fi
			;;
		-sdu | --script-debug-urls)
			script_debug_urls="yes"
			shift
			;;
		-wf | --workflow)
			qbt_workflow_files="yes"
			shift
			;;
		--) # end argument parsing
			shift
			break
			;;
		*) # preserve positional arguments
			params1+=("${1}")
			shift
			;;
	esac
done
# Set positional arguments in their proper place.
set -- "${params1[@]}"
#######################################################################################################################################################
# Functions part 1: Use some of our functions
#######################################################################################################################################################
_set_default_values "${@}"                                                  # see functions
_check_dependencies "${@}" && set -- "${filtered_check_dependency_args[@]}" # see functions
_test_url
_set_build_directory    # see functions
_set_module_urls "${@}" # see functions
_script_version         # see functions
#######################################################################################################################################################
# Environment variables - settings positional parameters of flags
#######################################################################################################################################################
[[ -n ${qbt_patches_url} ]] && set -- -pr "${qbt_patches_url}" "${@}"
[[ -n ${qbt_boost_tag} ]] && set -- -bt "${qbt_boost_tag}" "${@}"
[[ -n ${qbt_libtorrent_tag} ]] && set -- -lt "${qbt_libtorrent_tag}" "${@}"
[[ -n ${qbt_qt_tag} ]] && set -- -qtt "${qbt_qt_tag}" "${@}"
[[ -n ${qbt_qbittorrent_tag} ]] && set -- -qt "${qbt_qbittorrent_tag}" "${@}"
#######################################################################################################################################################
# This section controls our flags that we can pass to the script to modify some variables and behavior.
#######################################################################################################################################################
while (("${#}")); do
	case "${1}" in
		-bs-ef | --bootstrap-env-full)
			printf '\n%b\n\n' " ${unicode_green_light_circle} A template .qbt_env has been created${color_end}"
			_print_env | sed -e '1,/qbt/{ /qbt/!d }' -e 's/\x1B\[93m//g' -e 's/\x1B\[92m//g' -e 's/\x1B\[0m//g' -e 's/^[[:space:]]*//' -e '/^$/d' > .qbt_env
			exit
			;;
		-bs-p | --bootstrap-patches)
			_apply_patches bootstrap
			shift
			;;
		-bs-r | --bootstrap-release)
			_release_info
			shift
			;;
		-bs-ma | --bootstrap-multi-arch)
			if [[ ${multi_arch_options[${qbt_cross_name}]} == "${qbt_cross_name}" ]]; then
				_multi_arch
				shift
			else
				printf '\n%b\n\n' " ${unicode_red_circle} You must provide a valid arch option when using${color_end} ${color_blue_light}-ma${color_end}"
				for arches in "${multi_arch_options[@]}"; do
					printf '%b\n' " ${unicode_blue_light_circle} ${arches}${color_end}"
				done
				printf '\n%b\n\n' " ${unicode_green_circle} Example usage:${color_blue_light} -ma aarch64${color_end}"
				exit
			fi
			;;
		-bs-a | --bootstrap-all)
			_installation_modules
			_apply_patches bootstrap
			_release_info
			_multi_arch bootstrap
			_qbt_host_deps
			shift
			;;
		-bt | --boost-tag)
			if [[ -n ${2} ]]; then
				qbt_default_boost_github_tag="${github_tag[boost]}"
				github_tag[boost]="$(_git "${github_url[boost]}" -t "${2}")"
				app_version[boost]="${github_tag[boost]#boost-}"
				_boost_url

				# if qbt_default_boost_github_tag is the same as the define tag, don't override.
				if [[ ${qbt_default_boost_github_tag} != "${github_tag[boost]}" ]]; then
					qbt_workflow_override[boost]="yes"
				fi
				unset qbt_default_boost_github_tag

				# if using libtorrent v1.2 then override workflow files since it is limited to boost-1.86.0 which is not latest
				if [[ ${qbt_libtorrent_version} == "1.2" || ${github_tag[libtorrent]} =~ ^(v1\.2\.|RC_1_2) ]]; then
					qbt_workflow_override[boost]="yes"
				fi

				_test_git_ouput "${github_tag[boost]}" "boost" "${2}"
				shift 2
			else
				printf '\n%b\n\n' " ${unicode_red_circle} ${color_yellow_light}You must provide a tag for this switch:${color_end} ${color_blue_light}${1} TAG ${color_end}"
				exit
			fi
			;;
		-n | --no-delete)
			qbt_skip_delete="yes"
			shift
			;;
		-m | --master)
			github_tag[libtorrent]="$(_git "${github_url[libtorrent]}" -t "RC_${qbt_libtorrent_version//./_}")"
			app_version[libtorrent]="${github_tag[libtorrent]}"
			qbt_workflow_override[libtorrent]="yes"
			source_default[libtorrent]="folder"
			_test_git_ouput "${github_tag[libtorrent]}" "libtorrent" "RC_${qbt_libtorrent_version//./_}"
			github_tag[qbittorrent]="$(_git "${github_url[qbittorrent]}" -t "master")"
			app_version[qbittorrent]="${github_tag[qbittorrent]#release-}"
			qbt_workflow_override[qbittorrent]="yes"
			source_default[qbittorrent]="folder"
			_test_git_ouput "${github_tag[qbittorrent]}" "qbittorrent" "master"
			shift
			;;
		-lm | --libtorrent-master)
			github_tag[libtorrent]="$(_git "${github_url[libtorrent]}" -t "RC_${qbt_libtorrent_version//./_}")"
			app_version[libtorrent]="${github_tag[libtorrent]}"
			source_default[qbittorrent]="folder"
			qbt_workflow_override[libtorrent]="yes"
			_test_git_ouput "${github_tag[libtorrent]}" "libtorrent" "RC_${qbt_libtorrent_version//./_}"
			shift
			;;
		-lt | --libtorrent-tag)
			if [[ -n ${2} ]]; then
				qbt_default_libtorrent_github_tag="${github_tag[libtorrent]}"
				github_tag[libtorrent]="$(_git "${github_url[libtorrent]}" -t "$2")"
				[[ ${github_tag[libtorrent]} =~ ^RC_ ]] && app_version[libtorrent]="${github_tag[libtorrent]/RC_/}" app_version[libtorrent]="${app_version[libtorrent]//_/\.}"
				[[ ${github_tag[libtorrent]} =~ ^libtorrent- ]] && app_version[libtorrent]="${github_tag[libtorrent]#libtorrent-}" app_version[libtorrent]="${app_version[libtorrent]//_/\.}"
				[[ ${github_tag[libtorrent]} =~ ^libtorrent_ ]] && app_version[libtorrent]="${github_tag[libtorrent]#libtorrent_}" app_version[libtorrent]="${app_version[libtorrent]//_/\.}"
				[[ ${github_tag[libtorrent]} =~ ^v[0-9] ]] && app_version[libtorrent]="${github_tag[libtorrent]#v}"
				source_archive_url[libtorrent]="https://github.com/arvidn/libtorrent/releases/download/${github_tag[libtorrent]}/libtorrent-rasterbar-${app_version[libtorrent]}.tar.gz"
				if ! _curl "${source_archive_url[libtorrent]}" &> /dev/null; then
					source_default[libtorrent]="folder"
				fi

				# if qbt_default_libtorrent_github_tag is the same as the define tag, don't override.
				if [[ ${qbt_default_libtorrent_github_tag} != "${github_tag[libtorrent]}" ]]; then
					qbt_workflow_override[libtorrent]="yes"
				fi
				unset qbt_default_libtorrent_github_tag

				read -ra lt_version_short_array <<< "${app_version[libtorrent]//\./ }"
				qbt_libtorrent_version="${lt_version_short_array[0]}.${lt_version_short_array[1]}"
				[[ ${github_tag[libtorrent]} =~ ^RC_ ]] && app_version[libtorrent]="RC_${app_version[libtorrent]//\./_}" # set back to RC_... so that release info has proper version context

				_test_git_ouput "${github_tag[libtorrent]}" "libtorrent" "$2"

				# If libtorrent v1.2 is used then set default boost tag to boost-1.86.0
				if [[ ${qbt_libtorrent_version} == "1.2" || ${github_tag[libtorrent]} =~ ^(v1\.2\.|RC_1_2) ]]; then
					github_tag[boost]="boost-1.86.0"
					app_version[boost]="${github_tag[boost]#boost-}"
					_boost_url
				fi

				_libtorrent_v2_iconv_check

				shift 2
			else
				printf '\n%b\n\n' " ${unicode_red_circle} ${color_yellow_light}You must provide a tag for this switch:${color_end} ${color_blue_light}${1} TAG ${color_end}"
				exit
			fi
			;;
		-pr | --patch-repo)
			if [[ -n ${2} ]]; then
				if _curl "https://github.com/${2}" &> /dev/null; then
					qbt_patches_url="${2}"
				else
					printf '\n%b\n' " ${unicode_red_circle} ${color_yellow_light}This repo does not exist:${color_end}"
					printf '\n%b\n' "   ${color_cyan_light}https://github.com/${2}${color_end}"
					printf '\n%b\n\n' " ${unicode_yellow_circle} ${color_yellow_light}Please provide a valid username and repo.${color_end}"
					exit
				fi
				shift 2
			else
				printf '\n%b\n\n' " ${unicode_red_circle} ${color_yellow_light}You must provide a tag for this switch:${color_end} ${color_blue_light}${1} username/repo ${color_end}"
				exit
			fi
			;;
		-qm | --qbittorrent-master)
			github_tag[qbittorrent]="$(_git "${github_url[qbittorrent]}" -t "master")"
			app_version[qbittorrent]="${github_tag[qbittorrent]#release-}"
			qbt_workflow_override[qbittorrent]="yes"
			source_archive_url[qbittorrent]="https://github.com/qbittorrent/qBittorrent/archive/refs/heads/${github_tag[qbittorrent]}.tar.gz"
			_test_git_ouput "${github_tag[qbittorrent]}" "qbittorrent" "master"
			shift
			;;
		-qt | --qbittorrent-tag)
			if [[ -n ${2} ]]; then
				qbt_default_qbittorrent_github_tag="${github_tag[qbittorrent]}"
				github_tag[qbittorrent]="$(_git "${github_url[qbittorrent]}" -t "$2")"
				app_version[qbittorrent]="${github_tag[qbittorrent]#release-}"
				if [[ ${github_tag[qbittorrent]} =~ ^release- ]]; then
					source_archive_url[qbittorrent]="https://github.com/qbittorrent/qBittorrent/archive/refs/tags/${github_tag[qbittorrent]}.tar.gz"
				else
					source_archive_url[qbittorrent]="https://github.com/qbittorrent/qBittorrent/archive/refs/heads/${github_tag[qbittorrent]}.tar.gz"
				fi

				# if qbt_default_qbittorrent_github_tag is the same as the define tag, don't override.
				if [[ ${qbt_default_qbittorrent_github_tag} != "${github_tag[qbittorrent]}" ]]; then
					qbt_workflow_override[qbittorrent]="yes"
				fi
				unset qbt_default_qbittorrent_github_tag

				_test_git_ouput "${github_tag[qbittorrent]}" "qbittorrent" "$2"
				shift 2
			else
				printf '\n%b\n\n' " ${unicode_red_circle} ${color_yellow_light}You must provide a tag for this switch:${color_end} ${color_blue_light}${1} TAG ${color_end}"
				exit
			fi
			;;
		-qtt | --qt-tag)
			if [[ -n ${2} ]]; then
				qbt_default_qtbase_github_tag="${github_tag[qtbase]}"
				github_tag[qtbase]="$(_git "${github_url[qtbase]}" -t "${2}")"
				github_tag[qttools]="$(_git "${github_url[qttools]}" -t "${2}")"
				app_version[qtbase]="$(printf '%s' "${github_tag[qtbase]#v}" | sed 's/-lts-lgpl//g')"
				app_version[qttools]="$(printf '%s' "${github_tag[qttools]#v}" | sed 's/-lts-lgpl//g')"

				# if qbt_default_qtbase_github_tag is the same as the define tag, don't override.
				if [[ ${qbt_default_qtbase_github_tag} != "${github_tag[qtbase]}" ]]; then
					source_default[qtbase]="folder"
					source_default[qttools]="folder"
					qbt_workflow_override[qtbase]="yes"
					qbt_workflow_override[qttools]="yes"
				fi
				unset qbt_default_qtbase_github_tag

				qbt_qt_version="${app_version[qtbase]%%.*}"
				read -ra qt_version_short_array <<< "${app_version[qtbase]//\./ }"
				qt_version_short="${qt_version_short_array[0]}.${qt_version_short_array[1]}"
				_test_git_ouput "${github_tag[qtbase]}" "qtbase" "${2}"
				_test_git_ouput "${github_tag[qttools]}" "qttools" "${2}"

				if [[ $qbt_build_tool == "cmake" && ${2} =~ ^v5 ]]; then
					printf '\n%b\n' " ${unicode_red_circle} Please use a correct qt and build tool combination"
					printf '\n%b\n' " ${unicode_green_circle} qt5 + qmake ${unicode_green_circle} qt6 + cmake ${unicode_red_circle} qt5 + cmake ${unicode_red_circle} qt6 + qmake"
					_print_env
					exit
				fi
				shift 2
			else
				printf '\n%b\n\n' " ${unicode_red_circle} ${color_yellow_light}You must provide a tag for this switch:${color_end} ${color_blue_light}${1} TAG ${color_end}"
				exit
			fi
			;;
		-h | --help)
			printf '\n%b\n\n' " ${text_bold}${text_underlined}Here are a list of available options${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-b${color_end}     ${text_dim}or${color_end} ${color_blue_light}--build-directory${color_end}       ${color_yellow}Help:${color_end} ${color_blue_light}-h-b${color_end}     ${text_dim}or${color_end} ${color_blue_light}--help-build-directory${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-bt${color_end}    ${text_dim}or${color_end} ${color_blue_light}--boost-tag${color_end}             ${color_yellow}Help:${color_end} ${color_blue_light}-h-bt${color_end}    ${text_dim}or${color_end} ${color_blue_light}--help-boost-version${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-c${color_end}     ${text_dim}or${color_end} ${color_blue_light}--cmake${color_end}                 ${color_yellow}Help:${color_end} ${color_blue_light}-h-c${color_end}     ${text_dim}or${color_end} ${color_blue_light}--help-cmake${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-cd${color_end}    ${text_dim}or${color_end} ${color_blue_light}--cache-directory${color_end}       ${color_yellow}Help:${color_end} ${color_blue_light}-h-cd${color_end}    ${text_dim}or${color_end} ${color_blue_light}--help-cache-directory${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-d${color_end}     ${text_dim}or${color_end} ${color_blue_light}--debug${color_end}                 ${color_yellow}Help:${color_end} ${color_blue_light}-h-d${color_end}     ${text_dim}or${color_end} ${color_blue_light}--help-debug${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-bs-e${color_end}  ${text_dim}or${color_end} ${color_blue_light}--bootstrap-env${color_end}         ${color_yellow}Help:${color_end} ${color_blue_light}-h-bs-e${color_end}  ${text_dim}or${color_end} ${color_blue_light}--help-bootstrap-env${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-bs-ef${color_end} ${text_dim}or${color_end} ${color_blue_light}--bootstrap-env-full${color_end}    ${color_yellow}Help:${color_end} ${color_blue_light}-h-bs-ef${color_end} ${text_dim}or${color_end} ${color_blue_light}--help-bootstrap-env-full${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-bs-p${color_end}  ${text_dim}or${color_end} ${color_blue_light}--bootstrap-patches${color_end}     ${color_yellow}Help:${color_end} ${color_blue_light}-h-bs-p${color_end}  ${text_dim}or${color_end} ${color_blue_light}--help-bootstrap-patches${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-bs-c${color_end}  ${text_dim}or${color_end} ${color_blue_light}--bootstrap-cmake${color_end}       ${color_yellow}Help:${color_end} ${color_blue_light}-h-bs-c${color_end}  ${text_dim}or${color_end} ${color_blue_light}--help-bootstrap-cmake${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-bs-r${color_end}  ${text_dim}or${color_end} ${color_blue_light}--bootstrap-release${color_end}     ${color_yellow}Help:${color_end} ${color_blue_light}-h-bs-r${color_end}  ${text_dim}or${color_end} ${color_blue_light}--help-bootstrap-release${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-bs-ma${color_end} ${text_dim}or${color_end} ${color_blue_light}--bootstrap-multi-arch${color_end}  ${color_yellow}Help:${color_end} ${color_blue_light}-h-bs-ma${color_end} ${text_dim}or${color_end} ${color_blue_light}--help-bootstrap-multi-arch${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-bs-a${color_end}  ${text_dim}or${color_end} ${color_blue_light}--bootstrap-all${color_end}         ${color_yellow}Help:${color_end} ${color_blue_light}-h-bs-a${color_end}  ${text_dim}or${color_end} ${color_blue_light}--help-bootstrap-all${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-i${color_end}     ${text_dim}or${color_end} ${color_blue_light}--icu${color_end}                   ${color_yellow}Help:${color_end} ${color_blue_light}-h-i${color_end}     ${text_dim}or${color_end} ${color_blue_light}--help-icu${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-lm${color_end}    ${text_dim}or${color_end} ${color_blue_light}--libtorrent-master${color_end}     ${color_yellow}Help:${color_end} ${color_blue_light}-h-lm${color_end}    ${text_dim}or${color_end} ${color_blue_light}--help-libtorrent-master${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-lt${color_end}    ${text_dim}or${color_end} ${color_blue_light}--libtorrent-tag${color_end}        ${color_yellow}Help:${color_end} ${color_blue_light}-h-lt${color_end}    ${text_dim}or${color_end} ${color_blue_light}--help-libtorrent-tag${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-m${color_end}     ${text_dim}or${color_end} ${color_blue_light}--master${color_end}                ${color_yellow}Help:${color_end} ${color_blue_light}-h-m${color_end}     ${text_dim}or${color_end} ${color_blue_light}--help-master${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-ma${color_end}    ${text_dim}or${color_end} ${color_blue_light}--multi-arch${color_end}            ${color_yellow}Help:${color_end} ${color_blue_light}-h-ma${color_end}    ${text_dim}or${color_end} ${color_blue_light}--help-multi-arch${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-n${color_end}     ${text_dim}or${color_end} ${color_blue_light}--no-delete${color_end}             ${color_yellow}Help:${color_end} ${color_blue_light}-h-n${color_end}     ${text_dim}or${color_end} ${color_blue_light}--help-no-delete${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-o${color_end}     ${text_dim}or${color_end} ${color_blue_light}--optimise${color_end}              ${color_yellow}Help:${color_end} ${color_blue_light}-h-o${color_end}     ${text_dim}or${color_end} ${color_blue_light}--help-optimise${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-p${color_end}     ${text_dim}or${color_end} ${color_blue_light}--proxy${color_end}                 ${color_yellow}Help:${color_end} ${color_blue_light}-h-p${color_end}     ${text_dim}or${color_end} ${color_blue_light}--help-proxy${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-pr${color_end}    ${text_dim}or${color_end} ${color_blue_light}--patch-repo${color_end}            ${color_yellow}Help:${color_end} ${color_blue_light}-h-pr${color_end}    ${text_dim}or${color_end} ${color_blue_light}--help-patch-repo${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-q${color_end}     ${text_dim}or${color_end} ${color_blue_light}--qmake${color_end}                 ${color_yellow}Help:${color_end} ${color_blue_light}-h-q${color_end}     ${text_dim}or${color_end} ${color_blue_light}--help-qmake${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-qm${color_end}    ${text_dim}or${color_end} ${color_blue_light}--qbittorrent-master${color_end}    ${color_yellow}Help:${color_end} ${color_blue_light}-h-qm${color_end}    ${text_dim}or${color_end} ${color_blue_light}--help-qbittorrent-master${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-qt${color_end}    ${text_dim}or${color_end} ${color_blue_light}--qbittorrent-tag${color_end}       ${color_yellow}Help:${color_end} ${color_blue_light}-h-qt${color_end}    ${text_dim}or${color_end} ${color_blue_light}--help-qbittorrent-tag${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-qtt${color_end}   ${text_dim}or${color_end} ${color_blue_light}--qt-tag${color_end}                ${color_yellow}Help:${color_end} ${color_blue_light}-h-qtt${color_end}   ${text_dim}or${color_end} ${color_blue_light}--help-qtt-tag${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-sdu${color_end}   ${text_dim}or${color_end} ${color_blue_light}--script-debug-urls${color_end}     ${color_yellow}Help:${color_end} ${color_blue_light}-h-sdu${color_end}   ${text_dim}or${color_end} ${color_blue_light}--help-script-debug-urls${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-si${color_end}    ${text_dim}or${color_end} ${color_blue_light}--static-ish${color_end}            ${color_yellow}Help:${color_end} ${color_blue_light}-h-s${color_end}     ${text_dim}or${color_end} ${color_blue_light}--help-strip${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-s${color_end}     ${text_dim}or${color_end} ${color_blue_light}--strip${color_end}                 ${color_yellow}Help:${color_end} ${color_blue_light}-h-s${color_end}     ${text_dim}or${color_end} ${color_blue_light}--help-strip${color_end}"
			printf '%b\n' " ${color_green}Use:${color_end} ${color_blue_light}-wf${color_end}    ${text_dim}or${color_end} ${color_blue_light}--workflow${color_end}              ${color_yellow}Help:${color_end} ${color_blue_light}-h-wf${color_end}    ${text_dim}or${color_end} ${color_blue_light}--help-workflow${color_end}"
			printf '\n%b\n' " ${text_bold}${text_underlined}Module specific help - flags are used with the modules listed here.${color_end}"
			printf '\n%b\n' " ${color_green}Use:${color_end} ${color_magenta_light}all${color_end} ${text_dim}or${color_end} ${color_magenta_light}module-name${color_end}          ${color_green}Usage:${color_end} ${color_cyan_light}${qbt_working_dir_short}/${script_basename}${color_end} ${color_magenta_light}all${color_end} ${color_blue_light}-i${color_end}"
			printf '\n%b\n' " ${text_dim}${color_magenta_light}all${color_end} ${text_dim}----------------${color_end} ${text_dim}${color_yellow_light}optional${color_end} ${text_dim}Recommended method to install all modules${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}install${color_end} ${text_dim}------------${color_end} ${text_dim}${color_yellow_light}optional${color_end} ${text_dim}Install the ${text_dim}${color_cyan_light}${qbt_install_dir_short}/completed/qbittorrent-nox${color_end} ${text_dim}binary${color_end}"
			[[ ${os_id} =~ ^(debian|ubuntu)$ ]] && printf '%b\n' " ${text_dim}${color_magenta_light}glibc${color_end} ${text_dim}--------------${color_end} ${text_dim}${color_red_light}required${color_end} ${text_dim}Build libc locally to statically link nss${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}zlib${color_end} ${text_dim}---------------${color_end} ${text_dim}${color_red_light}required${color_end} ${text_dim}Build zlib locally${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}iconv${color_end} ${text_dim}--------------${color_end} ${text_dim}${color_red_light}required${color_end} ${text_dim}Build iconv locally (libtorrent v1.2 only)${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}icu${color_end} ${text_dim}----------------${color_end} ${text_dim}${color_yellow_light}optional${color_end} ${text_dim}Build ICU locally${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}openssl${color_end} ${text_dim}------------${color_end} ${text_dim}${color_red_light}required${color_end} ${text_dim}Build openssl locally${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}boost${color_end} ${text_dim}--------------${color_end} ${text_dim}${color_red_light}required${color_end} ${text_dim}Download, extract and build the boost library files${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}libtorrent${color_end} ${text_dim}---------${color_end} ${text_dim}${color_red_light}required${color_end} ${text_dim}Build libtorrent locally${color_end}"
			# printf '%b\n' " ${text_dim}${color_magenta_light}double_conversion${color_end} ${text_dim}--${color_end} ${text_dim}${color_red_light}required${color_end} ${text_dim}A cmake + Qt6 build component on modern OS only.${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}qtbase${color_end} ${text_dim}-------------${color_end} ${text_dim}${color_red_light}required${color_end} ${text_dim}Build qtbase locally${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}qttools${color_end} ${text_dim}------------${color_end} ${text_dim}${color_red_light}required${color_end} ${text_dim}Build qttools locally${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}qbittorrent${color_end} ${text_dim}--------${color_end} ${text_dim}${color_red_light}required${color_end} ${text_dim}Build qbittorrent locally${color_end}"

			printf '\n%b\n\n' " ${text_bold}${text_underlined}env help - supported exportable environment variables${color_end}"

			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_zlib_type=\"\"${color_end} ${text_dim}-----------------${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}zlib | zlib-ng${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_skip_icu=\"\"${color_end} ${text_dim}----------------- ${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}yes | no${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_boost_tag=\"\"${color_end} ${text_dim}-----------------${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}Takes a valid git tag or branch${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_libtorrent_version=\"\"${color_end} ${text_dim}--------${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}1.2 | 2.0${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_libtorrent_tag=\"\"${color_end} ${text_dim}------------${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}Takes a valid git tag or branch${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_libtorrent_master_jamfile=\"\"${color_end} ${text_dim}-${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}yes | no${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_qt_version=\"\"${color_end} ${text_dim}----------------${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}5 | 5.15 | 6 | 6.2 | 6.3 and so on${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_qt_tag=\"\"${color_end} ${text_dim}--------------------${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}Takes a valid git tag or branch${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_qbittorrent_tag=\"\"${color_end} ${text_dim}-----------${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}Takes a valid git tag or branch${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_build_dir=\"\"${color_end} ${text_dim}-----------------${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}path - a valid path${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_build_tool=\"\"${color_end} ${text_dim}----------------${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}cmake | qmake${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_cross_name=\"\"${color_end} ${text_dim}----------------${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}x86 | x86_64 | aarch64 | armv7 | armhf | riscv64 (see docs for more)${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_mcm_url=\"\"${color_end} ${text_dim}-------------------${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}userdocs/qbt-musl-cross-make${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_patches_url=\"\"${color_end} ${text_dim}---------------${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}userdocs/qbittorrent-nox-static${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_workflow_files=\"\"${color_end} ${text_dim}------------${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}userdocs/qbt-workflow-files${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_cache_dir=\"\"${color_end} ${text_dim}-----------------${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}path | empty - provide a path to a cache directory${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_optimise_strip=\"\"${color_end} ${text_dim}------------${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}yes | no${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_build_debug=\"\"${color_end} ${text_dim}---------------${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}yes | no${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_standard=\"\"${color_end} ${text_dim}------------------${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}14 | 17 | 20 | 23 - c standard for gcc - OS dependent${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_static_ish=\"\"${color_end} ${text_dim}----------------${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}yes | no${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_optimise=\"\"${color_end} ${text_dim}------------------${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}yes | no${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_host_deps=\"\"${color_end} ${text_dim}-----------------${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}yes | no${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_host_deps_repo=\"\"${color_end} ${text_dim}------------${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}userdocs/qbt-host-deps${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_legacy_mode=\"\"${color_end} ${text_dim}---------------${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}yes | no${color_end}"
			printf '%b\n' " ${text_dim}${color_magenta_light}export qbt_advanced_view=\"\"${color_end} ${text_dim}-------------${color_end} ${text_dim}${color_red_light}options${color_end} ${text_dim}yes | no${color_end}"

			_print_env
			exit
			;;
		-h-b | --help-build-directory)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " Default build location: ${color_cyan}${qbt_install_dir_short}${color_end}"
			printf '\n%b\n' " ${color_blue_light}-b${color_end} or ${color_blue_light}--build-directory${color_end} to set the location of the build directory."
			printf '\n%b\n' " ${color_yellow}Paths are relative to the script location. I recommend that you use a full path.${color_end}"
			printf '\n%b\n' " ${text_dim}${unicode_blue_light_circle} Usage example:${color_end} ${text_dim}${color_green}${qbt_working_dir_short}/${script_basename}${color_end} ${text_dim}${color_magenta_light}all${color_end} ${text_dim}- Will install all modules and build libtorrent to the default build location${color_end}"
			printf '\n%b\n' " ${text_dim}${unicode_blue_light_circle} Usage example:${color_end} ${text_dim}${color_green}${qbt_working_dir_short}/${script_basename}${color_end} ${text_dim}${color_magenta_light}module${color_end} ${text_dim}- Will install a single module to the default build location${color_end}"
			printf '\n%b\n\n' " ${text_dim}${unicode_blue_light_circle} Usage example:${color_end} ${text_dim}${color_green}${qbt_working_dir_short}/${script_basename}${color_end} ${text_dim}${color_magenta_light}module${color_end} ${color_blue_light}-b${color_end} ${text_dim}${color_cyan_light}\"\$HOME/build\"${color_end} ${text_dim}- will specify a custom build directory and install a specific module use to that custom location${color_end}"
			exit
			;;
		-h-bs-e | --help-bootstrap-env)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " Create the template env file ${color_cyan}.qbt_env${color_end}"
			printf '\n%b\n' " Notes:"
			printf '\n%b\n' " ${unicode_yellow_circle} If you use ${color_blue_light}-bs-e${color_end} it will create a default env file with empty vars and exit"
			printf '\n%b\n\n' " ${unicode_yellow_circle} Order of priority: script flags > env file > env vars"
			exit
			;;
		-h-bs-ef | --help-bootstrap-env-full)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " Create a populated template env file using provided flags or env vars${color_cyan}.qbt_env${color_end}"
			printf '\n%b\n' " Notes:"
			printf '\n%b\n' " ${unicode_yellow_circle} If you use ${color_blue_light}-bs-ef${color_end} it will create a default env file with populated vars and exit"
			printf '\n%b\n\n' " ${unicode_yellow_circle} Order of priority: script flags > env file > env vars"
			exit
			;;
		-h-bs-p | --help-bootstrap-patches)
			_apply_patches bootstrap-help
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " Creates dirs in this structure: ${color_cyan}${qbt_install_dir_short}/patches/app_name/tag/patch${color_end}"
			printf '\n%b\n' " Add your patches there, for example."
			printf '\n%b\n' " ${color_cyan}${qbt_install_dir_short}/patches/libtorrent/${app_version[libtorrent]}/patch${color_end}"
			printf '\n%b\n\n' " ${color_cyan}${qbt_install_dir_short}/patches/qbittorrent/${app_version[qbittorrent]}/patch${color_end}"
			exit
			;;
		-h-bs-r | --help-bootstrap-release)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' "${color_red_light} GitHub action specific. You probably don't need it${color_end}"
			printf '\n%b\n' " This switch creates some GitHub release template files in this directory"
			printf '\n%b\n' " ${qbt_install_dir_short}/release_info"
			printf '\n%b\n\n' "${color_green_light} Usage:${color_end} ${color_cyan_light}${qbt_working_dir_short}/${script_basename}${color_end} ${color_blue_light}-bs-r${color_end}"
			exit
			;;
		-h-bs-ma | --help-bootstrap-multi-arch)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " ${unicode_red_circle}${color_red_light} GitHub action and Alpine specific. You probably don't need it${color_end}"
			printf '\n%b\n' " This switch bootstraps the musl cross build files needed for any provided and supported architecture"
			printf '\n%b\n' " ${unicode_yellow_circle} armhf"
			printf '%b\n' " ${unicode_yellow_circle} armv7"
			printf '%b\n' " ${unicode_yellow_circle} aarch64"
			printf '\n%b\n' "${color_green_light} Usage:${color_end} ${color_cyan_light}${qbt_working_dir_short}/${script_basename}${color_end} ${color_blue_light}-bs-ma ${qbt_cross_name:-aarch64}${color_end}"
			printf '\n%b\n\n' " ${unicode_yellow_circle} You can also set it as a variable to trigger cross building: ${color_blue_light}export qbt_cross_name=${qbt_cross_name:-aarch64}${color_end}"
			exit
			;;
		-h-bs-a | --help-bootstrap-all)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " ${unicode_red_circle}${color_red_light} GitHub action specific and Alpine only. You probably don't need it${color_end}"
			printf '\n%b\n' " Performs all bootstrapping options"
			printf '\n%b\n' "${color_green_light} Usage:${color_end} ${color_cyan_light}${qbt_working_dir_short}/${script_basename}${color_end} ${color_blue_light}-bs-a${color_end}"
			printf '\n%b\n' " ${unicode_yellow_circle} ${color_yellow_light}Patches${color_end}"
			printf '%b\n' " ${unicode_yellow_circle} ${color_yellow_light}Release info${color_end}"
			printf '%b\n' " ${unicode_yellow_circle} ${color_yellow_light}Multi arch${color_end} if the ${color_blue_light}-ma${color_end} flag is passed"
			printf '\n%b\n' " Equivalent of doing: ${color_cyan_light}${qbt_working_dir_short}/${script_basename}${color_end} ${color_blue_light}-bs -bs-r${color_end}"
			printf '\n%b\n\n' " And with ${color_blue_light}-c${color_end} and ${color_blue_light}-ma${color_end} : ${color_cyan_light}${qbt_working_dir_short}/${script_basename}${color_end} ${color_blue_light}-bs -bs-c -bs-ma -bs-r ${color_end}"
			exit
			;;
		-h-bt | --help-boost-tag)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " This will let you set a specific version of boost to use with older build combos"
			printf '\n%b\n' " ${unicode_blue_light_circle} Usage example: ${color_blue_light}-bt boost-1.81.0${color_end}"
			printf '\n%b\n\n' " ${unicode_blue_light_circle} Usage example: ${color_blue_light}-bt boost-1.82.0.beta1${color_end}"
			exit
			;;
		-h-c | --help-cmake)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " This flag can change the build process in a few ways."
			printf '\n%b\n' " ${unicode_yellow_circle} Use cmake to build libtorrent."
			printf '%b\n' " ${unicode_yellow_circle} Use cmake to build qbittorrent."
			printf '\n%b\n\n' " ${unicode_yellow_circle} This is the default setting for the script."
			exit
			;;
		-h-cd | --help-cache-directory)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " This will let you set a path of a directory that contains cached GitHub repos of modules"
			printf '\n%b\n' " ${unicode_yellow_circle} Cached apps folder names must match the module name. Case and spelling"
			printf '\n%b\n' " For example: ${color_cyan_light}~/cache_dir/qbittorrent${color_end}"
			printf '\n%b\n' " Additional flags supported: ${color_cyan_light}rm${color_end} - remove the cache directory and exit"
			printf '\n%b\n' " Additional flags supported: ${color_cyan_light}bs${color_end} - download cache for all activated modules then exit"
			printf '\n%b\n' " ${unicode_blue_light_circle} Usage example: ${color_blue_light}-cd ~/cache_dir${color_end}"
			printf '\n%b\n' " ${unicode_blue_light_circle} Usage example: ${color_blue_light}-cd ~/cache_dir rm${color_end}"
			printf '\n%b\n\n' " ${unicode_blue_light_circle} Usage example: ${color_blue_light}-cd ~/cache_dir bs${color_end}"
			exit
			;;
		-h-d | --help-debug)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n\n' " Enable debug symbols for libtorrent and qBittorrent when building - required for gdb backtrace"
			exit
			;;
		-h-n | --help-no-delete)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " Skip all delete functions for selected modules to leave source code directories behind."
			printf '\n%b\n' " ${text_dim}This flag is provided with no arguments.${color_end}"
			printf '\n%b\n\n' " ${color_blue_light}-n${color_end}"
			exit
			;;
		-h-i | --help-icu)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " Use ICU libraries when building qBittorrent. Final binary size will be around ~50Mb"
			printf '\n%b\n' " ${text_dim}This flag is provided with no arguments.${color_end}"
			printf '\n%b\n\n' " ${color_blue_light}-i${color_end}"
			exit
			;;
		-h-m | --help-master)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " Always use the master branch for ${color_green}libtorrent RC_${qbt_libtorrent_version//./_}${color_end}"
			printf '\n%b\n' " Always use the master branch for ${color_green}qBittorrent"
			printf '\n%b\n' " ${text_dim}This flag is provided with no arguments.${color_end}"
			printf '\n%b\n\n' " ${color_blue_light}-lm${color_end}"
			exit
			;;
		-h-ma | --help-multiarch)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " ${unicode_red_circle}${color_red_light} GitHub action and Alpine specific. You probably don't need it${color_end}"
			printf '\n%b\n' " This switch will make the script use the cross build configuration for these supported architectures"
			printf '\n%b\n' " ${unicode_yellow_circle} armhf"
			printf '%b\n' " ${unicode_yellow_circle} armv7"
			printf '%b\n' " ${unicode_yellow_circle} aarch64"
			printf '\n%b\n' "${color_green_light} Usage:${color_end} ${color_cyan_light}${qbt_working_dir_short}/${script_basename}${color_end} ${color_blue_light}-bs-ma ${qbt_cross_name:-aarch64}${color_end}"
			printf '\n%b\n\n' " ${unicode_yellow_circle} You can also set it as a variable to trigger cross building: ${color_blue_light}export qbt_cross_name=${qbt_cross_name:-aarch64}${color_end}"
			exit
			;;
		-h-lm | --help-libtorrent-master)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " Always use the master branch for ${color_green}libtorrent-${qbt_libtorrent_version}${color_end}"
			printf '\n%b\n' " This master that will be used is: ${color_green}RC_${qbt_libtorrent_version//./_}${color_end}"
			printf '\n%b\n' " ${text_dim}This flag is provided with no arguments.${color_end}"
			printf '\n%b\n\n' " ${color_blue_light}-lm${color_end}"
			exit
			;;
		-h-lt | --help-libtorrent-tag)
			if [[ ! ${github_tag[libtorrent]} =~ (error_tag|error_22) ]]; then
				printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
				printf '\n%b\n' " Use a provided libtorrent tag when cloning from github."
				printf '\n%b\n' " ${color_yellow}You can use this flag with this help command to see the value if called before the help option.${color_end}"
				printf '\n%b\n' " ${color_green}${qbt_working_dir_short}/${script_basename}${color_end}${color_blue_light} -lt ${color_cyan_light}${github_tag[libtorrent]}${color_end} ${color_blue_light}-h-lt${color_end}"
				printf '\n%b\n' " ${text_dim}This flag must be provided with arguments.${color_end}"
				printf '\n%b\n' " ${color_blue_light}-lt${color_end} ${color_cyan_light}${github_tag[libtorrent]}${color_end}"
			fi
			printf '\n'
			exit
			;;
		-h-o | --help-optimise)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " ${unicode_yellow_circle} ${color_yellow_light}Warning:${color_end} using this flag will mean your static build is limited to a CPU that matches the host spec"
			printf '\n%b\n' " ${unicode_blue_light_circle} Usage example: ${color_blue_light}-o \"-my -custom --flags\"${color_end}"
			printf '\n%b\n' " Notes:"
			printf '\n%b\n\n' "    ${color_cyan_light}-march=native${color_end} is always passed if this flag is used unless crosscompiling"
			exit
			;;
		-h-p | --help-proxy)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " Specify a proxy URL and PORT to use with curl and git"
			printf '\n%b\n' " ${unicode_blue_light_circle} Usage examples:"
			printf '\n%b\n' " ${color_blue_light}-p${color_end} ${color_cyan_light}username:password@https://123.456.789.321:8443${color_end}"
			printf '\n%b\n' " ${color_blue_light}-p${color_end} ${color_cyan_light}https://proxy.com:12345${color_end}"
			printf '\n%b\n' " ${unicode_yellow_circle} Call this before the help option to see outcome dynamically:"
			printf '\n%b\n\n' " ${color_blue_light}-p${color_end} ${color_cyan_light}https://proxy.com:12345${color_end} ${color_blue_light}-h-p${color_end}"
			[[ -n ${qbt_curl_proxy[*]} ]] && printf '%b\n' " proxy command: ${color_cyan_light}${qbt_curl_proxy[*]}${text_newline}${color_end}"
			exit
			;;
		-h-pr | --help-patch-repo)
			_apply_patches bootstrap-help
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " Specify a username and repo to use patches hosted on GitHub${color_end}"
			printf '\n%b\n' " ${unicode_yellow_circle} ${color_yellow_light}There is a specific GitHub directory format you need to use with this flag${color_end}"
			printf '\n%b\n' " ${color_cyan_light}patches/libtorrent/${app_version[libtorrent]}/patch${color_end}"
			printf '%b\n' " ${color_cyan_light}patches/libtorrent/${app_version[libtorrent]}/Jamfile${color_end} ${color_red_light}(defaults to branch master)${color_end}"
			printf '\n%b\n' " ${color_cyan_light}patches/qbittorrent/${app_version[qbittorrent]}/patch${color_end}"
			printf '\n%b\n' " ${unicode_yellow_circle} ${color_yellow_light}If an installation tag matches a hosted tag patch file, it will be automatically used.${color_end}"
			printf '\n%b\n' " The tag name will always be an abbreviated version of the default or specified tag.${color_end}"
			printf '\n%b\n\n' " ${unicode_blue_light_circle} ${color_green}Usage example:${color_end} ${color_blue_light}-pr username/repo${color_end}"
			exit
			;;
		-h-q | --help-qmake)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " This flag can change the build process in a few ways."
			printf '\n%b\n' " ${unicode_yellow_circle} Use configure scripts to build apps"
			printf '%b\n' " ${unicode_yellow_circle} Use qmake to build qtbase, qttools and qbittorrent."
			printf '\n%b\n\n' " ${unicode_yellow_circle} You can use this flag to build older build combinations that don't use cmake"
			exit
			;;
		-h-qm | --help-qbittorrent-master)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " Always use the master branch for ${color_green}qBittorrent${color_end}"
			printf '\n%b\n' " This master that will be used is: ${color_green}master${color_end}"
			printf '\n%b\n' " ${text_dim}This flag is provided with no arguments.${color_end}"
			printf '\n%b\n\n' " ${color_blue_light}-qm${color_end}"
			exit
			;;
		-h-qt | --help-qbittorrent-tag)
			if [[ ! ${github_tag[qbittorrent]} =~ (error_tag|error_22) ]]; then
				printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
				printf '\n%b\n' " Use a provided qBittorrent tag when cloning from github."
				printf '\n%b\n' " ${color_yellow}You can use this flag with this help command to see the value if called before the help option.${color_end}"
				printf '\n%b\n' " ${color_green}${qbt_working_dir_short}/${script_basename}${color_end}${color_blue_light} -qt ${color_cyan_light}${github_tag[qbittorrent]}${color_end} ${color_blue_light}-h-qt${color_end}"
				printf '\n%b\n' " ${text_dim}This flag must be provided with arguments.${color_end}"
				printf '\n%b\n' " ${color_blue_light}-qt${color_end} ${color_cyan_light}${github_tag[qbittorrent]}${color_end}"
			fi
			printf '\n'
			exit
			;;
		-h-qtt | --help-qt-tag)
			if [[ ! ${github_tag[qtbase]} =~ (error_tag|error_22) ]]; then
				printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
				printf '\n%b\n' " Use a provided Qt tag when cloning from github."
				printf '\n%b\n' " ${color_yellow}You can use this flag with this help command to see the value if called before the help option.${color_end}"
				printf '\n%b\n' " ${color_green}${qbt_working_dir_short}/${script_basename}${color_end}${color_blue_light} -qt ${color_cyan_light}${github_tag[qtbase]}${color_end} ${color_blue_light}-h-qt${color_end}"
				printf '\n%b\n' " ${text_dim}This flag must be provided with arguments.${color_end}"
				printf '\n%b\n' " ${color_blue_light}-qt${color_end} ${color_cyan_light}${github_tag[qtbase]}${color_end}"
			fi
			printf '\n'
			exit
			;;
		-h-s | --help-strip)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " Strip the qbittorrent-nox binary of unneeded symbols to decrease file size"
			printf '\n%b\n' " ${unicode_yellow_circle} Static musl builds don't work with qBittorrent's built-in stacktrace."
			printf '\n%b\n' " If you need to debug a build with gdb you must build a debug build using the flag ${color_blue_light}-d${color_end}"
			printf '\n%b\n' " ${text_dim}This flag is provided with no arguments.${color_end}"
			printf '\n%b\n\n' " ${color_blue_light}-s${color_end}"
			exit
			;;
		-h-si | --help-static-ish)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " Do not statically link libc (glibc/muslc) when building qbittorrent-nox"
			printf '\n%b\n' " ${text_dim}This flag is provided with no arguments.${color_end}"
			printf '\n%b\n\n' " ${color_blue_light}-si${color_end}"
			exit
			;;
		-h-sdu | --help-script-debug-urls)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " ${unicode_blue_light_circle} This will print out all the ${color_yellow_light}_set_module_urls${color_end} array info to check"
			printf '\n%b\n\n' " ${unicode_blue_light_circle} Usage example: ${color_blue_light}-sdu${color_end}"
			exit
			;;
		-h-wf | --help-workflow)
			printf '\n%b\n' " ${unicode_cyan_light_circle} ${text_bold}${text_underlined}Here is the help description for this flag:${color_end}"
			printf '\n%b\n' " ${unicode_yellow_circle} Use archives from ${color_cyan_light}https://github.com/userdocs/qbt-workflow-files/releases/latest${color_end}"
			printf '\n%b\n' " ${unicode_yellow_circle} ${color_yellow_light}Warning:${color_end} If you set a custom version for supported modules it will override and disable workflows as a source for that module"
			printf '\n%b\n\n' " ${unicode_blue_light_circle} Usage example: ${color_blue_light}-wf${color_end}"
			exit
			;;
		--) # end argument parsing
			shift
			break
			;;
		-*) # unsupported flags
			printf '\n%b\n\n' " ${unicode_red_circle} Error: Unsupported flag ${color_red_light}${1}${color_end} - use ${color_green_light}-h${color_end} or ${color_green_light}--help${color_end} to see the valid options${color_end}" >&2
			exit
			;;
		*) # preserve positional arguments
			params2+=("${1}")
			shift
			;;
	esac
done
set -- "${params2[@]}" # Set positional arguments in their proper place.
#######################################################################################################################################################
# Functions part 2: Use some of our functions
#######################################################################################################################################################
[[ ${1} == "install" ]] && _install_qbittorrent "${@}" # see functions
#######################################################################################################################################################
# Lets dip out now if we find that any github tags failed validation or the urls are invalid
#######################################################################################################################################################
_error_tag
#######################################################################################################################################################
# Functions part 3: Any functions that require that params in the above options while loop to have been shifted must come after this line
#######################################################################################################################################################
_set_cxx_standard
_set_build_cons
_debug "${@}"                # requires shifted params from options block 2
_installation_modules "${@}" # requires shifted params from options block 2
#######################################################################################################################################################
# If any modules fail the qbt_modules_test then exit now.
#######################################################################################################################################################
if [[ ${qbt_modules_test} == 'fail' || ${#} -eq '0' ]]; then
	if [[ ${qbt_modules_test} == 'fail' ]]; then
		printf '\n%b\n' " ${text_blink}${unicode_red_circle}${color_end}${text_bold} One or more of the provided modules are not supported${color_end}"
	fi

	printf '\n%b\n' " ${unicode_yellow_circle}${text_bold} Below is a list of supported modules:${color_end}"
	printf '\n%b\n' " ${unicode_magenta_circle}${color_magenta_light} ${qbt_modules_install_processed[*]}${color_end}"
	_print_env
	exit
fi
#######################################################################################################################################################
# Functions part 4: no function past this point will be executed unless a valid module was passed
#######################################################################################################################################################
_multi_arch
_qbt_host_deps
#######################################################################################################################################################
# shellcheck disable=SC2317,SC2329
_glibc_bootstrap() {
	sub_dir="/BUILD"
}
# shellcheck disable=SC2317,SC2329
_glibc() {
	"${qbt_dl_folder_path}/configure" "${multi_glibc[@]}" --prefix="${qbt_install_dir}" --enable-cet --enable-static-nss --disable-nscd --srcdir="${qbt_dl_folder_path}" |& _tee "${qbt_install_dir}/logs/${app_name}.log"
	make -j"$(nproc)" |& _tee -a "${qbt_install_dir}/logs/$app_name.log"
	_post_command build
	make install |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
	make localedata/install-locales SUPPORTED-LOCALES='C.UTF-8/UTF-8' |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
	unset sub_dir
}
#######################################################################################################################################################
# shellcheck disable=SC2317,SC2329
_zlib() {
	if [[ ${qbt_zlib_type} == "zlib" ]]; then
		./configure --prefix="${qbt_install_dir}" --static |& _tee "${qbt_install_dir}/logs/${app_name}.log"
		make -j"$(nproc)" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		_post_command build
		make install |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
	fi

	if [[ ${qbt_zlib_type} == "zlib-ng" ]]; then
		if [[ ${qbt_build_tool} == "cmake" ]]; then
			mkdir -p "${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}"
			cmake -Wno-dev -Wno-deprecated --graphviz="${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}/dep-graph.dot" -G Ninja -B build \
				-D CMAKE_BUILD_TYPE="${qbt_cmake_build_type}" \
				-D CMAKE_VERBOSE_MAKEFILE="${qbt_cmake_debug}" \
				-D CMAKE_CXX_STANDARD="${qbt_standard}" \
				-D CMAKE_PREFIX_PATH="${qbt_install_dir}" \
				-D BUILD_SHARED_LIBS=OFF \
				-D ZLIB_COMPAT=ON \
				-D WITH_GTEST=OFF \
				-D CMAKE_INSTALL_PREFIX="${qbt_install_dir}" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
			cmake --build build |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
			_post_command build
			cmake --install build |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
			dot -Tpng -o "${qbt_install_dir}/completed/${app_name}-graph.png" "${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}/dep-graph.dot"
		else
			./configure --prefix="${qbt_install_dir}" --static --zlib-compat |& _tee "${qbt_install_dir}/logs/${app_name}.log"
			make -j"$(nproc)" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
			_post_command build
			make install |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		fi
	fi
}
#######################################################################################################################################################
# shellcheck disable=SC2317,SC2329
_iconv() {
	if [[ -n ${qbt_cache_dir} && -d "${qbt_cache_dir}/${app_name}" ]]; then
		./gitsub.sh pull --depth 1
		./autogen.sh
	fi

	./configure "${multi_iconv[@]}" --prefix="${qbt_install_dir}" --disable-shared --enable-static |& _tee "${qbt_install_dir}/logs/${app_name}.log"
	make -j"$(nproc)" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
	make install |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
}
#######################################################################################################################################################
# shellcheck disable=SC2317,SC2329
_set_icu_sub_dir() {
	if [[ -n ${qbt_cache_dir} && -d "${qbt_cache_dir}/${app_name}" && ${qbt_workflow_files} == "no" ]]; then
		sub_dir="/icu4c/source"
	else
		sub_dir="/source"
	fi
}
#######################################################################################################################################################
# shellcheck disable=SC2317,SC2329
_icu_host_deps_bootstrap() {
	_set_icu_sub_dir
}
#######################################################################################################################################################
# shellcheck disable=SC2317,SC2329
_icu_host_deps() {
	mkdir -p "${qbt_host_deps_path}"
	_pushd "${qbt_host_deps_path}"
	"${qbt_install_dir}/${app_name/_host_deps/}${sub_dir}/runConfigureICU" Linux --disable-shared --enable-static --disable-samples --disable-tests --with-data-packaging=static |& _tee "${qbt_install_dir}/logs/${app_name}.log"
	make -j"$(nproc)" |& _tee "${qbt_install_dir}/logs/${app_name}.log"
	_post_command build
	_pushd "${qbt_install_dir}/${app_name/_host_deps/}${sub_dir}"
	unset sub_dir
}
#######################################################################################################################################################
# shellcheck disable=SC2317,SC2329
_icu_bootstrap() {
	_set_icu_sub_dir
}
#######################################################################################################################################################
# shellcheck disable=SC2317,SC2329
_icu() {
	./configure "${multi_icu[@]}" --prefix="${qbt_install_dir}" --disable-shared --enable-static --disable-samples --disable-tests --with-data-packaging=static |& _tee "${qbt_install_dir}/logs/${app_name}.log"
	make -j"$(nproc)" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
	_post_command build
	make install |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
	unset sub_dir
}
#######################################################################################################################################################
# shellcheck disable=SC2317,SC2329
_openssl() {
	openssl_config=("threads" "no-shared" "no-dso" "no-docs" "no-async" "no-comp" "no-idea" "no-mdc2" "no-rc5" "no-ec2m" "no-ssl3" "no-seed" "no-weak-ssl-ciphers")
	"${multi_openssl[@]}" --prefix="${qbt_install_dir}" --libdir="${lib_dir##*/}" --openssldir="/etc/ssl" "${qbt_openssl_build_type}" "${openssl_config[@]}" |& _tee "${qbt_install_dir}/logs/${app_name}.log"
	make -j"$(nproc)" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
	_post_command build
	make install_sw |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
}
#######################################################################################################################################################
# shellcheck disable=SC2317,SC2329
_boost_bootstrap() {
	# If using source files and the source fails, default to git, if we are not using workflows sources.
	if [[ ${boost_url_status} =~ (403|404) && ${qbt_workflow_files} == "no" ]]; then
		source_default["${app_name}"]="folder"
	fi
}
#######################################################################################################################################################
# shellcheck disable=SC2317,SC2329
_boost() {
	if [[ ${source_default["${app_name}"]} == "file" ]]; then
		mv -f "${qbt_dl_folder_path}/" "${qbt_install_dir}/boost"
		_pushd "${qbt_install_dir}/boost"
	fi

	if [[ ${qbt_build_tool} != 'cmake' ]]; then
		# no valid to make bootstrap.sh build b2 statically so we do this otherwise it links dynamically a gcc.
		sed -i "s|-o b2|-static --static -o b2|" "${qbt_install_dir}/boost/tools/build/src/engine/build.sh"
		"${qbt_install_dir}/boost/bootstrap.sh" |& _tee "${qbt_install_dir}/logs/${app_name}.log"
		ln -s "${qbt_install_dir}/boost/boost" "${qbt_install_dir}/boost/include"
	else
		printf '\n%b\n' " ${unicode_yellow_circle} Skipping b2 as we are using cmake with Qt6"
	fi

	if [[ ${source_default["${app_name}"]} == "folder" ]]; then
		"${qbt_install_dir}/boost/b2" headers |& _tee "${qbt_install_dir}/logs/${app_name}.log"
	fi
}
#######################################################################################################################################################
# shellcheck disable=SC2317,SC2329
_libtorrent() {
	export BOOST_ROOT="${qbt_install_dir}/boost"
	export BOOST_INCLUDEDIR="${qbt_install_dir}/boost"
	export BOOST_BUILD_PATH="${qbt_install_dir}/boost"

	if [[ ${qbt_build_tool} == 'cmake' ]]; then
		mkdir -p "${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}"
		cmake -Wno-dev -Wno-deprecated --graphviz="${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}/dep-graph.dot" -G Ninja -B build \
			"${multi_libtorrent[@]}" \
			-D CMAKE_VERBOSE_MAKEFILE="${qbt_cmake_debug}" \
			-D CMAKE_BUILD_TYPE="${qbt_cmake_build_type}" \
			-D CMAKE_CXX_STANDARD="${qbt_standard}" \
			-D CMAKE_PREFIX_PATH="${qbt_install_dir};${qbt_install_dir}/boost" \
			-D Boost_NO_BOOST_CMAKE=TRUE \
			-D BUILD_SHARED_LIBS=OFF \
			-D Iconv_LIBRARY="${lib_dir}/libiconv.a" \
			-D CMAKE_INSTALL_PREFIX="${qbt_install_dir}" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		cmake --build build |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		_post_command build
		cmake --install build |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		dot -Tpng -o "${qbt_install_dir}/completed/${app_name}-graph.png" "${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}/dep-graph.dot"
	else
		[[ ${qbt_cross_name} =~ ^(armel|armhf|armv7|powerpc|mips|mipsel)$ ]] && arm_libatomic="-l:libatomic.a"
		# Check the actual version of the cloned libtorrent instead of using the tag so that we can determine RC_1_1, RC_1_2 or RC_2_0 when a custom pr branch was used. This will always give an accurate result.
		libtorrent_version_hpp="$(sed -rn 's|(.*)LIBTORRENT_VERSION "(.*)"|\2|p' include/libtorrent/version.hpp)"
		if [[ ${libtorrent_version_hpp} =~ ^1\.1\. ]]; then
			libtorrent_library_filename="libtorrent.a"
		else
			libtorrent_library_filename="libtorrent-rasterbar.a"
		fi

		if [[ ${libtorrent_version_hpp} =~ ^2\. ]]; then
			lt_version_options=()
			libtorrent_libs="-l:libboost_system.a -l:${libtorrent_library_filename} -l:libtry_signal.a ${arm_libatomic}"
			lt_cmake_flags="-DTORRENT_USE_LIBCRYPTO -DTORRENT_USE_OPENSSL -DTORRENT_USE_I2P=1 -DBOOST_ALL_NO_LIB -DBOOST_ASIO_ENABLE_CANCELIO -DBOOST_ASIO_HAS_STD_CHRONO -DBOOST_MULTI_INDEX_DISABLE_SERIALIZATION -DBOOST_SYSTEM_NO_DEPRECATED -DBOOST_SYSTEM_STATIC_LINK=1 -DTORRENT_SSL_PEERS -DBOOST_ASIO_NO_DEPRECATED"
		else
			lt_version_options=("iconv=on")
			libtorrent_libs="-l:libboost_system.a -l:${libtorrent_library_filename} ${arm_libatomic} -l:libiconv.a"
			lt_cmake_flags="-DTORRENT_USE_LIBCRYPTO -DTORRENT_USE_OPENSSL -DTORRENT_USE_I2P=1 -DBOOST_ALL_NO_LIB -DBOOST_ASIO_ENABLE_CANCELIO -DBOOST_ASIO_HAS_STD_CHRONO -DBOOST_MULTI_INDEX_DISABLE_SERIALIZATION -DBOOST_SYSTEM_NO_DEPRECATED -DBOOST_SYSTEM_STATIC_LINK=1 -DTORRENT_USE_ICONV=1"
		fi

		"${qbt_install_dir}/boost/b2" "${multi_libtorrent[@]}" -j"$(nproc)" "${lt_version_options[@]}" address-model="${bitness:-$(getconf LONG_BIT)}" "${qbt_libtorrent_debug}" optimization=speed cxxstd="${qbt_standard}" dht=on encryption=on crypto=openssl i2p=on extensions=on variant=release threading=multi link=static boost-link=static install --prefix="${qbt_install_dir}" |& _tee "${qbt_install_dir}/logs/${app_name}.log"
		_post_command build
		libtorrent_strings_version="$(strings -d "${lib_dir}/${libtorrent_library_filename}" | grep -Eom1 "^libtorrent/[0-9]\.(.*)")" # ${libtorrent_strings_version#*/}
		cat > "${PKG_CONFIG_PATH}/libtorrent-rasterbar.pc" <<- LIBTORRENT_PKG_CONFIG
			prefix=${qbt_install_dir}
			libdir=\${prefix}/lib
			includedir=\${prefix}/include

			Name: libtorrent-rasterbar
			Description: The libtorrent-rasterbar libraries
			Version: ${libtorrent_strings_version#*/}

			Requires:
			Libs: -L\${libdir} ${libtorrent_libs}
			Cflags: -I\${includedir} -I${BOOST_ROOT} ${lt_cmake_flags}
		LIBTORRENT_PKG_CONFIG
	fi
}
#######################################################################################################################################################
# shellcheck disable=SC2317,SC2329
_double_conversion() {
	if [[ ${qbt_build_tool} == 'cmake' && ${qbt_qt_version} =~ ^6 ]]; then
		mkdir -p "${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}"
		cmake -Wno-dev -Wno-deprecated --graphviz="${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}/dep-graph.dot" -G Ninja -B build \
			"${multi_double_conversion[@]}" \
			-D CMAKE_BUILD_TYPE="${qbt_cmake_build_type}" \
			-D CMAKE_VERBOSE_MAKEFILE="${qbt_cmake_debug}" \
			-D CMAKE_PREFIX_PATH="${qbt_install_dir}" \
			-D CMAKE_INSTALL_LIBDIR=lib \
			-D BUILD_SHARED_LIBS=OFF \
			-D CMAKE_INSTALL_PREFIX="${qbt_install_dir}" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		cmake --build build |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		cmake --install build |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		_post_command build
		dot -Tpng -o "${qbt_install_dir}/completed/${app_name}-graph.png" "${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}/dep-graph.dot"
	fi
}
#######################################################################################################################################################
# shellcheck disable=SC2317,SC2329
_qtbase_host_deps() {
	if [[ ${qbt_build_tool} == 'cmake' && ${qbt_qt_version} =~ ^6 ]]; then
		cmake -Wno-dev -Wno-deprecated -G Ninja -B build \
			-D CMAKE_VERBOSE_MAKEFILE="${qbt_cmake_debug}" \
			-D CMAKE_BUILD_TYPE="${qbt_cmake_build_type}" \
			-D QT_FEATURE_optimize_full=on -D QT_FEATURE_static=on -D QT_FEATURE_shared=off \
			-D QT_FEATURE_gui=off -D QT_FEATURE_openssl_linked=off -D QT_FEATURE_dbus=off -D QT_FEATURE_icu=off \
			-D QT_FEATURE_system_pcre2=off -D QT_FEATURE_system_zlib=off -D QT_FEATURE_widgets=off \
			-D QT_FEATURE_system_doubleconversion=off \
			-D FEATURE_androiddeployqt=OFF -D FEATURE_animation=OFF \
			-D QT_FEATURE_testlib=off -D QT_BUILD_EXAMPLES=off -D QT_BUILD_TESTS=off \
			-D QT_BUILD_EXAMPLES_BY_DEFAULT=OFF -D QT_BUILD_TESTS_BY_DEFAULT=OFF \
			-D CMAKE_CXX_STANDARD="${qbt_standard}" \
			-D BUILD_SHARED_LIBS=OFF \
			-D CMAKE_SKIP_RPATH=on -D CMAKE_SKIP_INSTALL_RPATH=on \
			-D CMAKE_INSTALL_PREFIX="${qbt_host_deps_path}" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		cmake --build build |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		_post_command build
		cmake --install build |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
	fi
}
#######################################################################################################################################################
# shellcheck disable=SC2317,SC2329
_qtbase() {
	cat > "mkspecs/${qbt_cross_qtbase}/qmake.conf" <<- QT_MKSPECS
		MAKEFILE_GENERATOR      = UNIX
		CONFIG                 += incremental
		QMAKE_INCREMENTAL_STYLE = sublib

		include(../common/linux.conf)
	QT_MKSPECS

	if [[ ${qbt_cross_name} =~ ^(x86|x86_64)$ ]]; then
		cat >> "mkspecs/${qbt_cross_qtbase}/qmake.conf" <<- QT_MKSPECS

			QMAKE_CFLAGS            = -m${bitness:-$(getconf LONG_BIT)}
			QMAKE_LFLAGS            = -m${bitness:-$(getconf LONG_BIT)}

		QT_MKSPECS
	fi

	cat >> "mkspecs/${qbt_cross_qtbase}/qmake.conf" <<- QT_MKSPECS
		include(../common/gcc-base-unix.conf)
		include(../common/g++-unix.conf)

		# modifications to g++.conf
		QMAKE_CC                = ${qbt_cross_host}-gcc
		QMAKE_CXX               = ${qbt_cross_host}-g++
		QMAKE_LINK              = ${qbt_cross_host}-g++
		QMAKE_LINK_SHLIB        = ${qbt_cross_host}-g++

		# modifications to linux.conf
		QMAKE_AR                = ${qbt_cross_host}-ar cqs
		QMAKE_OBJCOPY           = ${qbt_cross_host}-objcopy
		QMAKE_NM                = ${qbt_cross_host}-nm -P
		QMAKE_STRIP             = ${qbt_cross_host}-strip

		QMAKE_CFLAGS            = ${CFLAGS}
		QMAKE_CXXFLAGS          = ${CXXFLAGS} -w -fpermissive
		QMAKE_LFLAGS            = ${LDFLAGS}

		load(qt_config)
	QT_MKSPECS

	# force qmake to build and link statically against the cross compiler.
	sed -i '/load(qt_config)/i QMAKE_LFLAGS = -static --static' "mkspecs/linux-g++/qmake.conf"
	[[ ${qbt_cross_name} =~ ^(armel|armhf|armv7|powerpc|mips|mipsel)$ ]] && arm_libatomic="-l:libatomic.a"

	if [[ ${qbt_build_tool} == 'cmake' && ${qbt_qt_version} =~ ^6 ]]; then
		mkdir -p "${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}"
		cmake -Wno-dev -Wno-deprecated --graphviz="${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}/dep-graph.dot" -G Ninja -B build \
			"${multi_qtbase[@]}" \
			-D CMAKE_VERBOSE_MAKEFILE="${qbt_cmake_debug}" \
			-D CMAKE_BUILD_TYPE="${qbt_cmake_build_type}" \
			-D QT_FEATURE_optimize_full=on -D QT_FEATURE_static=on -D QT_FEATURE_shared=off \
			-D QT_FEATURE_gui=off -D QT_FEATURE_openssl_linked=on -D QT_FEATURE_dbus=off \
			-D QT_FEATURE_system_pcre2=off -D QT_FEATURE_widgets=off \
			-D FEATURE_androiddeployqt=OFF -D FEATURE_animation=OFF \
			-D QT_FEATURE_testlib=off -D QT_BUILD_EXAMPLES=off -D QT_BUILD_TESTS=off \
			-D QT_BUILD_EXAMPLES_BY_DEFAULT=OFF -D QT_BUILD_TESTS_BY_DEFAULT=OFF \
			-D CMAKE_CXX_STANDARD="${qbt_standard}" \
			-D CMAKE_PREFIX_PATH="${qbt_install_dir}" \
			-D BUILD_SHARED_LIBS=OFF \
			-D CMAKE_SKIP_RPATH=on -D CMAKE_SKIP_INSTALL_RPATH=on \
			-D CMAKE_INSTALL_PREFIX="${qbt_install_dir}" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		cmake --build build |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		_post_command build
		cmake --install build |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		dot -Tpng -o "${qbt_install_dir}/completed/${app_name}-graph.png" "${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}/dep-graph.dot"
	elif [[ ${qbt_qt_version} =~ ^5 ]]; then
		if [[ ${qbt_skip_icu} == "no" ]]; then
			icu=("-icu" "-no-iconv" "QMAKE_CXXFLAGS+=-w -fpermissive")
		else
			icu=("-no-icu" "-iconv" "QMAKE_CXXFLAGS+=-w -fpermissive")
		fi
		# Fix 5.15.4 to build on gcc 11
		sed '/^#  include <utility>/a #  include <limits>' -i "src/corelib/global/qglobal.h"
		# Don't strip by default by disabling these options. We will set it as off by default and use it with a switch
		printf '%b\n' "CONFIG                 += ${qbt_strip_qmake}" >> "mkspecs/common/linux.conf"

		./configure "${multi_qtbase[@]}" -prefix "${qbt_install_dir}" \
			QMAKE_CFLAGS="${CFLAGS}" QMAKE_CXXFLAGS="${CXXFLAGS}" QMAKE_LFLAGS="${LDFLAGS}" \
			-I "${include_dir}" -L "${lib_dir}" \
			QMAKE_LIBS_OPENSSL="-lssl -lcrypto ${arm_libatomic}" \
			"${icu[@]}" -opensource -confirm-license -release \
			-openssl-linked -static -c++std "${qbt_cxx_standard}" -qt-pcre \
			-no-feature-glib -no-feature-opengl -no-feature-dbus -no-feature-gui -no-feature-widgets -no-feature-testlib -no-compile-examples \
			-skip tests -nomake tests -skip examples -nomake examples |& _tee "${qbt_install_dir}/logs/${app_name}.log"
		make -j"$(nproc)" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		_post_command build
		make install |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
	else
		printf '\n%b\n' " ${unicode_red_circle} Please use a correct qt and build tool combination"
		printf '\n%b\n\n' " ${unicode_green_circle} qt5 + qmake ${unicode_green_circle} qt6 + cmake ${unicode_red_circle} qt5 + cmake ${unicode_red_circle} qt6 + qmake"
		exit
	fi
}
#######################################################################################################################################################
# shellcheck disable=SC2317,SC2329
_qttools_host_deps() {
	cmake -Wno-dev -Wno-deprecated -G Ninja -B build \
		-D CMAKE_VERBOSE_MAKEFILE="${qbt_cmake_debug}" \
		-D CMAKE_BUILD_TYPE="${qbt_cmake_build_type}" \
		-D CMAKE_CXX_STANDARD="${qbt_standard}" \
		-D CMAKE_PREFIX_PATH="${qbt_host_deps_path}" \
		-D BUILD_SHARED_LIBS=OFF \
		-D CMAKE_SKIP_RPATH=on -D CMAKE_SKIP_INSTALL_RPATH=on \
		-D CMAKE_INSTALL_PREFIX="${qbt_host_deps_path}" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
	cmake --build build |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
	_post_command build
	cmake --install build |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
}
#######################################################################################################################################################
# shellcheck disable=SC2317,SC2329
_qttools() {
	if [[ ${qbt_build_tool} == 'cmake' && ${qbt_qt_version} =~ ^6 ]]; then
		mkdir -p "${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}"
		cmake -Wno-dev -Wno-deprecated --graphviz="${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}/dep-graph.dot" -G Ninja -B build \
			"${multi_qttools[@]}" \
			-D CMAKE_VERBOSE_MAKEFILE="${qbt_cmake_debug}" \
			-D CMAKE_BUILD_TYPE="${qbt_cmake_build_type}" \
			-D CMAKE_CXX_STANDARD="${qbt_standard}" \
			-D CMAKE_PREFIX_PATH="${qbt_install_dir}" \
			-D BUILD_SHARED_LIBS=OFF \
			-D CMAKE_SKIP_RPATH=on -D CMAKE_SKIP_INSTALL_RPATH=on \
			-D CMAKE_INSTALL_PREFIX="${qbt_install_dir}" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		cmake --build build |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		_post_command build
		cmake --install build |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		dot -Tpng -o "${qbt_install_dir}/completed/${app_name}-graph.png" "${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}/dep-graph.dot"
	elif [[ ${qbt_qt_version} =~ ^5 ]]; then
		"${qbt_install_dir}/bin/qmake" -set prefix "${qbt_install_dir}" |& _tee "${qbt_install_dir}/logs/${app_name}.log"
		"${qbt_install_dir}/bin/qmake" QMAKE_CXXFLAGS="-std=${qbt_cxx_standard} -static -w -fpermissive" QMAKE_LFLAGS="-static" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		make -j"$(nproc)" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		_post_command build
		make install |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
	else
		printf '\n%b\n' " ${unicode_red_circle} Please use a correct qt and build tool combination"
		printf '\n%b\n\n' " ${unicode_green_circle} qt5 + qmake ${unicode_green_circle} qt6 + cmake ${unicode_red_circle} qt5 + cmake ${unicode_red_circle} qt6 + qmake"
		exit
	fi
}
#######################################################################################################################################################
# shellcheck disable=SC2317,SC2329
_qbittorrent() {
	[[ ${os_id} =~ ^(alpine)$ ]] && stacktrace="OFF"

	if [[ ${qbt_build_tool} == 'cmake' ]]; then
		mkdir -p "${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}"
		cmake -Wno-dev -Wno-deprecated --graphviz="${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}/dep-graph.dot" -G Ninja -B build \
			"${multi_qbittorrent[@]}" \
			-D CMAKE_VERBOSE_MAKEFILE="${qbt_cmake_debug}" \
			-D CMAKE_BUILD_TYPE="${qbt_cmake_build_type}" \
			-D QT6="${qbt_use_qt6}" \
			-D STACKTRACE="${stacktrace:-ON}" \
			-D CMAKE_CXX_STANDARD="${qbt_standard}" \
			-D CMAKE_PREFIX_PATH="${qbt_install_dir};${qbt_install_dir}/boost" \
			-D Boost_NO_BOOST_CMAKE=TRUE \
			-D Iconv_LIBRARY="${lib_dir}/libiconv.a" \
			-D GUI=OFF \
			-D CMAKE_INSTALL_PREFIX="${qbt_install_dir}" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"

		cmake --build build |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		_post_command build
		cmake --install build |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		dot -Tpng -o "${qbt_install_dir}/completed/${app_name}-graph.png" "${qbt_install_dir}/graphs/${app_name}/${app_version["${app_name}"]}/dep-graph.dot"
	else
		./bootstrap.sh |& _tee "${qbt_install_dir}/logs/${app_name}.log"
		./configure \
			QT_QMAKE="${qbt_install_dir}/bin" \
			--prefix="${qbt_install_dir}" \
			"${multi_qbittorrent[@]}" \
			"${qbt_qbittorrent_debug}" \
			--disable-gui \
			--with-boost="${qbt_install_dir}/boost" --with-boost-libdir="${lib_dir}" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		make -j"$(nproc)" |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
		_post_command build
		make install |& _tee -a "${qbt_install_dir}/logs/${app_name}.log"
	fi

	[[ -f "${qbt_install_dir}/bin/qbittorrent-nox" ]] && cp -f "${qbt_install_dir}/bin/qbittorrent-nox" "${qbt_install_dir}/completed/qbittorrent-nox"
}
#######################################################################################################################################################
# A module installer loop. This will loop through the activated modules and install them via their corresponding functions
#######################################################################################################################################################
for app_name in "${qbt_modules_install_processed[@]}"; do
	if [[ ${qbt_cache_dir_options} != "bs" ]] && [[ ! -d "${qbt_install_dir}/boost" && ${app_name} =~ (libtorrent|qbittorrent) ]]; then
		printf '\n%b\n\n' " ${unicode_red_circle}${color_red_light} Warning${color_end} This module depends on the boost module. Use them together: ${color_magenta_light}boost ${app_name}${color_end}"
	else
		if [[ ${skip_modules["${app_name}"]} == "no" ]]; then
			############################################################
			skipped_false=$((skipped_false + 1))
			############################################################
			if command -v "_${app_name}_bootstrap" &> /dev/null; then
				"_${app_name}_bootstrap"
			fi
			########################################################
			_custom_flags
			############################################################
			_download
			############################################################
			[[ ${qbt_cache_dir_options} == "bs" && ${skipped_false} -eq ${#qbt_modules_install_processed[@]} ]] && printf '\n'
			[[ ${qbt_cache_dir_options} == "bs" ]] && continue
			############################################################
			_apply_patches
			############################################################
			"_${app_name}"
			############################################################
			_fix_static_links
			[[ ${app_name} != "boost" ]] && _delete_function
		fi

		if [[ ${#qbt_modules_selected_compare[@]} -gt '0' ]]; then
			printf '\n'
			printf '%b' " ${unicode_magenta_light_circle} ${color_cyan_light}Activated modules:${color_end}"
			for activated_modules in "${!qbt_modules_selected_compare[@]}"; do
				if [[ ${qbt_activated_modules[${qbt_modules_selected_compare[$activated_modules]}]} == "yes" ]]; then
					printf '%b' " ${color_magenta_light}${qbt_modules_selected_compare[$activated_modules]}${color_end}"
				else
					printf '%b' " ${text_dim}${qbt_modules_selected_compare[$activated_modules]}${color_end}"
				fi
			done
			printf '\n'
		fi

		[[ ${skipped_false} -eq ${#qbt_modules_install_processed[@]} ]] && printf '\n'
	fi
	_pushd "${qbt_working_dir}"
done
#######################################################################################################################################################
# We are all done so now exit
#######################################################################################################################################################
exit
