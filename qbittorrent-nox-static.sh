#! /usr/bin/env bash
#
# Copyright 2020 by userdocs and contributors
#
# SPDX-License-Identifier: Apache-2.0
#
# @author - userdocs
#
# @contributors IceCodeNew
#
# @credits - https://gist.github.com/notsure2
#
# shellcheck disable=SC2034,SC1091 # Why are these checks excluded?
#
# https://github.com/koalaman/shellcheck/wiki/SC2034 There a quite a few variables defined by combining other variables that mean nothing on their own. This behavior is intentional and the warning can be skipped.
#
# https://github.com/koalaman/shellcheck/wiki/SC1091 I am sourcing /etc/os-release for some variables. It's not available to shellcheck to source and it's a safe file so we can skip this
#
# Script Formatting - https://marketplace.visualstudio.com/items?itemName=foxundermoon.shell-format
#
#####################################################################################################################################################
# Set some script features - https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
#####################################################################################################################################################
set -a
#####################################################################################################################################################
# Unset some variables to set defaults.
#####################################################################################################################################################
unset PARAMS qb_skip_delete qb_skip_icu qb_git_proxy qb_curl_proxy qb_install_dir qb_build_dir qb_working_dir qb_modules_test qb_python_version
#####################################################################################################################################################
# Color me up Scotty - define some color values to use as variables in the scripts.
#####################################################################################################################################################
cr="\e[31m" && clr="\e[91m" # [c]olor[r]ed     && [c]olor[l]ight[r]ed
cg="\e[32m" && clg="\e[92m" # [c]olor[g]reen   && [c]olor[l]ight[g]reen
cy="\e[33m" && cly="\e[93m" # [c]olor[y]ellow  && [c]olor[l]ight[y]ellow
cb="\e[34m" && clb="\e[94m" # [c]olor[b]lue    && [c]olor[l]ight[b]lue
cm="\e[35m" && clm="\e[95m" # [c]olor[m]agenta && [c]olor[l]ight[m]agenta
cc="\e[36m" && clc="\e[96m" # [c]olor[c]yan    && [c]olor[l]ight[c]yan
#
tb="\e[1m" && td="\e[2m" && tu="\e[4m" && tn="\n" # [t]ext[b]old && [t]ext[d]im && [t]ext[u]nderlined && [t]ext[n]ewline
#
cdef="\e[39m" # [c]olor[default]
cend="\e[0m"  # [c]olor[end]
#####################################################################################################################################################
# CHeck we are on a supported OS and release.
#####################################################################################################################################################
what_id="$(source /etc/os-release && printf "%s" "${ID}")" # an easy and consistent way to get our os info.
what_version_codename="$(source /etc/os-release && printf "%s" "${VERSION_CODENAME}")"
what_version_id="$(source /etc/os-release && printf "%s" "${VERSION_ID}")"
[[ "${what_id}" =~ ^(alpine)$ ]] && {
	what_version_codename="alpine"
} # add apline to codename check to just be consistent.
#
if [[ ! "${what_version_codename}" =~ ^(alpine|stretch|buster|bullseye|bionic|focal|groovy|hirsute)$ ]] || [[ "${what_version_codename}" =~ ^(alpine)$ && "${what_version_id//\./}" -lt "3100" ]]; then
	echo
	echo -e " ${cly}This is not a supported OS. There is no reason to continue.${cend}"
	echo
	echo -e " id: ${td}${cly}${what_id}${cend} codename: ${td}${cly}${what_version_codename}${cend} version: ${td}${clr}${what_version_id}${cend}"
	echo
	echo -e " ${td}These are the supported platforms${cend}"
	echo
	echo -e " ${clm}Debian${cend} - ${clb}stretch${cend} - ${clb}buster${cend} - ${clb}bullseye${cend}"
	echo
	echo -e " ${clm}Ubuntu${cend} - ${clb}bionic${cend} - ${clb}focal${cend} -${clb} groovy${cend} - ${clb}hirsute${cend}"
	echo
	echo -e " ${clm}Alpine${cend} - ${clb}3.10.0${cend} or greater"
	echo
	exit
