# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit multilib cmake-utils flag-o-matic

MY_P="PDAL-${PV}"

DESCIPTION=="C/C++ Point Data Abstraction Library for translating and processing point cloud data, particularly LiDAR."
HOMEPAGE="https://pdal.io"
SRC_URI="http://download.osgeo.org/pdal/${MY_P}-src.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="+xml2 +curl oracle"


DEPEND="
	>=dev-util/cmake-2.8.11
	>=sci-libs/geos-3.3
	>=sci-libs/gdal-1.9
	>=sci-libs/libgeotiff-1.3.0
	>=sci-libs/proj-4.9.0
	>=dev-libs/jsoncpp-1.6.2
	<=dev-libs/jsoncpp-1.8.1
	>=sci-geosciences/laszip-3.1.1:3
	curl? ( net-misc/curl )
	xml2? ( >=dev-libs/libxml2-2.7.0 )
	oracle? ( >=dev-db/oracle-instant-client-12 ) 
"

RDEPEND="${DEPEND}"

S="${WORKDIR}/${MY_P}-src"

src_prepare() {
	append-cxxflags $(test-flags-CXX -std=c++11)
	cmake-utils_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DBUILD_SHARED_LIBS=1
		-DLASZIP_INCLUDE_DIR="${EPREFIX}/usr/include/laszip-3"
		-DLASZIP_LIBRARY="${EPREFIX}/usr/$(get_libdir)/liblaszip.so.3"
	)
	cmake-utils_src_configure
}
