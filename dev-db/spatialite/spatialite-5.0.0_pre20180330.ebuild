


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
LICENSE="MPL-1.1"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~ia64 ~ppc ~ppc64 ~x86"
IUSE="+geos iconv +proj test +xls +xml"

RDEPEND="
	>=dev-db/sqlite-3.8.5:3[extensions(+)]
	sys-libs/zlib
	geos? ( >=sci-libs/geos-3.5.0 )
	proj? ( >=sci-libs/proj-4.8.0 )
	xls? ( >=dev-libs/freexl-1.0.1 )
	xml? ( dev-libs/libxml2 )
"
DEPEND="
	dev-vcs/fossil[ssl]
	${RDEPEND}
"

REQUIRED_USE="test? ( iconv )"

#S="${WORKDIR}/${MY_P}"


src_prepare() {
	default
	eautoreconf
}

src_configure() {
	econf \
		--disable-examples \
		--disable-static \
		--enable-epsg \
		--enable-geocallbacks \
		$(use_enable geos) \
		$(use_enable geos geosadvanced) \
		$(use_enable iconv) \
		$(use_enable proj) \
		$(use_enable xls freexl) \
		$(use_enable xml libxml2)
}

src_install() {
	default
	find "${D}" -name '*.la' -delete || die
}