fi
#####################################################################################################################################################
# This function sets some default values we use but whose values can be overridden by certain flags
#####################################################################################################################################################
set_default_values() {
	DEBIAN_FRONTEND="noninteractive" TZ="Europe/London" # For docker deploys to not get prompted to set the timezone.
	#
	[[ "${what_id}" = 'alpine' ]] && delete=("bison" "gawk" "glibc") # remove modules when used on alpine.
	#
	[[ "${1}" != 'install' ]] && delete+=("install") # remove this module by default unless provided as a first argument to the script.
	#
	[[ "${qb_skip_icu}" != 'no' ]] && delete+=("icu")
	#
	qb_modules=("all" "install" "bison" "gawk" "glibc" "zlib" "icu" "openssl" "boost" "qtbase" "qttools" "libtorrent" "qbittorrent") # Define our list of available modules in an array.
	#
	libtorrent_version='1.2' # Set this here so it is easy to see and change
	#
	qb_python_version="3" # we are only using python3 but it's easier to just change this if we need to.
	#
	qb_working_dir="$(printf "%s" "$(pwd <(dirname "${0}"))")" # Get the full path to the scripts location to use with setting some path related variables.
	qb_working_dir_short="${qb_working_dir/$HOME/\~}"          # echo the working dir but replace the $HOME path with ~
	#
	qb_install_dir="${qb_working_dir}/qbittorrent-build" # install relative to the script location.
	qb_install_dir_short="${qb_install_dir/$HOME/\~}"    # echo the install dir but replace the $HOME path with ~
}
#####################################################################################################################################################
# This function will check for a list of defined dependencies from the qb_required_pkgs array. Apps like python3 and python2 are dynamically set
#####################################################################################################################################################
check_dependencies() {
	#
	## Define our ALpine list of required core packages in an array.
	[[ "${what_id}" =~ ^(alpine)$ ]] && qb_required_pkgs=("bash" "bash-completion" "build-base" "curl" "pkgconf" "autoconf" "automake" "libtool" "git" "perl" "python${qb_python_version}" "python${qb_python_version}-dev" "py${qb_python_version}-numpy" "linux-headers")
	#
	## Define our Debian/Ubuntu list of required core packages in an array.
	[[ "${what_id}" =~ ^(debian|ubuntu)$ ]] && qb_required_pkgs=("build-essential" "curl" "pkg-config" "automake" "libtool" "git" "perl" "python${qb_python_version}" "python${qb_python_version}-dev" "python${qb_python_version}-numpy")
	#
	echo -e "${tn}${tb}Checking if required core dependencies are installed${cend}${tn}"
	#
	for pkg in "${qb_required_pkgs[@]}"; do
		#
		[[ "${what_id}" =~ ^(alpine)$ ]] && pkgman() { apk info -e "${pkg}"; }
		#
		[[ "${what_id}" =~ ^(debian|ubuntu)$ ]] && pkgman() { dpkg -s "${pkg}"; }
		#
		if pkgman > /dev/null 2>&1; then
			echo -e "Dependency - ${cg}OK${cend} - ${pkg}"
		else
			if [[ -n "${pkg}" ]]; then
				deps_installed='no'
				echo -e "Dependency - ${cr}NO${cend} - ${pkg}"
				qb_checked_required_pkgs+=("$pkg")
			fi
		fi
	done
	#
	## Check if user is able to install the dependencies, if yes then do so, if no then exit.
	if [[ "${deps_installed}" = 'no' ]]; then
		if [[ "$(id -un)" = 'root' ]]; then
			#
			echo -e "${tn}${cg}Updating${cend}${tn}"
			#
			[[ "${what_id}" =~ ^(alpine)$ ]] && CDN_URL="http://dl-cdn.alpinelinux.org/alpine/latest-stable/main"
			#
			set +e
			#
			[[ "${what_id}" =~ ^(alpine)$ ]] && apk update --repository="${CDN_URL}"
			[[ "${what_id}" =~ ^(alpine)$ ]] && apk upgrade --repository="${CDN_URL}"
			[[ "${what_id}" =~ ^(alpine)$ ]] && apk fix
			#
			[[ "${what_id}" =~ ^(debian|ubuntu)$ ]] && apt-get update -y
			[[ "${what_id}" =~ ^(debian|ubuntu)$ ]] && apt-get upgrade -y
			[[ "${what_id}" =~ ^(debian|ubuntu)$ ]] && apt-get autoremove -y
			#
			set -e
			#
			[[ -f /var/run/reboot-required ]] && {
				echo -e "${tn}${cr}This machine requires a reboot to continue installation. Please reboot now.${cend}${tn}"
				exit
			}
			#
			echo -e "${tn}${cg}Installing required dependencies${cend}${tn}"
			#
			[[ "${what_id}" =~ ^(debian|ubuntu)$ ]] && apt-get install -y "${qb_checked_required_pkgs[@]}"
			#
			[[ "${what_id}" =~ ^(alpine)$ ]] && apk add "${qb_checked_required_pkgs[@]}" --repository="${CDN_URL}"
			#
			echo -e "${tn}${cg}Dependencies installed!${cend}"
			#
			deps_installed='yes'
			#
		else
			echo -e "${tn}${tb}Please request or install the missing core dependencies before using this script${cend}"
			#
			echo -e "${tn}apk add ${qb_checked_required_pkgs[*]}${tn}"
			#
			exit
		fi
	fi
	#
	## All checks passed echo
	if [[ "${deps_installed}" != 'no' ]]; then
		echo -e "${tn}${tb}All checks - ${cg}OK${cend}${tb} - core dependencies are installed, continuing to build${cend}"
	fi
}
#####################################################################################################################################################
# 1: curl and git http/https proxy detection use -p username:pass@URL:PORT or -p URL:PORT
#####################################################################################################################################################
while (("${#}")); do
	case "${1}" in
		-b | --build-directory)
			qb_build_dir="${2}"
			shift 2
			;;
		-p | --proxy)
			qb_git_proxy="${2}"
			qb_curl_proxy="${2}"
			shift 2
			;;
		-h-p | --help-proxy)
			echo
			echo -e "${tb}${tu}Here is the help description for this flag:${cend}"
			echo
			echo -e " Specify a proxy URL and PORT to use with curl and git"
			echo
			echo -e " ${td}Example:${cend} ${td}${clb}-p${cend} ${td}${clc}username:password@https://123.456.789.321:8443${cend}"
			echo
			echo -e " ${td}${clb}-p${cend} ${td}${clc}https://proxy.com:12345${cend}"
			echo
			echo -e " ${cy}You can use this flag with this help command to see the value if called before the help option:${cend}"
			echo
			echo -e " ${td}${clb}-p${cend} ${td}${clc}https://proxy.com:12345${cend} ${td}${clb}-h-p${cend}"
			echo
			[[ -n "${qb_curl_proxy}" ]] && echo -e " proxy command: ${clc}${qb_curl_proxy}${tn}${cend}"
			exit 1
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
#
eval set -- "${params1[@]}" # Set positional arguments in their proper place.
#####################################################################################################################################################
# 2:  curl test download functions - default is no proxy - curl is a test function and curl_curl is the command function
#####################################################################################################################################################
curl_curl() {
	if [[ -z "${qb_curl_proxy}" ]]; then
		"$(type -P curl)" -sNL4fq --connect-timeout 5 --retry 5 --retry-delay 5 --retry-max-time 25 "${@}"
	else
		"$(type -P curl)" -sNL4fq --connect-timeout 5 --retry 5 --retry-delay 5 --retry-max-time 25 --proxy-insecure -x "${qb_curl_proxy}" "${@}"
	fi
}
#
curl() {
	if [[ "$(
		curl_curl "${@}" > /dev/null
		echo "$?"
	)" =~ ^(28|7)$ ]]; then
		echo -e "${cy}There is an issue with your proxy settings or network connection${cend}"
		echo
		exit
	else
		curl_curl "${@}"
	fi
}
#####################################################################################################################################################
# 3: git test download functions - default is no proxy - git is a test function and git_git is the command function
#####################################################################################################################################################
git_git() {
	if [[ -z "${qb_git_proxy}" ]]; then
		"$(type -P git)" "${@}"
	else
		"$(type -P git)" -c http.sslVerify=false -c http.https://github.com.proxy="${qb_git_proxy}" "${@}"
	fi
}
#
git() {
	if [[ "${2}" = '-t' ]]; then
		url_test="${1}"
		tag_flag="${2}"
		tag_test="${3}"
	else
		url_test="${11}" # 11th place in our download filder function.
	fi
	#
	status="$(
		git_git ls-remote --exit-code "${url_test}" "${tag_flag}" "${tag_test}" > /dev/null 2>&1
		echo "${?}"
	)"
	#
	if [[ "$status" = '128' ]]; then
		echo "error_url"
	elif [[ "${tag_flag}" = '-t' && "${status}" = '0' ]]; then
		echo "${tag_test}"
	elif [[ "${tag_flag}" = '-t' && "${status}" -eq '2' ]]; then
		echo "error_tag"
	else
		git_git "${@}"
	fi
}
#
test_git_ouput() {
	if [[ "${1}" = "error_tag" ]]; then
		echo -e "${tn} ${cy}Sorry, the provided ${3} tag ${cr}$2${cend}${cy} is not valid${cend}"
	elif [[ "${1}" = "error_url" ]]; then
		echo
		echo -e " ${cy}There is an issue with your proxy settings or network connection${cend}"
		echo
		exit
	fi
}
#####################################################################################################################################################
# This function sets the build and installation directory. If the argument -b is used to set a build directory that directory is set and used.
# If nothing is specified or the switch is not used it defaults to the hard-coded path relative to the scripts location - qbittorrent-build
#####################################################################################################################################################
set_build_directory() {
	if [[ -n "${qb_build_dir}" ]]; then
		if [[ "${qb_build_dir}" =~ ^/ ]]; then
			qb_install_dir="${qb_build_dir}"
			qb_install_dir_short="${qb_install_dir/$HOME/\~}"
		else
			qb_install_dir="${qb_working_dir}/${qb_build_dir}"
			qb_install_dir_short="${qb_working_dir_short}/${qb_build_dir}"
		fi
	fi
	#
	## Set lib and include directory paths based on install path.
	include_dir="${qb_install_dir}/include"
	lib_dir="${qb_install_dir}/lib"
	#
	## Define some build specific variables
	PATH="${qb_install_dir}/bin:${HOME}/bin${PATH:+:${PATH}}"
	LD_LIBRARY_PATH="-L${lib_dir}"
	PKG_CONFIG_PATH="-L${lib_dir}/pkgconfig"
	local_boost="--with-boost=${qb_install_dir}"
	local_openssl="--with-openssl=${qb_install_dir}"
}
#####################################################################################################################################################
# This function sets some compiler flags globally - b2 settings are set in the ~/user-config.jam  set in the installation_modules function
#####################################################################################################################################################
custom_flags_set() {
	CXXFLAGS="-std=c++14"
	CPPFLAGS="--static -static -I${include_dir}"
	LDFLAGS="--static -static -Wl,--no-as-needed -L${lib_dir} -lpthread -pthread"
}
#
custom_flags_reset() {
	CXXFLAGS="-std=c++14"
	CPPFLAGS=""
	LDFLAGS=""
}
#####################################################################################################################################################
# This function is where we set your URL that we use with other functions.
#####################################################################################################################################################
set_module_urls() {
	bison_url="http://ftpmirror.gnu.org/gnu/bison/$(grep -Eo 'bison-([0-9]{1,3}[.]?)([0-9]{1,3}[.]?)([0-9]{1,3}?)\.tar.gz' <(curl http://ftpmirror.gnu.org/gnu/bison/) | sort -V | tail -1)"
	#
	gawk_url="http://ftpmirror.gnu.org/gnu/gawk/$(grep -Eo 'gawk-([0-9]{1,3}[.]?)([0-9]{1,3}[.]?)([0-9]{1,3}?)\.tar.gz' <(curl http://ftpmirror.gnu.org/gnu/gawk/) | sort -V | tail -1)"
	#
	# glibc_url="http://ftpmirror.gnu.org/gnu/libc/$(grep -Eo 'glibc-([0-9]{1,3}[.]?)([0-9]{1,3}[.]?)([0-9]{1,3}?)\.tar.gz' <(curl http://ftpmirror.gnu.org/gnu/libc/) | sort -V | tail -1)"
	glibc_url="http://ftpmirror.gnu.org/gnu/libc/glibc-2.31.tar.gz"
	#
	zlib_github_tag="$(grep -Eom1 'v1.2.([0-9]{1,2})' <(curl https://github.com/madler/zlib/releases))" || zlib_github_tag="null_value"
	zlib_url="https://github.com/madler/zlib/archive/${zlib_github_tag}.tar.gz"
	#
	icu_url="$(grep -Eom1 'ht(.*)icu4c(.*)-src.tgz' <(curl https://api.github.com/repos/unicode-org/icu/releases/latest))" || icu_url="null_value"
	#
	openssl_github_tag="$(grep -Eom1 'OpenSSL_1_1_([0-9][a-z])' <(curl "https://github.com/openssl/openssl/releases"))" || openssl_github_tag="null_value"
	openssl_url="https://github.com/openssl/openssl/archive/${openssl_github_tag}.tar.gz"
	#
	boost_version="$(sed -rn 's#(.*)e">Version (.*\.[0-9]{1,2})</s(.*)#\2#p' <(curl "https://www.boost.org/users/download/"))"
	boost_github_tag="boost-${boost_version}"
	boost_url="https://dl.bintray.com/boostorg/release/${boost_version}/source/boost_${boost_version//./_}.tar.gz"
	boost_url_status="$(curl -o /dev/null --silent --head --write-out '%{http_code}' "https://dl.bintray.com/boostorg/release/${boost_version}/source/boost_${boost_version//./_}.tar.gz")" || boost_url_status="null_value"
	boost_github_url="https://github.com/boostorg/boost.git"
	#
	qt_version='5.15'
	qtbase_github_tag="$(grep -Eom1 "v${qt_version}.([0-9]{1,2})" <(curl "https://github.com/qt/qtbase/releases"))" || qtbase_github_tag="null_value"
	qtbase_github_url="https://github.com/qt/qtbase.git"
	qttools_github_tag="$(grep -Eom1 "v${qt_version}.([0-9]{1,2})" <(curl "https://github.com/qt/qttools/releases"))" || qttools_github_tag="null_value"
	qttools_github_url="https://github.com/qt/qttools.git"
	#
	libtorrent_github_url="https://github.com/arvidn/libtorrent.git"
	libtorrent_github_tag_default="$(grep -Eom1 "v${libtorrent_version}.([0-9]{1,2})" <(curl "https://github.com/arvidn/libtorrent/tags"))" || libtorrent_github_tag_default="null_value"
	libtorrent_github_tag="${libtorrent_github_tag:-$libtorrent_github_tag_default}"
	#
	qbittorrent_github_url="https://github.com/qbittorrent/qBittorrent.git"
	qbittorrent_github_tag_default="$(grep -Eom1 'release-([0-9]{1,4}\.?)+$' <(curl "https://github.com/qbittorrent/qBittorrent/tags"))" || qbittorrent_github_tag_default="null_value"
	qbittorrent_github_tag="${qbitorrent_github_tag:-$qbittorrent_github_tag_default}"
}
#####################################################################################################################################################
# This function verifies the module names from the array qb_modules in the default values function.
#####################################################################################################################################################
installation_modules() {
	params_count="${#}"
	params_test=1
	#
	## remove modules from the delete array from the qb_modules array
	for target in "${delete[@]}"; do
		for i in "${!qb_modules[@]}"; do
			if [[ "${qb_modules[i]}" = "${target}" ]]; then
				unset 'qb_modules[i]'
			fi
		done
	done
	#
	while [[ "${params_test}" -le "${params_count}" && "${params_count}" -gt '1' ]]; do
		if [[ "${qb_modules[*]}" =~ ${*:$params_test:1} ]]; then
			:
		else
			qb_modules_test="fail"
		fi
		params_test="$((params_test + 1))"
	done
	#
	if [[ "${params_count}" -le '1' ]]; then
		if [[ "${qb_modules[*]}" =~ ${*:$params_test:1} && -n "${*:$params_test:1}" ]]; then
			:
		else
			qb_modules_test="fail"
		fi
	fi
	#
	## Activate all validated modules for installation and define some core variables.
	if [[ "${qb_modules_test}" != 'fail' ]]; then
		if [[ "${*}" =~ ([[:space:]]|^)"all"([[:space:]]|$) ]]; then
			for module in "${qb_modules[@]}"; do
				eval "skip_${module}=no"
			done
		else
			for module in "${@}"; do
				eval "skip_${module}=no"
			done
		fi
		#
		## Create the directories we need.
		mkdir -p "${qb_install_dir}/logs"
		mkdir -p "${qb_install_dir}/completed"
		#
		## Set some python variables we need.
		python_major="$(python${qb_python_version} -c "import sys; print(sys.version_info[0])")"
		python_minor="$(python${qb_python_version} -c "import sys; print(sys.version_info[1])")"
		python_micro="$(python${qb_python_version} -c "import sys; print(sys.version_info[2])")"
		#
		python_short_version="${python_major}.${python_minor}"
		python_link_version="${python_major}${python_minor}"
		#
		echo -e "using gcc : : : <cxxflags>-std=c++14 ;${tn}using python : ${python_short_version} : /usr/bin/python${python_short_version} : /usr/include/python${python_short_version} : /usr/lib/python${python_short_version} ;" > "$HOME/user-config.jam"
		#
		## Echo the build directory.
		echo -e "${tn}${tb}Install Prefix${cend} : ${clc}${qb_install_dir_short}${cend}"
		#
		## Some basic help
		echo -e "${tn}${tb}Script help${cend} : ${clc}${qb_working_dir_short}/$(basename -- "$0")${cend} ${clb}-h${cend}"
	else
		echo -e "${cr}${tn}One or more of the provided modules are not supported${cend}"
		echo -e "${tb}${tn}This is a list of supported modules${cend}"
		echo -e "${clm}${tn}${qb_modules[*]}${tn}${cend}"
		exit
	fi
}
#####################################################################################################################################################
# This function will test to see if a Jamfile patch file exists via the variable patches_github_url for the tag used.
#####################################################################################################################################################
apply_patches() {
	[[ -d "$qb_install_dir/patches" ]] && rm -rf "$qb_install_dir/patches"
	#
	[[ "$libtorrent_github_tag" =~ ^(libtorrent-1_1_[0-9]{1,2}|RC_1_1) ]] && libtorrent_patch_github_tag="RC_1_1"
	[[ "$libtorrent_github_tag" =~ ^(libtorrent-1_2_[0-9]{1,2}|RC_1_2|v1.2\.[0-9]{1,2})$ ]] && libtorrent_patch_github_tag="RC_1_2"
	[[ "$libtorrent_github_tag" =~ ^(RC_2_0|v2\.[0-9](\.[0-9]{1,2})?)$ ]] && libtorrent_patch_github_tag="RC_2_0"
	#
	patches_github_url="https://raw.githubusercontent.com/userdocs/python-libtorrent-binding/master/patches/$libtorrent_patch_github_tag/Jamfile"
	#
	if [[ "$(
		curl "$patches_github_url" > /dev/null
		echo "$?"
	)" -ne '22' ]]; then
		curl "$patches_github_url" -o "$qb_install_dir/libtorrent/bindings/python/Jamfile"
	else
		curl "https://raw.githubusercontent.com/arvidn/libtorrent/$libtorrent_patch_github_tag/Jamfile" -o "$qb_install_dir/libtorrent/Jamfile"
	fi
}
#####################################################################################################################################################
# This function installs qt
#####################################################################################################################################################
install_qbittorrent() {
	if [[ -f "${qb_install_dir}/completed/qbittorrent-nox" ]]; then
		#
		if [[ "$(id -un)" = 'root' ]]; then
			mkdir -p "/usr/local/bin"
			cp -rf "${qb_install_dir}/completed/qbittorrent-nox" "/usr/local/bin"
		else
			mkdir -p "${HOME}/bin"
			cp -rf "${qb_install_dir}/completed/qbittorrent-nox" "${HOME}/bin"
		fi
		#
		echo -e "${tn}qbittorrent-nox has been installed!${tn}"
		echo -e "Run it using this command:${tn}"
		#
		[[ "$(id -un)" = 'root' ]] && echo -e "${cg}qbittorrent-nox${cend}${tn}" || echo -e "${cg}~/bin/qbittorrent-nox${cend}${tn}"
		#
		exit
	else
		echo -e "${tn}qbittorrent-nox has not been built to the defined install directory:${tn}"
		echo -e "${cg}${qb_install_dir_short}/completed${cend}${tn}"
		echo -e "Please build it using the script first then install${tn}"
		#
		exit
	fi
}
#####################################################################################################################################################
# This function is for downloading source code archives
#####################################################################################################################################################
download_file() {
	if [[ -n "${1}" ]]; then
		url_filename="${2}"
		[[ -n "${3}" ]] && subdir="/${3}" || subdir=""
		echo -e "${tn}${cg}Installing $1${cend}${tn}"
		file_name="${qb_install_dir}/${1}.tar.gz"
		[[ -f "${file_name}" ]] && rm -rf {"${qb_install_dir:?}/$(tar tf "${file_name}" | grep -Eom1 "(.*)[^/]")","${file_name}"}
		curl "${url_filename}" -o "${file_name}"
		tar xf "${file_name}" -C "${qb_install_dir}"
		mkdir -p "${qb_install_dir}/$(tar tf "${file_name}" | head -1 | cut -f1 -d"/")${subdir}"
		cd "${qb_install_dir}/$(tar tf "${file_name}" | head -1 | cut -f1 -d"/")${subdir}"
	else
		echo
		echo "You must provide a filename name for the function - download_file"
		echo "It creates the name from the appname_github_tag variable set in the URL section"
		echo
		echo "download_file filename url"
		echo
		exit
	fi
}
#####################################################################################################################################################
# This function is for downloading git releases based on their tag.
#####################################################################################################################################################
download_folder() {
	if [[ -n "${1}" ]]; then
		github_tag="${1}_github_tag"
		url_github="${2}"
		[[ -n "${3}" ]] && subdir="/${3}" || subdir=""
		echo -e "${tn}${cg}Installing ${1}${cend}${tn}"
		folder_name="${qb_install_dir}/${1}"
		[[ -d "${folder_name}" ]] && rm -rf "${folder_name}"
		git clone --no-tags --single-branch --branch "${!github_tag}" --shallow-submodules --recurse-submodules -j"$(nproc)" --depth 1 "${url_github}" "${folder_name}"
		mkdir -p "${folder_name}${subdir}"
		cd "${folder_name}${subdir}"
	else
		echo
		echo "You must provide a tag name for the function - download_folder"
		echo "It creates the tag from the appname_github_tag variable set in the URL section"
		echo
		echo "download_folder tagname url subdir"
		echo
		exit
	fi
}
#####################################################################################################################################################
# This function is for removing files and folders we no longer need
#####################################################################################################################################################
delete_function() {
	if [[ -n "${1}" ]]; then
		if [[ -z "${qb_skip_delete}" ]]; then
			[[ "$2" = 'last' ]] && echo -e "${tn}${clr}Deleting $1 installation files and folders${cend}${tn}" || echo -e "${tn}${clr}Deleting ${1} installation files and folders${cend}"
			#
			file_name="${qb_install_dir}/${1}.tar.gz"
			folder_name="${qb_install_dir}/${1}"
			[[ -f "${file_name}" ]] && rm -rf {"${qb_install_dir:?}/$(tar tf "${file_name}" | grep -Eom1 "(.*)[^/]")","${file_name}"}
			[[ -d "${folder_name}" ]] && rm -rf "${folder_name}"
			cd "${qb_working_dir}"
		else
			[[ "${2}" = 'last' ]] && echo -e "${tn}${clr}Skipping $1 deletion${cend}${tn}" || echo -e "${tn}${clr}Skipping ${1} deletion${cend}"
		fi
	else
		echo
		echo "The delete_function works in tandem with the application_name function"
		echo "Set the appname using the application_name function then use this function."
		echo
		echo "delete_function appname"
		echo
		exit
	fi
}
#####################################################################################################################################################
# This function sets the name of the application to be used with the functions download_file/folder and delete_function
#####################################################################################################################################################
application_name() {
	last_app_name="skip_${app_name}"
	app_name="${1}"
	app_name_skip="skip_${app_name}"
	app_url="${app_name}_url"
	app_github_url="${app_name}_github_url"
}
#####################################################################################################################################################
# This function skips the deletion of the -n flag is supplied
#####################################################################################################################################################
application_skip() {
	if [[ "${1}" = 'last' ]]; then
		echo -e "${tn}Skipping ${clm}$app_name${cend} module installation${tn}"
	else
		echo -e "${tn}Skipping ${clm}$app_name${cend} module installation"
	fi
}
#####################################################################################################################################################
# Functions part 1: Use some of our functions
#####################################################################################################################################################
set_default_values "${@}" see functions
#
check_dependencies # see functions
#
set_build_directory # see functions
#
set_module_urls # see functions
#####################################################################################################################################################
# This section controls our flags that we can pass to the script to modify some variables and behavior.
#####################################################################################################################################################
while (("${#}")); do
	case "${1}" in
		-bs | --boot-strap)
			mkdir -p "$qb_install_dir/patches"
			echo
			echo -e "${clc}$qb_install_dir_short/patches${cend} created"
			echo
			exit
			;;
		-n | --no-delete)
			qb_skip_delete='yes'
			shift
			;;
		-i | --icu)
			qb_skip_icu='no'
			[[ "${qb_skip_icu}" = 'no' ]] && delete=("${delete[@]/icu/}")
			shift
			;;
		-m | --master)
			libtorrent_github_tag="$(git "${libtorrent_github_url}" -t "RC_${libtorrent_version//./_}")"
			test_git_ouput "${libtorrent_github_tag}" "RC_${libtorrent_version//./_}" "libtorrent"
			#
			qbittorrent_github_tag="$(git "${qbittorrent_github_url}" -t "master")"
			test_git_ouput "${qbittorrent_github_tag}" "master" "qbittorrent"
			shift
			;;
		-lm | --libtorrent-master)
			libtorrent_github_tag="$(git "${libtorrent_github_url}" -t "RC_${libtorrent_version//./_}")"
			test_git_ouput "${libtorrent_github_tag}" "RC_${libtorrent_version//./_}" "libtorrent"
			shift
			;;
		-lt | --libtorrent-tag)
			libtorrent_github_tag="$(git "${libtorrent_github_url}" -t "$2")"
			test_git_ouput "${libtorrent_github_tag}" "$2" "libtorrent"
			shift 2
			;;
		-qm | --qbittorrent-master)
			qbittorrent_github_tag="$(git "${qbittorrent_github_url}" -t "master")"
			test_git_ouput "${qbittorrent_github_tag}" "master" "qbittorrent"
			shift
			;;
		-qt | --qbittorrent-tag)
			qbittorrent_github_tag="$(git "${qbittorrent_github_url}" -t "$2")"
			test_git_ouput "${qbittorrent_github_tag}" "$2" "qbittorrent"
			shift 2
			;;
		-h | --help)
			echo
			echo -e "${tb}${tu}Here are a list of available options${cend}"
			echo
			echo -e " ${cg}Use:${cend} ${clb}-b${cend}  ${td}or${cend} ${clb}--build-directory${cend}    ${cy}Help:${cend} ${clb}-h-b${cend}  ${td}or${cend} ${clb}--help-build-directory${cend}"
			echo -e " ${cg}Use:${cend} ${clb}-bs${cend} ${td}or${cend} ${clb}--boot-strap${cend}         ${cy}Help:${cend} ${clb}-h-bs${cend}  ${td}or${cend} ${clb}--help-boot-strap${cend}"
			echo -e " ${cg}Use:${cend} ${clb}-n${cend}  ${td}or${cend} ${clb}--no-delete${cend}          ${cy}Help:${cend} ${clb}-h-n${cend}  ${td}or${cend} ${clb}--help-no-delete${cend}"
			echo -e " ${cg}Use:${cend} ${clb}-i${cend}  ${td}or${cend} ${clb}--icu${cend}                ${cy}Help:${cend} ${clb}-h-i${cend}  ${td}or${cend} ${clb}--help-icu${cend}"
			echo -e " ${cg}Use:${cend} ${clb}-m${cend}  ${td}or${cend} ${clb}--master${cend}             ${cy}Help:${cend} ${clb}-h-m${cend}  ${td}or${cend} ${clb}--help-master${cend}"
			echo -e " ${cg}Use:${cend} ${clb}-lm${cend} ${td}or${cend} ${clb}--libtorrent-master${cend}  ${cy}Help:${cend} ${clb}-h-lm${cend} ${td}or${cend} ${clb}--help-libtorrent-master${cend}"
			echo -e " ${cg}Use:${cend} ${clb}-lt${cend} ${td}or${cend} ${clb}--libtorrent-tag${cend}     ${cy}Help:${cend} ${clb}-h-lt${cend} ${td}or${cend} ${clb}--help-libtorrent-tag${cend}"
			echo -e " ${cg}Use:${cend} ${clb}-qm${cend} ${td}or${cend} ${clb}--qbittorrent-master${cend} ${cy}Help:${cend} ${clb}-h-qm${cend} ${td}or${cend} ${clb}--help-qbittorrent-master${cend}"
			echo -e " ${cg}Use:${cend} ${clb}-qt${cend} ${td}or${cend} ${clb}--qbittorrent-tag${cend}    ${cy}Help:${cend} ${clb}-h-qt${cend} ${td}or${cend} ${clb}--help-qbittorrent-tag${cend}"
			echo -e " ${cg}Use:${cend} ${clb}-p${cend}  ${td}or${cend} ${clb}--proxy${cend}              ${cy}Help:${cend} ${clb}-h-p${cend}  ${td}or${cend} ${clb}--help-proxy${cend}"
			echo
			echo -e "${tb}${tu}Module specific help - flags are used with the modules listed here.${cend}"
			echo
			echo -e "${cg}Use:${cend} ${clm}all${cend} ${td}or${cend} ${clm}module-name${cend}          ${cy}Usage:${cend} ${cg}${qb_working_dir_short}/$(basename -- "$0")${cend} ${clm}all${cend} ${clb}-i${cend}"
			echo
			echo -e " ${td}${clm}all${cend}         ${td}-${cend} ${td}Install all modules${cend}"
			echo -e " ${td}${clm}install${cend}     ${td}-${cend} ${td}${cly}optional${cend} ${td}Install the ${td}${clc}${qb_install_dir_short}/completed/qbittorrent-nox${cend} ${td}binary${cend}"
			[[ "${what_id}" != 'alpine' ]] && echo -e "${td} ${clm}bison${cend}       ${td}-${cend} ${td}${clr}required${cend} ${td}Build bison${cend}"
			[[ "${what_id}" != 'alpine' ]] && echo -e " ${td}${clm}gawk${cend}        ${td}-${cend} ${td}${clr}required${cend} ${td}Build gawk${cend}"
			[[ "${what_id}" != 'alpine' ]] && echo -e " ${td}${clm}glibc${cend}       ${td}-${cend} ${td}${clr}required${cend} ${td}Build libc locally to statically link nss${cend}"
			echo -e " ${td}${clm}zlib${cend}        ${td}-${cend} ${td}${clr}required${cend} ${td}Build zlib locally${cend}"
			echo -e " ${td}${clm}icu${cend}         ${td}-${cend} ${td}${cly}optional${cend} ${td}Build ICU locally${cend}"
			echo -e " ${td}${clm}openssl${cend}     ${td}-${cend} ${td}${clr}required${cend} ${td}Build openssl locally${cend}"
			echo -e " ${td}${clm}boost${cend}       ${td}-${cend} ${td}${clr}required${cend} ${td}Download, extract and build the boost library files${cend}"
			echo -e " ${td}${clm}qtbase${cend}      ${td}-${cend} ${td}${clr}required${cend} ${td}Build qtbase locally${cend}"
			echo -e " ${td}${clm}qttools${cend}     ${td}-${cend} ${td}${clr}required${cend} ${td}Build qttools locally${cend}"
			echo -e " ${td}${clm}libtorrent${cend}  ${td}-${cend} ${td}${clr}required${cend} ${td}Build libtorrent locally with b2${cend}"
			echo -e " ${td}${clm}qbittorrent${cend} ${td}-${cend} ${td}${clr}required${cend} ${td}Build qbitorrent locally${cend}"
			echo
			exit 1
			;;
		-h-b | --help-build-directory)
			echo
			echo -e "${tb}${tu}Here is the help description for this flag:${cend}"
			echo
			echo -e " Default build location: ${cc}${qb_install_dir_short}${cend}"
			echo
			echo -e " ${clb}-b${cend} or ${clb}--build-directory${cend} to set the location of the build directory."
			echo
			echo -e " ${cy}Paths are relative to the script location. I recommend that you use a full path.${cend}"
			echo
			echo -e " ${td}Example:${cend} ${td}${cg}${qb_working_dir_short}/$(basename -- "$0")${cend} ${td}${clm}all${cend} ${td}- Will install all modules and build libtorrent to the default build location${cend}"
			echo
			echo -e " ${td}Example:${cend} ${td}${cg}${qb_working_dir_short}/$(basename -- "$0")${cend} ${td}${clm}all ${clb}-b${cend} ${td}${clc}\"\$HOME/build\"${cend} ${td}- Will specify a build directory and install all modules to that custom location${cend}"
			echo
			echo -e " ${td}Example:${cend} ${td}${cg}${qb_working_dir_short}/$(basename -- "$0")${cend} ${td}${clm}module${cend} ${td}- Will install a single module to the default build location${cend}"
			echo
			echo -e " ${td}Example:${cend} ${td}${cg}${qb_working_dir_short}/$(basename -- "$0")${cend} ${td}${clm}module${cend} ${clb}-b${cend} ${td}${clc}\"\$HOME/build\"${cend} ${td}- will specify a custom build directory and install a specific module use to that custom location${cend}"
			#
			echo
			exit 1
			;;
		-h-bs | --help-boot-strap)
			echo
			echo -e "${tb}${tu}Here is the help description for this flag:${cend}"
			echo
			echo -e " Creates this dir: ${cc}${qb_install_dir_short}/patches${cend}"
			echo
			echo -e " Add you patches here in the format module name, for example."
			echo
			echo -e " ${cc}${qb_install_dir_short}/patches${cend}"
			echo
			exit 1
			;;
		-h-n | --help-no-delete)
			echo
			echo -e "${tb}${tu}Here is the help description for this flag:${cend}"
			echo
			echo -e " Skip all delete functions for selected modules to leave source code directories behind."
			echo
			echo -e " ${td}This flag is provided with no arguments.${cend}"
			echo
			echo -e " ${clb}-n${cend}"
			echo
			exit 1
			;;
		-h-i | --help-icu)
			echo
			echo -e "${tb}${tu}Here is the help description for this flag:${cend}"
			echo
			echo -e " Use ICU libraries when building qBittorrent. Final binary size will be around ~50Mb"
			echo
			echo -e " ${td}This flag is provided with no arguments.${cend}"
			echo
			echo -e " ${clb}-i${cend}"
			echo
			exit 1
			;;
		-h-m | --help-master)
			echo
			echo -e "${tb}${tu}Here is the help description for this flag:${cend}"
			echo
			echo -e " Always use the master branch for ${cg}libtorrent RC_${libtorrent_version//./_}${cend}"
			echo
			echo -e " Always use the master branch for ${cg}qBittorrent ${qbittorrent_github_tag/release-/}${cend}"
			echo
			echo -e " ${td}This flag is provided with no arguments.${cend}"
			echo
			echo -e " ${clb}-lm${cend}"
			echo
			exit 1
			;;
		-h-lm | --help-libtorrent-master)
			echo
			echo -e "${tb}${tu}Here is the help description for this flag:${cend}"
			echo
			echo -e " Always use the master branch for ${cg}libtorrent-$libtorrent_version${cend}"
			echo
			echo -e " This master that will be used is: ${cg}RC_${libtorrent_version//./_}${cend}"
			echo
			echo -e " ${td}This flag is provided with no arguments.${cend}"
			echo
			echo -e " ${clb}-lm${cend}"
			echo
			exit 1
			;;
		-h-lt | --help-libtorrent-tag)
			echo
			echo -e "${tb}${tu}Here is the help description for this flag:${cend}"
			echo
			echo -e " Use a provided libtorrent tag when cloning from github."
			echo
			echo -e " ${cy}You can use this flag with this help command to see the value if called before the help option.${cend}"
			echo
			echo -e " ${cg}${qb_working_dir_short}/$(basename -- "$0")${cend}${clb} -lt ${clc}RC_2_0${cend} ${clb}-h-lt${cend}"
			if [[ ! "${libtorrent_github_tag}" =~ (error_tag|error_22) ]]; then
				echo
				echo -e " ${td}This is tag that will be used is: ${cg}$libtorrent_github_tag${cend}"
			fi
			echo
			echo -e " ${td}This flag must be provided with arguments.${cend}"
			echo
			echo -e " ${clb}-lt${cend} ${clc}libtorrent-1_2_11${cend}"
			echo
			exit 1
			;;
		-h-qm | --help-qbittorrent-master)
			echo
			echo -e "${tb}${tu}Here is the help description for this flag:${cend}"
			echo
			echo -e " Always use the master branch for ${cg}qBittorrent${cend}"
			echo
			echo -e " This master that will be used is: ${cg}master${cend}"
			echo
			echo -e " ${td}This flag is provided with no arguments.${cend}"
			echo
			echo -e " ${clb}-lm${cend}"
			echo
			exit 1
			;;
		-h-qt | --help-qbittorrent-tag)
			echo
			echo -e "${tb}${tu}Here is the help description for this flag:${cend}"
			echo
			echo -e " Use a provided libtorrent tag when cloning from github."
			echo
			echo -e " ${cy}You can use this flag with this help command to see the value if called before the help option.${cend}"
			echo
			echo -e " ${cg}${qb_working_dir_short}/$(basename -- "$0")${cend}${clb} -qt ${clc}release-4.3.0.1${cend} ${clb}-h-qt${cend}"
			#
			if [[ ! "${qbittorrent_github_tag}" =~ (error_tag|error_22) ]]; then
				echo
				echo -e " ${td}This tag that will be used is: ${cg}$qbittorrent_github_tag${cend}"
			fi
			echo
			echo -e " ${td}This flag must be provided with arguments.${cend}"
			echo
			echo -e " ${clb}-lt${cend} ${clc}release-4.3.0.1${cend}"
			echo
			exit 1
			;;
		--) # end argument parsing
			shift
			break
			;;
		-*) # unsupported flags
			echo -e "${tn}Error: Unsupported flag ${cr}$1${cend} - use ${cg}-h${cend} or ${cg}--help${cend} to see the valid options${tn}" >&2
			exit 1
			;;
		*) # preserve positional arguments
			params2+=("${1}")
			shift
			;;
	esac
