


EAPI=6

inherit cmake-utils flag-o-matic

MY_P="SFCGAL-${PV}"

DESCRIPTION="CGAL C++ wrapper library aiming to support ISO 19107:2013 and OGC Simple Feature Access 1.2 for 3D operations."
HOMEPAGE="https://sfcgal.org"
SRC_URI="https://github.com/Oslandia/SFCGAL/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="LGPL-2+"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="osg"


DEPEND="
	>=dev-util/cmake-2.8.6
	osg? ( >=sci-mathematics/cgal-4.10.1[gmp,qt5] )
	!osg? ( >=sci-mathematics/cgal-4.10.1[gmp] )
	>=dev-libs/boost-1.54
	>=dev-libs/mpfr-2.2.1
	>=dev-libs/gmp-4.2
	osg? ( >=dev-games/openscenegraph-3.1[qt5] )
"

RDEPEND="${DEPEND}"

PATCHES=( "${FILESDIR}/${P}-fix-cgal-gmpxx-0.patch" "${FILESDIR}/${P}-fix-cgal-gmpxx-1.patch" )

S="${WORKDIR}/${MY_P}"

src_prepare() {
	append-cxxflags $(test-flags-CXX -std=c++11)
	cmake-utils_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DSFCGAL_WITH_OSG=$(usex osg)
	)
	cmake-utils_src_configure
}
