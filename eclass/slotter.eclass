# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: slotter.eclass
# @MAINTAINER:
# Chris A. Giorgi <chrisgiorgi@gmail.com>
# @AUTHOR:
# Chris A. Giorgi <chrisgiorgi@gmail.com>
# @BLURB: Eclass for making multiple installed versions of slotted packages coexist.
# @DESCRIPTION:
# Eclass with functions to assist making multiple installed slotted versions
# of a package coexist peacefully.


# @FUNCTION: slotter-enversion_solibdirs
# @USAGE: [list of library directories]
# @DESCRIPTION:
# Runs slotter-enversion_solibs with an arguments list containing all
# unversioned .so libraries found in any of the supplied directories.
slotter-enversion_solibdirs() {
	local my_libdirs my_libdir
	if [[ ${1} ]]; then
		my_libdirs=( ${1} )
	elif [[ $(declare -p ESLOTTER_SOLIB_DIRS) == "declare -a"* ]]; then
		my_libdirs=( "${ESLOTTER_SOLIB_DIRS[@]}" )
	elif [ ! -z "${ESLOTTER_SOLIB_DIRS}" ] ; then
		my_libdirs=( ${ESLOTTER_SOLIB_DIRS} )
	else
		my_libdirs=( /lib /lib32 /lib64 /usr/lib /usr/lib32 /usr/lib64 )
	fi

	for my_libdir in "${my_libdirs[@]}" ; do
		# Sanetize path with destdir prepended if not present.
		my_libdir="${D%%/}/${my_libdir#${D%%/}/}"
		if [ -d "${my_libdir}" ] ; then
			local my_file
			for my_file in "${my_libdir%%/}"/*.so ; do
				[ -e "$my_file" ] && ESLOTTER_SOLIBS+=( "$my_file" )
			done
		fi
	done

	slotter-enversion_solibs
}


# @FUNCTION: slotter-enversion_solibs
# @USAGE: [list of unversioned solibs]
# @DESCRIPTION:
# Remove unversioned links to versioned shared libraries of the form
# libname.so -> libname.so.x.y and replace them with links named libname[-]x.so
# to allow compiling against a specifc library ABI when multiple revisions of
# the library are installed in parallel. Unversioned libraries are moved rather
# than having the new link created and existing one removed.
slotter-enversion_solibs() {
	# If called with arguments, variable is ignored. Accepts string or array.
	local my_solibs
	if [[ ${1} ]]; then
		my_solibs=( ${1} )
	elif [[ $(declare -p ESLOTTER_SOLIBS) == "declare -a"* ]]; then
		my_solibs=( "${ESLOTTER_SOLIBS[@]}" )
	else
		my_solibs=( ${ESLOTTER_SOLIBS} )
	fi
	
	# Iterate over unversioned shared libraries and slot them.
	local my_dest_solib
	for my_dest_solib in "${my_solibs[@]}"; do

		# Sanitize path with destdir prepended if not present.
		my_dest_solib="${D%%/}/${my_dest_solib#${D%%/}/}"

		# Skip any files that don't end in '.so' with a warning.
		[ "${my_dest_solib}" == "${my_dest_solib%.so}" ] && ewarn "File not ending in '.so' passed to slotter-enversion_solibs!" && continue

		local my_solib my_dest_dir my_dir my_solib_slotted

		# Extract solib name, destination directory, and relative directory from $my_dest_solib.
		my_solib="${my_dest_solib##*/}"
		my_dest_dir="${my_dest_solib%/${my_solib}}"
		my_dir="/${my_dest_dir#${D%/}/}"

		# Detect slotted solib name to use from passed solib's soname.
		my_solib_slotted="$(slotter-solib_get_soname_slotted "${my_dest_solib}").so"

		# Check if we have an unversioned library that is not a link, if so move it to slotted soname.
		if [ ! -h "${my_dest_solib}" ] ; then
			mv -T "${my_dest_solib}" "${my_dest_dir}/${my_solib_slotted}"
		# Othewise create a symlink from the the slotted soname to the raw soname versioned library.
		else
			dosym "$(basename "$(readlink "${my_dest_solib}")")" "${my_dir}/${my_solib_slotted}"
			rm "${my_dest_solib}"
		fi

		# Add this library to the list to check when adding back compatability links.
		ESLOTTER_SOLIBS_SLOTTED+=( "${my_dir}/${my_solib_slotted}" )
	done
}


slotter-solib_get_soname_slotted() {
	local my_solib="${1}"
	local my_sobase="${my_solib##*/}"
	local my_soname="$(slotter-solib_get_soname "${my_solib}")"
	local my_soslot="${my_soname#*.so.}"
	# Set our slot using the following order of priorites:
	# Passed Argument, ..._SLOT_FORCED, Detected slot, _...SLOT_DEFAULT, 0
	my_soslot="${2:-${ESLOTTER_SLOT_FORCED:-${my_soslot:-${ESLOTTER_SLOT_DEFAULT:-0}}}}"
	slotter-soname_to_soname_slotted "${my_sobase}.${my_soslot}"
}


slotter-solib_get_soname() {
	objdump -p "${1}" | sed -n -e 's/^[[:space:]]*SONAME[[:space:]]*//p'
}


slotter-soname_to_soname_slotted() {
	# Regex adapted from Debian Policy Manual v4.1.3.0, Section 8.1, Listing 2 to not alter case.
	echo "${1}" | LC_ALL=C sed -r -e 's/([0-9])\.so\./\1-/; s/\.so(\.|$)//; y/_/-/'
}


slotter-pkg_postinst() {
	local newest="$(best_version ${CATEGORY}/${PN})"
	if [ "${newest#*/}" == "${PF}" ] ; then
		echo "Creating symlink to newest installed version of libraries."
		local my_ver_so
		for my_ver_so in "${ESLOTTER_SOLIBS_SLOTTED[@]}" ; do
			local my_so my_src

			if [ ! -e "${my_ver_so}" ] ; then
				ewarn "Couldn't find ${my_ver_so}!"
				continue
			elif [ -h "${my_ver_so}" ] ; then
				my_src="$(basename "$(readlink "${my_ver_so}")")"
			else
				my_src="${my_ver_so}"
			fi
			my_so="${my_ver_so%/*}/${my_src%.so.*}.so"

			echo "Creating link from \"${my_src}\" to \"${my_so}\"."
			if [ -h "${my_so}" ] ; then rm -f "${my_so}" || die "Failed to remove link at ${my_so}" ; fi
			[ -e "${my_so}" ] && die "Attempting to overwrite ${my_so} found real file, not symbolic link."
			ln -s "${my_src}" "${my_so}"
		done
	fi
}