done
#
eval set -- "${params2[@]}" # Set positional arguments in their proper place.
#####################################################################################################################################################
# Lets dip out now if we find that any github tags failed validation
#####################################################################################################################################################
[[ "${libtorrent_github_tag}" = "error_tag" || "${qbittorrent_github_tag}" = "error_tag" ]] && {
	echo
	exit
}
#####################################################################################################################################################
# Functions part 2: Use some of our functions
#####################################################################################################################################################
installation_modules "${@}" # see functions
#
[[ "${*}" =~ ([[:space:]]|^)"install"([[:space:]]|$) ]] && install_qbittorrent "${@}" # see functions
#####################################################################################################################################################
# bison installation
#####################################################################################################################################################
application_name bison
#
if [[ "${!app_name_skip:-yes}" = 'no' || "${1}" = "${app_name}" ]]; then
	custom_flags_reset
	download_file "${app_name}" "${!app_url}"
	#
	./configure --prefix="${qb_install_dir}" 2>&1 | tee "${qb_install_dir}/logs/${app_name}.log.txt"
	make -j"$(nproc)" CXXFLAGS="${CXXFLAGS}" CPPFLAGS="${CPPFLAGS}" LDFLAGS="${LDFLAGS}" 2>&1 | tee -a "${qb_install_dir}/logs/${app_name}.log.txt"
	make install 2>&1 | tee -a "${qb_install_dir}/logs/${app_name}.log.txt"
	#
	delete_function "${app_name}"
