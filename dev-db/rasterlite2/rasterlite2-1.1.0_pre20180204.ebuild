


# @AUTHOR:
# Chris A. Giorgi <chrisgiorgi@gmail.com>


EAPI=6

inherit fossil versionator autotools

MY_PN="lib${PN}"
MY_PV="$(replace_version_separator '_' '-')"
MY_P="${MY_PN}-${MY_PV}"
MY_PVR="${PV##*.*_*[^0-9]}"

DESCRIPTION="A complete Spatial DBMS in a nutshell built upon sqlite"
HOMEPAGE="https://www.gaia-gis.it/gaia-sins/"
#SRC_URI="https://www.gaia-gis.it/gaia-sins/${MY_PN}-sources/${MY_P}.tar.gz"
EFOSSIL_REPO_URI="https://www.gaia-gis.it/fossil/${MY_PN}"
if [ ${#MY_PVR} -eq  8 ]  && [ ${MY_PVR} -lt 50000000 ] ; then
	EFOSSIL_COMMIT_DATE="${MY_PVR:0:4}-${MY_PVR:4:2}-${MY_PVR:6:2}"
fi
LICENSE="MPL-1.1 GPL-2.0+ LGPL-2.1+ GPL-3+"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~ia64 ~ppc ~ppc64 ~x86"
IUSE="webp lzma charls"

# Note: Fails to build tools with openjpeg disabled;
# setting it as hard dep until upstream is fixed.
RDEPEND="
	>=dev-db/sqlite-3.7.5:3[extensions(+)]
	>=dev-db/spatialite-4.3.0
	sys-libs/zlib
	virtual/jpeg
	media-libs/libpng
	media-libs/tiff
	sci-libs/libgeotiff
	media-libs/openjpeg
	charls? ( media-libs/charls:1 )
	webp? ( media-libs/libwebp )
	lzma? ( app-arch/xz-utils )
	x11-libs/cairo
	net-misc/curl
	dev-libs/libxml2
"
DEPEND="
	dev-vcs/fossil[ssl]
	${RDEPEND}
"

PATCHES=( 
	"${FILESDIR}/rasterlite2-dev-charls-pkgconfig.patch"
	"${FILESDIR}/rasterlite2-dev-openjpeg-2.3.patch"
)

src_prepare() {
	default
	eautoreconf
}

src_configure() {
	LIBSPATIALITE_LIBS="-lspatialite -lpthread -lsqlite3" econf \
	--disable-static \
	--enable-openjpeg \
	$(use_enable webp) \
	$(use_enable lzma) \
	$(use_enable charls)
}

src_install() {
	default
	find "${D}" -name '*.la' -delete || die
}
