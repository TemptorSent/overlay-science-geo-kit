# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit cmake-multilib

DESCRIPTION="Extended-Rice lossless compression algorithm implementation"
HOMEPAGE="http://www.hdfgroup.org/doc_resource/SZIP/"
SRC_URI="https://support.hdfgroup.org/ftp/lib-external/${PN}/${PV}/src/${P}.tar.gz"
LICENSE="szip"

SLOT="0/${PV}"
KEYWORDS="alpha amd64 ~arm ~arm64 ~hppa ia64 ~ppc ppc64 sparc x86 ~x86-fbsd ~amd64-linux ~x86-linux"

IUSE="+static-libs test"
RDEPEND="!sci-libs/libaec[szip]"
DEPEND="
	>=dev-util/cmake-3.2.2
"

src_unpack() {
	# Fix archive which was compressed twice and unpack.
	zcat "${DISTDIR}/${A}" > "${T}/${A}"
	unpack "${T}/${A}"
}

src_prepare() {
	default

	# Allow conditional installation of static libs and fixes output lib names.
	sed -e 's/set (install_targets ${SZIP_LIB_TARGET})/if (BUILD_STATIC_LIBS)\n&\nendif ()/' \
		-e '/set_target_properties(${SZIP_LIB_TARGET} PROPERTIES/ a\
	OUTPUT_NAME "${SZIP_LIB_CORENAME}"' \
		-e '/set_target_properties(${SZIP_LIBSH_TARGET} PROPERTIES/ a\
	OUTPUT_NAME "${SZIP_LIB_CORENAME}"' \
		-i src/CMakeLists.txt || die

	cmake-utils_src_prepare
}

multilib_src_configure() {
	local mycmakeargs=(
		-DSZIP_INSTALL_LIB_DIR="$(get_libdir)"
		-DSZIP_INSTALL_CMAKE_DIR="$(get_libdir)/cmake/szip"
		-DSZIP_INSTALL_DATA_DIR="share/doc/${P}"
		-DBUILD_STATIC_LIBS=$(usex static-libs)
		-DBUILD_TESTING=$(usex test)
	)
	cmake-utils_src_configure
}
