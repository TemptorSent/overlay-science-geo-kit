


EAPI=6

inherit slotter versionator cmake-utils

DESCRIPTION="CharLS is an image compression library which provides a JPEG-LS compliant compressor/decompressor codec."
HOMEPAGE="https://github.com/team-charls/charls/wiki"
SRC_URI="https://github.com/team-charls/charls/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="BSD-3-Clause"
SLOT_MAJOR_COMPONENTS="1"
SLOT_MAJOR="$(get_version_component_range ${SLOT_MAJOR_COMPONENTS} ${PV})"
SLOT="${SLOT_MAJOR}/${PV}"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"
PATCHES=( "${FILESDIR}/charls-${PV}" )


src_prepare() {
	sed -e "s|DESTINATION include/CharLS|DESTINATION include/CharLS-${SLOT_MAJOR}|" -i ${S}/CMakeLists.txt
	cp "${FILESDIR}/charls.pc.cmakein" "${S}/src"
	cmake-utils_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DBUILD_SHARED_LIBS=ON
	)
	cmake-utils_src_configure
}

src_install() {
	cmake-utils_src_install

	# Setup symlink so includes using '#include <CharLS/blah>' work as expected
	dosym . "${EPREFIX}/usr/include/CharLS-${SLOT_MAJOR}/CharLS"

	slotter-enversion_solibdirs
}

pkg_postinst() {
	slotter-pkg_postinst
}
