# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit cmake-utils flag-o-matic

DESCRIPTION="Library for free and lossless compression of the LAS LiDAR format"
HOMEPAGE="http://www.laszip.org/"
SRC_URI="https://github.com/LASzip/LASzip/releases/download/${PV}/${PN}-src-${PV}.tar.gz"

LICENSE="LGPL-2.1+"
SLOT="3/3.1.1"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND=""

PATCHES="${FILESDIR}/${PN}-3.1.1-include-install-dir.patch"

S="${WORKDIR}/${PN}-src-${PV}"

src_prepare() {
	append-cxxflags $(test-flags-CXX -std=c++11)
	append-cflags $(test-flags-CC -fno-strict-aliasing)
	cmake-utils_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DLASZIP_INCLUDE_INSTALL_ROOT="include/laszip-3"
	)

	cmake-utils_src_configure
}
src_install() {
	cmake-utils_src_install
	#Create symlink so "#include <laszip/laszip_api.h>" works as expected
	dosym  "${EPREFIX}/usr/include/laszip-3" "${EPREFIX}/usr/include/laszip-3/laszip"
}


RDEPEND="${DEPEND}"