else
	application_skip
fi
#####################################################################################################################################################
# gawk installation
#####################################################################################################################################################
application_name gawk
#
if [[ "${!app_name_skip:-yes}" = 'no' || "$1" = "${app_name}" ]]; then
	custom_flags_reset
	download_file "${app_name}" "${!app_url}"
	#
	./configure --prefix="$qb_install_dir" 2>&1 | tee "${qb_install_dir}/logs/${app_name}.log.txt"
	make -j"$(nproc)" CXXFLAGS="${CXXFLAGS}" CPPFLAGS="${CPPFLAGS}" LDFLAGS="${LDFLAGS}" 2>&1 | tee -a "${qb_install_dir}/logs/${app_name}.log.txt"
	make install 2>&1 | tee -a "${qb_install_dir}/logs/${app_name}.log.txt"
	#
	delete_function "${app_name}"
else
	application_skip
fi
#####################################################################################################################################################
# glibc installation
#####################################################################################################################################################
application_name glibc
#
if [[ "${!app_name_skip:-yes}" = 'no' || "${1}" = "${app_name}" ]]; then
	custom_flags_reset
	download_file "${app_name}" "${!app_url}"
	#
	mkdir -p build
	cd build
	"${qb_install_dir}/$(tar tf "${file_name}" | head -1 | cut -f1 -d"/")/configure" --prefix="${qb_install_dir}" --enable-static-nss 2>&1 | tee "${qb_install_dir}/logs/${app_name}.log.txt"
	make -j"$(nproc)" 2>&1 | tee -a "${qb_install_dir}/logs/$app_name.log.txt"
	make install 2>&1 | tee -a "${qb_install_dir}/logs/${app_name}.log.txt"
	#
	delete_function "${app_name}"
