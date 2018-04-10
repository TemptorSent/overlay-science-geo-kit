# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

FORTRAN_NEEDED=fortran

inherit fortran-2 toolchain-funcs cmake-utils flag-o-matic

MYP=${P/_p/-patch}

DESCRIPTION="General purpose library and format for storing scientific data"
HOMEPAGE="http://www.hdfgroup.org/hdf4.html"
SRC_URI="http://www.hdfgroup.org/ftp/HDF/HDF_Current/src/${MYP}.tar.bz2"

SLOT="0"
LICENSE="NCSA-HDF"
KEYWORDS="~amd64 ~ia64 ~ppc ~x86 ~amd64-linux ~x86-linux"
IUSE="examples fortran +szip static-libs +libtirpc test"
REQUIRED_USE="test? ( szip )"

RDEPEND="
	!libtirpc? ( elibc_glibc? ( sys-libs/glibc[rpc(-)] ) )
	libtirpc? ( net-libs/libtirpc )
	net-libs/rpcsvc-proto
	sys-libs/zlib
	virtual/jpeg:0
	szip? ( virtual/szip )
"
DEPEND="${RDEPEND}
	test? ( virtual/szip )"

S="${WORKDIR}/${MYP}"

PATCHES=( "${FILESDIR}/${P}-git-20180201.patch" )


src_prepare() {
	[[ $(tc-getFC) = *gfortran ]] && append-fflags -fno-range-check

	cmake-utils_src_prepare

	# Fixups for libtircp if enabled
	if use libtirpc ; then
		# Find libtirpc using pkg-config module and set libs.
		sed -e '14,$ c\
include(FindPkgConfig)\
pkg_search_module(XDR REQUIRED libtirpc)\
set (LINK_COMP_LIBS ${LINK_COMP_LIBS} ${XDR_LIBS})\
set (LINK_COMP_SHARED_LIBS ${LINK_COMP_SHARED_LIBS} ${XDR_LIBRARIES})'\
		-i config/cmake/FindXDR.cmake
		# Fix libs for mfhdf to use libtirpc properly.
		sed -e '/#-*/ {
			N
		/#-*\n# Add file(s) to CMake Install/ i\
if (XDR_FOUND AND NOT HDF_BUILD_XDR_LIB)\
  target_link_libraries (${HDF4_MF_LIB_TARGET} PUBLIC ${XDR_LIBRARIES})\
  target_include_directories (${HDF4_MF_LIB_TARGET} PUBLIC ${XDR_INCLUDE_DIRS})\
  if (BUILD_SHARED_LIBS)\
    target_link_libraries (${HDF4_MF_LIBSH_TARGET} PUBLIC ${XDR_LIBRARIES})\
    target_include_directories (${HDF4_MF_LIBSH_TARGET} PUBLIC ${XDR_INCLUDE_DIRS})\
  endif ()\
endif ()\

			}'\
			-i mfhdf/libsrc/CMakeLists.txt
	fi
	# End libtirpc fixup.

	# Fixup doc install dir.
	sed -e '/HDF4_Examples.cmake file/,/README.txt file/ {
		s/.*${HDF4_INSTALL_DATA_DIR}/&\/doc\/'"${PF}"'\/examples/
		}' \
		-e '/README.txt file/,$ {
		s/.*${HDF4_INSTALL_DATA_DIR}/&\/doc\/'"${PF}"'/
		}'\
		-i CMakeInstallation.cmake

## TODO: Fix installing of examples, the following doesn't do it:
	# Fixup examples install dir.
#	sed -re 's|add_executable \(([^$]*\$\{example\}).*|&\n  set_target_properties(\1 PROPERTIES RUNTIME_OUTPUT_DIR "${CMAKE_BINARY_DIR}/HDF4Examples")|'\
#		-i */examples/CMakeLists.txt */*/examples/CMakeLists.txt
	sed -e '3 i\
set_directory_properties( PROPERTIES\
  RUNTIME_OUTPUT_DIR "${CMAKE_BINARY_DIR}/bin/HDF4Examples"\
  ARCHIVE_OUTPUT_DIR "${CMAKE_BINARY_DIR}/bin/HDF4Examples"\
  LIBRARY_OUTPUT_DIR "${CMAKE_BINARY_DIR}/bin/HDF4Examples"\
)'\
		-i */examples/CMakeLists.txt */*/examples/CMakeLists.txt
#		-e '$ a\
#install( TARGETS ${examples} RUNTIME DESTINATION "bin/HDF4Examples" OPTIONAL)'\


}

src_configure() {
	CC="$(tc-getCC)"

	mycmakeargs=(
		-DHDF4_INSTALL_LIB_DIR="$(get_libdir)"
		-DHDF4_INSTALL_INCLUDE_DIR="include/hdf"
		-DBUILD_SHARED_LIBS=TRUE
		-DHDF4_ENABLE_NETCDF=FALSE
		-DHDF4_BUILD_EXAMPLES=$(usex examples)
		-DHDF4_BUILD_FORTRAN=$(usex fortran)
		-DHDF4_BUILD_TOOLS=TRUE
		-DHDF4_BUILD_UTILS=TRUE
		-DHDF4_ENABLE_SZIP_SUPPORT=$(usex szip)
	)

	cmake-utils_src_configure
}

src_install() {
	cmake-utils_src_install

	if ! use static-libs ; then
		rm "${ED}usr"/lib*/*.a
		prune_libtool_files --all
	fi

	# Install man pages, renaming ncdump and ncgen with suffix -hdf
	doman ${S}/man/*.1
	cp mfhdf/ncdump/ncdump.1 "${ED}usr/share/man/man1/ncdump-hdf.1"
	cp mfhdf/ncgen/ncgen.1 "${ED}usr/share/man/man1/ncgen-hdf.1"

	dodoc release_notes/{RELEASE,HISTORY,bugs_fixed,misc_docs}.txt
	cd "${ED}usr"
#	if use examples; then
#		mv  share/hdf4_examples share/doc/${PF}/examples || die
#		docompress -x /usr/share/doc/${PF}/examples
#	else
#		rm -r share/hdf4_examples || die
#	fi
	# Rename ncdump and ncgen with -hdf prefix
	mv bin/ncdump{,-hdf} || die
	mv bin/ncgen{,-hdf} || die
}
