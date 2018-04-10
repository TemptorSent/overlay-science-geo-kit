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

src_prepare() {
#	sed -e '/## Is XDR support present/,/AC_HEADER_STDC/ s/cygwin//g' -i configure.ac
#	sed -i -e 's/-R/-L/g' config/commence.am || die #rpath
#	eautoreconf

	use libtirpc && sed -e '14,$ c\
include(FindPkgConfig)\
pkg_search_module(XDR REQUIRED libtirpc)'\
		-i config/cmake/FindXDR.cmake

	[[ $(tc-getFC) = *gfortran ]] && append-fflags -fno-range-check
	cmake-utils_src_prepare
}

src_configure() {
#	econf \
#		--enable-shared \
#		--enable-production=gentoo \
#		--disable-netcdf \
#		$(use_enable fortran) \
#		$(use_enable static-libs static) \
#		$(use_with szip szlib) \


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