else
	application_skip
fi
#####################################################################################################################################################
# zlib installation
#####################################################################################################################################################
application_name zlib
#
if [[ "${!app_name_skip:-yes}" = 'no' || "${1}" = "${app_name}" ]]; then
	custom_flags_set
	download_file "${app_name}" "${!app_url}"
	#
	./configure --prefix="${qb_install_dir}" --static 2>&1 | tee "${qb_install_dir}/logs/${app_name}.log.txt"
	make -j"$(nproc)" CXXFLAGS="${CXXFLAGS}" CPPFLAGS="${CPPFLAGS}" LDFLAGS="${LDFLAGS}" 2>&1 | tee -a "${qb_install_dir}/logs/${app_name}.log.txt"
	make install 2>&1 | tee -a "${qb_install_dir}/logs/${app_name}.log.txt"
	#
	delete_function "${app_name}"
else
	application_skip
fi
#####################################################################################################################################################
# ICU installation
#####################################################################################################################################################
application_name icu
#
if [[ "${!app_name_skip:-yes}" = 'no' || "${1}" = "${app_name}" ]]; then
	custom_flags_set
	download_file "${app_name}" "${!app_url}" "/source"
	#
	./configure --prefix="${qb_install_dir}" --disable-shared --enable-static CXXFLAGS="${CXXFLAGS}" CPPFLAGS="${CPPFLAGS}" LDFLAGS="${LDFLAGS}" 2>&1 | tee "${qb_install_dir}/logs/${app_name}.log.txt"
	make -j"$(nproc)" 2>&1 | tee -a "${qb_install_dir}/logs/${app_name}.log.txt"
	make install 2>&1 | tee -a "${qb_install_dir}/logs/${app_name}.log.txt"
	#
	delete_function "${app_name}"
