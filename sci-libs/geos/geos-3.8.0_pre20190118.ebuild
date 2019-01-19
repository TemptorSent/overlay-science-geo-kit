# Copyright 1999-2018 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python2_7 )

inherit autotools versionator python-single-r1

DESCRIPTION="Geometry engine library for Geographic Information Systems"
HOMEPAGE="http://trac.osgeo.org/geos/"
MY_PV="${PV%_pre*}"

MY_BRANCH="$(get_version_component_range 1-2)"
if [ "${MY_BRANCH}" = "3.8" ] ; then MY_BRANCH="master" ; fi

MY_DATE="${PV##*_pre}"
if	[ "${MY_DATE}" != "${PV}" ] ; then
	inherit git-r3
	EGIT_REPO_URI="https://git.osgeo.org/gitea/geos/geos.git"
	EGIT_COMMIT_DATE="${MY_DATE}"
	EGIT_BRANCH="${MY_BRANCH}"
	SRC_URI=""
else
	MY_DATE=""
	SRC_URI="http://download.osgeo.org/geos/${P}.tar.bz2"
fi

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="amd64 arm ~arm64 ia64 ppc ppc64 x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris"
IUSE="doc python ruby static-libs"
REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"

RDEPEND="
	python? ( ${PYTHON_DEPS} )
	ruby? ( dev-lang/ruby:* )
"
DEPEND="${RDEPEND}
	doc? ( app-doc/doxygen )
	python? ( dev-lang/swig:0 )
	ruby? ( dev-lang/swig:0 )
"

PATCHES=( "${FILESDIR}"/3.4.2-solaris-isnan.patch )

RESTRICT="test"

pkg_setup() {
	use python && python-single-r1_pkg_setup
}

src_prepare() {
	default
	eautoreconf
	echo "#!${EPREFIX}/bin/bash" > py-compile
}

src_configure() {
	econf \
		$(use_enable python) \
		$(use_enable ruby) \
		$(use_enable static-libs static)
}

src_compile() {
	default
	use doc && emake -C "${S}/doc" doxygen-html
}

src_install() {
	use doc && HTML_DOCS=( doc/doxygen_docs/html/. )
	default
	use python && python_optimize "${D}$(python_get_sitedir)"/geos/

	find "${D}" -name '*.la' -delete || die
}