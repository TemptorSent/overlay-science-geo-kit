


EAPI=6

inherit cmake-utils versionator flag-o-matic

MY_PV="$(replace_version_separator '_' '-')"
MY_PN="CGAL"
MY_P="${MY_PN}-${MY_PV}"

DESCRIPTION="C++ library for geometric algorithms and data structures"
HOMEPAGE="https://www.cgal.org/"
SRC_URI="
	https://github.com/CGAL/cgal/releases/download/releases/${MY_P}/${MY_P}.tar.xz
	doc? ( https://github.com/CGAL/cgal/releases/download/releases/${MY_P}/${MY_P}-doc_html.tar.xz )"

LICENSE="LGPL-3 GPL-3 Boost-1.0"
SLOT="13/13.0.1"
KEYWORDS="~amd64 ~x86 ~amd64-linux ~x86-linux"
IUSE="doc examples +gmp mpfi +ntl qt5 +tbb"

RDEPEND="
	>=dev-cpp/eigen-3.1
	>=dev-libs/boost-1.48:=[threads]
	>=dev-libs/mpfr-2.2.1:0=
	sys-libs/zlib:=
	x11-libs/libX11:=
	virtual/glu:=
	virtual/opengl:=
	gmp? ( >=dev-libs/gmp-4.2:=[cxx] )
	mpfi? ( >=sci-libs/mpfi-1.4:= )
	ntl? ( >=dev-libs/ntl-5.1:=[threads] )
	qt5? (
		>=dev-qt/qtcore-5.3.0:5
		>=dev-qt/qtgui-5.3.0:5
		>=dev-qt/qtopengl-5.3.0:5
		>=dev-qt/qtsvg-5.3.0:5
		>=dev-qt/qtwidgets-5.3.0:5
	)
	tbb? ( dev-cpp/tbb )
	"
DEPEND="${RDEPEND}
	app-arch/xz-utils
	virtual/pkgconfig"

S="${WORKDIR}/${MY_P}"

PATCHES=(
	"${FILESDIR}/${PN}-4.11.1-fix-buildsystem.patch"
)

src_prepare() {
	cmake-utils_src_prepare
	# modules provided by dev-util/cmake and dev-cpp/eigen
	rm cmake/modules/Find{Eigen3,OpenGL,GLEW}.cmake || die
	sed -e '/install(FILES AUTHORS/d' \
		-i CMakeLists.txt || die
	sed -e 's/find_package(OpenCV QUIET)/&\nfind_package(TBB)/' \
		-e '/list (INSERT CGAL_SUPPORTING_3RD_PARTY_LIBRARIES 0/ s/IPE)/IPE TBB)/' \
		-i CMakeLists.txt || die

	# use C++11 threads instead of boost::thread
	append-cxxflags -std=c++11
}

src_configure() {

	local mycmakeargs=(
		-DCGAL_INSTALL_LIB_DIR="$(get_libdir)/${MY_P}"
		-DCGAL_INSTALL_CMAKE_DIR="$(get_libdir)/cmake/${MY_P}"
		-DCGAL_INSTALL_INC_DIR="include/${MY_P}"
		-DWITH_LEDA=OFF
		-DWITH_Eigen3=ON
		-DWITH_ZLIB=ON
		-DWITH_GMP="$(usex gmp)"
		-DWITH_GMPXX="$(usex gmp)"
		-DWITH_MPFI="$(usex mpfi)"
		-DWITH_NTL="$(usex ntl)"
		-DWITH_CGAL_Qt5="$(usex qt5)"
	)
	if use tbb ; then
		mycmakeargs+=(
			-DWITH_TBB=ON
			-DTBB_INSTALL_DIR="${EPREFIX}/usr"
			-DTBB_INCLUDE_DIR="${EPREFIX}/usr/include"
			-DTBB_LIBRARY_DIRS="${EPREFIX}/usr/$(get_libdir)"
		)
	else
		mycmakeargs+=(
			-DWITH_TBB=OFF
		)
	fi
	cmake-utils_src_configure
}

src_install() {
	use doc && local HTML_DOCS=( "${WORKDIR}"/doc_html/. )
	cmake-utils_src_install
	if use examples; then
		dodoc -r examples demo
		docompress -x /usr/share/doc/${PF}/{examples,demo}
	fi

	# Add ld.so.conf.d entry for the subdir our libs are in.
	mkdir -p "${ED}etc/ld.so.conf.d"
	echo "${EPREFIX}/usr/$(get_libdir)/${MY_P}" >> "${ED}etc/ld.so.conf.d/210-${MY_P}.conf"
}

pkg_postinst() {
	env-update
}