else
	application_skip
fi
#####################################################################################################################################################
# openssl installation
#####################################################################################################################################################
application_name openssl
#
if [[ "${!app_name_skip:-yes}" = 'no' || "${1}" = "${app_name}" ]]; then
	custom_flags_set
	download_file "${app_name}" "${!app_url}"
	#
	./config --prefix="${qb_install_dir}" threads no-shared no-dso no-comp CXXFLAGS="${CXXFLAGS}" CPPFLAGS="${CPPFLAGS}" LDFLAGS="${LDFLAGS}" 2>&1 | tee "${qb_install_dir}/logs/${app_name}.log.txt"
	make -j"$(nproc)" 2>&1 | tee -a "${qb_install_dir}/logs/${app_name}.log.txt"
	make install_sw install_ssldirs 2>&1 | tee -a "${qb_install_dir}/logs/${app_name}.log.txt"
	#
	delete_function "${app_name}"
else
	application_skip
fi
#####################################################################################################################################################
# boost libraries install
#####################################################################################################################################################
application_name boost
#
if [[ "${!app_name_skip:-yes}" = 'no' ]] || [[ "${1}" = "${app_name}" ]]; then
	custom_flags_set
	#
	[[ -d "${qb_install_dir}/boost" ]] && delete_function "${app_name}"
	#
	if [[ "${boost_url_status}" -eq '200' ]]; then
		download_file "${app_name}" "${boost_url}"
		mv -f "${qb_install_dir}/boost_${boost_version//./_}/" "${qb_install_dir}/boost"
		cd "${qb_install_dir}/boost"
	fi
	#
	if [[ "${boost_url_status}" -eq '403' ]]; then
		download_folder "${app_name}" "${!app_github_url}"
	fi
	#
	"${qb_install_dir}/boost/bootstrap.sh" 2>&1 | tee "${qb_install_dir}/logs/${app_name}.log.txt"
	"${qb_install_dir}/boost/b2" -j"$(nproc)" variant=release threading=multi link=static cxxflags="${CXXFLAGS}" cflags="${CPPFLAGS}" linkflags="${LDFLAGS}" toolset=gcc install --prefix="${qb_install_dir}" 2>&1 | tee -a "${qb_install_dir}/logs/${app_name}.log.txt"
