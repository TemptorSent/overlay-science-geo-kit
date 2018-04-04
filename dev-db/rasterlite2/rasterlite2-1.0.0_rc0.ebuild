


# @AUTHOR:
# Chris A. Giorgi <chrisgiorgi@gmail.com>


EAPI=6

inherit versionator autotools

MY_PN="lib${PN}"
MY_PV="$(replace_version_separator '_' '-')"
MY_P="${MY_PN}-${MY_PV}"

DESCRIPTION="A complete Spatial DBMS in a nutshell built upon sqlite"
HOMEPAGE="https://www.gaia-gis.it/gaia-sins/"
SRC_URI="https://www.gaia-gis.it/gaia-sins/${MY_PN}-sources/${MY_P}.tar.gz"
LICENSE="MPL-1.1 GPL-2.0+ LGPL-2.1+ GPL-3+"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~ia64 ~ppc ~ppc64 ~x86"
IUSE="webp lzma"

RDEPEND="
	>=dev-db/sqlite-3.7.5:3[extensions(+)]
	>=dev-db/spatialite-4.3.0
	sys-libs/zlib
	virtual/jpeg
	media-libs/libpng
	media-libs/tiff
	sci-libs/libgeotiff
	webp? ( media-libs/libwebp )
	lzma? ( app-arch/xz-utils )
	x11-libs/cairo
	net-misc/curl
	dev-libs/libxml2
"
DEPEND="${RDEPEND}"

S="${WORKDIR}/${MY_P}"

src_prepare() {
	default
	eautoreconf
}

src_configure() {
	LIBSPATIALITE_LIBS="-lspatialite -lpthread -lsqlite3" econf --disable-static
}

src_install() {
	default
	find "${D}" -name '*.la' -delete || die
}
