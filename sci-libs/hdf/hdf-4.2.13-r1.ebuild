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
IUSE="+fortran +szip examples test +static-libs"

REQUIRED_USE="test? ( szip )"

RDEPEND="
	net-libs/libtirpc
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

	# Find libtirpc using pkg-config module and set libs.
	sed -e '14,$ c\
find_package(PkgConfig REQUIRED)\
pkg_search_module(XDR REQUIRED libtirpc)\
set (LINK_LIBS ${LINK_LIBS} ${XDR_STATIC_LIBRARIES})\
set (LINK_SHARED_LIBS ${LINK_SHARED_LIBS} ${XDR_LIBRARIES})'\
		-i config/cmake/FindXDR.cmake || die

	sed -e 's/"@PACKAGE_INCLUDE_INSTALL_DIR@"/& "@XDR_INCLUDE_DIRS@"/' -i config/cmake/hdf4-config.cmake.in || die

	# Fix libs for mfhdf to use libtirpc properly.
	sed -e '/#-*/ {
			N
			/#-*\n# Add file(s) to CMake Install/ i\
if (XDR_FOUND AND NOT HDF_BUILD_XDR_LIB)\
  target_link_libraries (${HDF4_MF_LIB_TARGET} PUBLIC ${XDR_STATIC_LIBRARIES})\
  target_include_directories (${HDF4_MF_LIB_TARGET} PUBLIC ${XDR_STATIC_INCLUDE_DIRS})\
  if (BUILD_SHARED_LIBS)\
    target_link_libraries (${HDF4_MF_LIBSH_TARGET} PUBLIC ${XDR_LIBRARIES})\
    target_include_directories (${HDF4_MF_LIBSH_TARGET} PUBLIC ${XDR_INCLUDE_DIRS})\
  endif ()\
endif ()\

			}'\
		-i mfhdf/libsrc/CMakeLists.txt || die
	# End libtirpc fixup.

	# Fixup doc install dir.
	sed -e '/HDF4_Examples.cmake file/,/README.txt file/ { s/.*${HDF4_INSTALL_DATA_DIR}/&\/doc\/'"${PF}"'\/examples/ }' \
		-e '/README.txt file/,$ { s/.*${HDF4_INSTALL_DATA_DIR}/&\/doc\/'"${PF}"'/ }'\
		-i CMakeInstallation.cmake || die

	# Fixup examples install dir.
	sed -re 's|add_executable \(([[:graph:]]+)[[:space:]].*|&\n  set(all_examples ${all_examples} \1 )\n  set_target_properties(\1 PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${HDF4_BINARY_DIR}/HDF4Examples")|'\
		-e '$ a\
install( TARGETS ${all_examples} RUNTIME DESTINATION "${HDF4_INSTALL_DATA_DIR}/doc/'"${PF}"'/examples" COMPONENT hdfexamples)' \
		-i */examples/CMakeLists.txt */*/examples/CMakeLists.txt || die

	# Fixup to allow disabling of static-libs.
	sed -e 's/set (install_targets .*${HDF4_[_[:alnum:]]*_LIB_TARGET})/if (BUILD_STATIC_LIBS)\n&\nendif ()/' \
		-i */*/CMakeLists.txt || die
}

src_configure() {
	CC="$(tc-getCC)"

	mycmakeargs=(
		-DBUILD_SHARED_LIBS=TRUE
		-DBUILD_STATIC_LIBS=$(usex static-libs)
		-DBUILD_TESTING=$(usex test)
		-DHDF4_INSTALL_LIB_DIR="$(get_libdir)"
		-DHDF4_INSTALL_INCLUDE_DIR="include/hdf"
		-DHDF4_INSTALL_CMAKE_DIR="$(get_libdir)/cmake"
		-DHDF4_ENABLE_SZIP_SUPPORT=$(usex szip)
		-DHDF4_ENABLE_NETCDF=$(usex test)
		-DHDF4_BUILD_FORTRAN=$(usex fortran)
		-DHDF4_BUILD_TOOLS=TRUE
		-DHDF4_BUILD_UTILS=TRUE
		-DHDF4_BUILD_EXAMPLES=$(usex examples)
		-DHDF4_PACK_EXAMPLES=$(usex examples)
	)

	cmake-utils_src_configure
}

src_install() {
	cmake-utils_src_install
	# Set to use shared libs by default
	sed -e '/component(static)/,/endif/ s/static/shared/g' -i "${ED}usr/share/cmake/hdf4/hdf4-config.cmake" || die

	use static-libs || prune_libtool_files --all

	# Remove duplicate copy of examples directory
	rm -r "${ED}/usr/share/doc/${PF}/examples/HDF4Examples" || die

	# Install man pages, renaming ncdump and ncgen with suffix -hdf
	doman ${S}/man/*.1
	cp mfhdf/ncdump/ncdump.1 "${ED}usr/share/man/man1/ncdump-hdf.1" || die
	cp mfhdf/ncgen/ncgen.1 "${ED}usr/share/man/man1/ncgen-hdf.1" || die

	dodoc release_notes/{RELEASE,HISTORY,bugs_fixed,misc_docs}.txt

	# Rename ncdump and ncgen with -hdf prefix
	pushd "${ED}usr" > /dev/null
	mv bin/ncdump{,-hdf} || die
	mv bin/ncgen{,-hdf} || die
	popd
}