else
	application_skip
fi
#####################################################################################################################################################
# qtbase installation
#####################################################################################################################################################
application_name qtbase
#
if [[ "${!app_name_skip:-yes}" = 'no' ]] || [[ "${1}" = "${app_name}" ]]; then
	custom_flags_set
	download_folder "${app_name}" "${!app_github_url}"
	#
	[[ "${qb_skip_icu}" = 'no' ]] && icu='-icu' || icu='-no-icu'
	./configure -prefix "${qb_install_dir}" "${icu}" -opensource -confirm-license -release -openssl-linked -static -c++std c++14 -no-feature-c++17 -qt-pcre -no-iconv -no-feature-glib -no-feature-opengl -no-feature-dbus -no-feature-gui -no-feature-widgets -no-feature-testlib -no-compile-examples -I "$include_dir" -L "$lib_dir" QMAKE_LFLAGS="$LDFLAGS" 2>&1 | tee "$qb_install_dir/logs/$app_name.log.txt"
	make -j"$(nproc)" 2>&1 | tee -a "${qb_install_dir}/logs/${app_name}.log.txt"
	make install 2>&1 | tee -a "${qb_install_dir}/logs/${app_name}.log.txt"
	#
	delete_function "${app_name}"
else
	application_skip
fi
#####################################################################################################################################################
# qttools installation
#####################################################################################################################################################
application_name qttools
#
if [[ "${!app_name_skip:-yes}" = 'no' ]] || [[ "${1}" = "${app_name}" ]]; then
	custom_flags_set
	download_folder "${app_name}" "${!app_github_url}"
	#
	"${qb_install_dir}/bin/qmake" -set prefix "${qb_install_dir}" 2>&1 | tee "${qb_install_dir}/logs/${app_name}.log.txt"
	"${qb_install_dir}/bin/qmake" QMAKE_CXXFLAGS="-static" QMAKE_LFLAGS="-static" 2>&1 | tee -a "${qb_install_dir}/logs/${app_name}.log.txt"
	make -j"$(nproc)" 2>&1 | tee -a "${qb_install_dir}/logs/${app_name}.log.txt"
	make install 2>&1 | tee -a "${qb_install_dir}/logs/${app_name}.log.txt"
	#
	delete_function "${app_name}"
