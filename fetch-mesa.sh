#!/bin/bash

: '
This is a simple script that gets, extracts, and install the newest release
	of the Mesa drivers.

TODO:
	- "allow release candidates" flag (-r|--release-candidates)
	- Specify a Mesa version to install (-v*|--version* VERSION)
'

print_help() {
	printf '\nSimple script for updating Mesa GPU drivers.\n\n'
	printf 'Usage: bash get-mesa.sh\n\n'
	printf '[OPTIONS]\n'
	echo "-h, --help		show this message"
	echo "-f, --force		forces installation of newest version, regardless of installed version"
	
	echo ""
}

ask_yn(){
	# Asks the first argument as a yes/no question and echoes and return
	# 1 for yes
	# 0 for no
	
	if [[ ${YES_TO_ALL} == 1 ]]; then
		echo 1
		return 1
	fi

	local RESPONSE=""
	while [ "${RESPONSE,,}" != 'n' ] && [ "${RESPONSE,,}" != 'y' ]
	do
		read -p "$1 (y/n): " RESPONSE
	done

	if [[ ${RESPONSE,,} == 'y' ]]; then
		echo 1
		return 1
	fi
	
	echo 0
	return 0
}

clean_files () {
	# Checks if cleanup is empty
	if [[ -z ${CLEANUP} ]]; then
		return 0
	fi

	ANSWER=$(ask_yn "Clean up files?")
	if [[ ${ANSWER} ]]; then
		rm -r ${CLEANUP[*]}
	fi
}

while test $# -gt 0; do
	case "$1" in
		-f|--force)
			shift
			FORCE_INSTALL=1
			;;
		-y|--yes)
			shift
			YES_TO_ALL=1
			;;
		*)
			print_help
			exit 0
			;;
	esac
done

CALLING_DIR=$(pwd)
DATA_DIR="./data/"
SITE="https://archive.mesa3d.org/"

CLEANUP=()

mkdir -p ${DATA_DIR}
cd ${DATA_DIR}

# Gets the index of the repo. This contains all versions and links
wget -O mesa-index.html $SITE
CLEANUP+=('mesa-index.html')

# Gets the latest version .tar.xz file name
TARFILE="$( grep -Eoi 'mesa-[0-9\.]+\.tar\.xz' mesa-index.html \
	  | tail -1 )"

# Extracts the latest version name
LAT_VERSION="${TARFILE%.tar.xz}"

# Gets the current installed version using vulkaninfo
CRNT_VERSION="$(vulkaninfo --summary \
		| grep -Eoi "mesa [0-9\.]*" \
		| tail -1 )"

# Handles a difference in formatting, where the repo has "mesa-x.x.x" and vulkaninfo has "Mesa x.x.x"
CRNT_VERSION="${CRNT_VERSION/ /-}"

if [ ${CRNT_VERSION,,} == ${LAT_VERSION} ] && [ -z ${FORCE_INSTALL} ]; then
 	echo "Already latest version."
 	clean_files
	return 0 2>/dev/null
 	exit 0
fi

# Checks if there already is a compacted file for the latest version
echo "Checking for local ${LAT_VERSION}"
if ! [[ $(ls | grep ^${LAT_VERSION}) ]]; then
	echo "File not found. downloading."
	wget $SITE$TARFILE
fi

# Adds the tar file to the cleanup
CLEANUP+=($TARFILE)

# Extracts the tar file if no extracted directory exists
if ! [[ $(ls | grep ^${LAT_VERSION}$) ]]; then
	echo "Extracting ${TARFILE}"
	tar -xf $TARFILE
fi

# Adds the extracted directory to the cleanup
CLEANUP+=($LAT_VERSION)


COMPILE=$(ask_yn "Compile the downloaded version?")
if [[ "${COMPILE}" -eq "0" ]]; then
	clean_files
	return 0 2>/dev/null
	exit 0
fi

cd ${LAT_VERSION}
# Compiles Mesa
meson setup builddir/
meson compile -C builddir/

INSTALL=$(ask_yn "Install compiled Mesa version? Needs superuser access.")

if [[ ${INSTALL} ]]; then
	# Installs Mesa
	sudo meson install -C builddir/

	# Creates links to newly installed Mesa, needs super user status
	sudo ldconfig
fi

cd ..
# Cleans the downloaded/extracted files
clean_files

return 0 2>/dev/null
exit 0
