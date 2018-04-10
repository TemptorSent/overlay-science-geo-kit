# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit autotools flag-o-matic

DESCRIPTION="Implementation of a C++ SDK for DAP 2.0 and 3.2"
HOMEPAGE="http://opendap.org/"
SRC_URI="http://www.opendap.org/pub/source/${P}.tar.gz"

LICENSE="|| ( LGPL-2.1 URI )"
SLOT="0"
KEYWORDS="amd64 ~ppc ~ppc64 x86 ~amd64-linux ~x86-linux"
IUSE="static-libs test +libtirpc"

RDEPEND="
	!libtirpc? ( elibc_glibc? ( sys-libs/glibc[rpc(-)] ) )
	libtirpc? ( net-libs/libtirpc )
	net-libs/rpcsvc-proto
	>=dev-libs/libxml2-2.7.0:2
	>=net-misc/curl-7.19.0
	sys-libs/zlib"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	>=sys-devel/flex-2.5.35
	test? ( dev-util/cppunit )"

PATCHES=(
	"${FILESDIR}/${PN}-3.18.1-fix-buildsystem.patch"
	"${FILESDIR}/${PN}-3.18.1-fix-c++14.patch"
	"${FILESDIR}/${PN}-3.18.1-disable-cache-test.patch"
	"${FILESDIR}/${PN}-3.18.1-disable-dmr-tests.patch"
	"${FILESDIR}/${PN}-3.18.1-disable-net-tests.patch"
	#"${FILESDIR}/${PN}-3.18.1-disable-broken-tests.patch"
)

src_prepare() {
	default
	# TODO - Clean up CFLAGS and LIBS handling
	if use libtirpc ; then

		eapply "${FILESDIR}/${PN}-3.19.1-use-libtirpc.patch"
		# Fix CFLAGS to use libtirpc if defined -- this is the brute-force method.
		sed -e 's/$(XML2_CFLAGS)/& $(TIRPC_CFLAGS)/' \
			-e 's/$(CURL_CFLAGS)/& $(TIRPC_CFLAGS)/' \
			-e 's/$(AM_CPPFLAGS)/& $(TIRPC_CFLAGS)/' \
			-i Makefile.am */Makefile.am */*/Makefile.am

		# Fix dap-config.in to include tirpc cflags as needed.
		sed -e 's|@CURL_CFLAGS@|& @TIRPC_CFLAGS@|' -i dap-config.in

		# Fix .pc.in files to include tirpc cflags and libs as needed.
		sed -e 's|^Cflags:|& @TIRPC_CFLAGS@|' \
			-e 's|^Libs:|& @TIRPC_LIBS@|' \
			-i *.pc.in
	fi

	eautoreconf
}

src_configure() {
	# bug 619144
	append-cxxflags -std=c++14
	econf \
		--enable-shared \
		$(use_enable static-libs static)
		#$(use_with libtirpc)
}

src_install() {
	default

	# package provides .pc files
	find "${D}" -name '*.la' -delete || die
}