else
	application_skip
fi
#####################################################################################################################################################
# libtorrent installation
#####################################################################################################################################################
application_name libtorrent
#
if [[ "${!app_name_skip:-yes}" = 'no' ]] || [[ "${1}" = "${app_name}" ]]; then
	if [[ ! -d "${qb_install_dir}/boost" ]]; then
		echo -e "${tn}${clr}Warning${cend} - You must install the boost module before you can use the libtorrent module"
	else
		custom_flags_set
		download_folder "${app_name}" "${!app_github_url}"
		#
		BOOST_ROOT="${qb_install_dir}/boost"
		BOOST_INCLUDEDIR="${qb_install_dir}/boost"
		BOOST_BUILD_PATH="${qb_install_dir}/boost"
		#
		apply_patches
		#
		"${qb_install_dir}/boost/b2" -j"$(nproc)" address-model="$(getconf LONG_BIT)" dht=on encryption=on crypto=openssl i2p=on extensions=on variant=release threading=multi link=static boost-link=static cxxflags="${CXXFLAGS}" cflags="${CPPFLAGS}" linkflags="${LDFLAGS}" install --prefix="${qb_install_dir}" 2>&1 | tee "${qb_install_dir}/logs/${app_name}.log.txt"
		#
		delete_function boost
		delete_function "${app_name}"
	fi
else
	application_skip
fi
#####################################################################################################################################################
# qBittorrent installation
#####################################################################################################################################################
application_name qbittorrent
#
if [[ "${!app_name_skip:-yes}" = 'no' ]] || [[ "${1}" = "${app_name}" ]]; then
	custom_flags_set
	download_folder "${app_name}" "${!app_github_url}"
	#
	./bootstrap.sh 2>&1 | tee "${qb_install_dir}/logs/${app_name}.log.txt"
	./configure --prefix="${qb_install_dir}" "${local_boost}" --disable-gui CXXFLAGS="${CXXFLAGS}" CPPFLAGS="${CPPFLAGS}" LDFLAGS="${LDFLAGS} -l:libboost_system.a" openssl_CFLAGS="-I${include_dir}" openssl_LIBS="-L${lib_dir} -l:libcrypto.a -l:libssl.a" libtorrent_CFLAGS="-I${include_dir}" libtorrent_LIBS="-L${lib_dir} -l:libtorrent.a" zlib_CFLAGS="-I${include_dir}" zlib_LIBS="-L${lib_dir} -l:libz.a" QT_QMAKE="${qb_install_dir}/bin" 2>&1 | tee -a "${qb_install_dir}/logs/${app_name}.log.txt"
	#
	sed -i 's/-lboost_system//' conf.pri
	sed -i 's/-lcrypto//' conf.pri
	sed -i 's/-lssl//' conf.pri
	#
	make -j"$(nproc)" 2>&1 | tee -a "${qb_install_dir}/logs/${app_name}.log.txt"
	make install 2>&1 | tee -a "${qb_install_dir}/logs/${app_name}.log.txt"
	#
	[[ -f "${qb_install_dir}/bin/qbittorrent-nox" ]] && cp -f "${qb_install_dir}/bin/qbittorrent-nox" "${qb_install_dir}/completed/qbittorrent-nox"
	#
	delete_function "${app_name}" last
else
	application_skip last
fi
#####################################################################################################################################################
# We are all done so now exit
#####################################################################################################################################################
exit
