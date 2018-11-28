
EAPI=6

inherit multilib cmake-utils flag-o-matic

MY_P="PDAL-${PV}"

DESCIPTION=="C/C++ Point Data Abstraction Library for translating and processing point cloud data, particularly LiDAR."
HOMEPAGE="https://pdal.io"
SRC_URI="https://github.com/PDAL/PDAL/releases/download/${PV}/${MY_P}-src.tar.bz2"

LICENSE="BSD"
SLOT="7/8.0.0" # From CMakeLists.txt, PDAL_API_VERSION/PDAL_BUILD_VERSION
KEYWORDS="*"
IUSE="+xml2 +curl unwind postgres oracle zlib zstd"


DEPEND="
	>=dev-util/cmake-3.5
	>=sci-libs/geos-3.3
	>=sci-libs/gdal-1.9
	>=sci-libs/libgeotiff-1.3.0
	>=sci-libs/proj-4.9.0
	sci-libs/hdf5
	>=dev-libs/jsoncpp-1.6.2
	>=sci-geosciences/laszip-3.2.2:8
	unwind? (
		sys-libs/libunwind
		dev-libs/libexecinfo
	)
	curl? ( net-misc/curl )
	xml2? ( >=dev-libs/libxml2-2.7.0 )
	oracle? ( >=dev-db/oracle-instant-client-12 )
	postgres? ( dev-db/postgresql )
	zlib? ( sys-libs/zlib )
	zstd? ( app-arch/zstd )
"
# To add:
# (BUILD_PLUGIN_GEOWAVE) GeoWave, Jace, JNI
# (WITH_LAZPERF) Lazperf
# (WITH_LZMA) LibLZMA
# Nitro-2.6
# OSG (OpenSceneGraph)
# PostgreSQL
# PythonInterp PythonLibs-2.4 NumPy-1.5
# spatialite>=4.2.0
# SQLite3
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
		-DLASZIP_LIBRARY="${EPREFIX}/usr/$(get_libdir)/liblaszip.so.8"
	)
	cmake-utils_src_configure
}
