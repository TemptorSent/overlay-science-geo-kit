# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit eutils java-pkg-opt-2 flag-o-matic

DESCRIPTION="Proj.4 cartographic projection software"
HOMEPAGE="http://trac.osgeo.org/proj/"
SRC_URI="
	http://download.osgeo.org/proj/${P}.tar.gz
	http://download.osgeo.org/proj/${PN}-datumgrid-1.6.zip
	http://download.osgeo.org/proj/hpgn_ntv2.zip
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~ia64 ~ppc ~ppc64 ~s390 ~sparc ~x86 ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos"
IUSE="java static-libs"

RDEPEND=""
DEPEND="
	app-arch/unzip
	java? ( >=virtual/jdk-1.5 )"

src_unpack() {
	unpack ${P}.tar.gz
	cd "${S}"/nad || die
	mv README README.NAD || die
	unpack ${PN}-datumgrid-1.6.zip
	unpack hpgn_ntv2.zip
}

src_configure() {
	if use java; then
		export JAVACFLAGS="$(java-pkg_javac-args)"
		append-cflags "$(java-pkg_get-jni-cflags)"
	fi
	econf \
		$(use_enable static-libs static) \
		$(use_with java jni)
}

src_install() {
	default
	cd nad || die
	dodoc README.{NAD,DATUMGRID}
	newdoc README.TXT README.HPGN
	insinto /usr/share/proj
	insopts -m 755
	doins test27 test83
	insopts -m 644
	doins pj_out27.dist pj_out83.dist
	prune_libtool_files
}
