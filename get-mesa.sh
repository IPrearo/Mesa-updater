#!/bin/bash

:'
This is a simple script that gets, extracts, and install the newest release
	of the Mesa drivers.

TODO:
	- "yes to all" flag (-y)
	- "allow release candidates" flag (-r)
'

CALLING_DIR=$(pwd)
DATA_DIR="./data/"
SITE="https://archive.mesa3d.org/"

CLEANUP=()
clean_files () {
	# Checks if cleanup is empty
	if [[ -z ${CLEANUP} ]]; then
		return 0
	fi

	RESPONSE=""
	while [ "${RESPONSE,,}" != 'n' ] && [ "${RESPONSE,,}" != 'y' ]
	do	
		read -p "Clean up files? (y/n): " RESPONSE
	done

	if [[ ${RESPONSE,,} == 'y' ]]; then
		rm -r ${CLEANUP[*]}
	fi
}

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

if [[ ${CRNT_VERSION,,} == ${LAT_VERSION} ]]; then
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


cd ${LAT_VERSION}
# Compiles Mesa
meson setup builddir/
meson compile -C builddir/

# Installs Mesa
sudo meson install -C builddir/

cd ..
# Cleans the downloaded/extracted files
clean_files

return 0 2>/dev/null
exit 0
