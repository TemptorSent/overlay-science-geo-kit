# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit cmake-utils flag-o-matic

DESCRIPTION="Library for free and lossless compression of the LAS LiDAR format"
HOMEPAGE="http://www.laszip.org/"
SRC_URI="https://github.com/LASzip/LASzip/releases/download/${PV}/${PN}-src-${PV}.tar.gz"

LICENSE="LGPL-2.1+"
SLOT="8/8.0.0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"

PATCHES="${FILESDIR}/${PN}-3.1.1-include-install-dir.patch"

S="${WORKDIR}/${PN}-src-${PV}"

src_prepare() {

	append-cxxflags $(test-flags-CXX -std=c++11)
	append-cflags $(test-flags-CC -fno-strict-aliasing)
	cmake-utils_src_prepare

	# Fixup CXX flags
	sed -e '/set(LASZIP_COMMON_CXX_FLAGS/ s|-isystem /usr/local/include||' -i cmake/unix_compiler_options.cmake

	# Install cmake modules for our libraries.
	sed -e 's|endmacro(LASZIP_ADD_LIBRARY)|install(EXPORT LASZIPTargets FILE ${_name}Config.cmake DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/laszip)\n&|' \
		-e '/macro(LASZIP_ADD_INCLUDES/,/endmacro(LASZIP_ADD_INCLUDES)/ s|/${_subdir}||' \
		-i cmake/macros.cmake

	# Install laszip-config and pkgconfig files.
	sed 's|add_subdirectory(dll)|&\nadd_subdirectory(example)|' -i CMakeLists.txt

	sed -e 's|^libdir.*|&\nincludedir=@includedir@\nlibname=@libname@|' \
		-e 's|INCLUDES=.*|INCLUDES="-I${includedir} "|' \
		-e 's|LIBS=.*|LIBS="-L${libdir} -l${libname} "|' \
		-e 's|laszip-config|@libname@-config|' \
		-e 's|@CMAKE_C_FLAGS@|${INCLUDES}|' \
		-e 's|@CFLAGS@||' -e 's|@CXXFLAGS@||' \
		-i example/laszip-config.in

# Replace the CMakeLists.txt for building laszip-config and pkgconfig files with our own.
	cat > example/CMakeLists.txt <<EOF
if(UNIX)
	# laszip-config
	set(prefix \${CMAKE_INSTALL_PREFIX})
	set(exec_prefix \\\${prefix})
	set(libdir \\\${exec_prefix}/\${LASZIP_LIB_INSTALL_DIR})
	set(includedir \\\${prefix}\${LASZIP_INCLUDE_INSTALL_ROOT})
	set(libname "laszip")
	GET_DIRECTORY_PROPERTY(LASZIP_DEFINITIONS DIRECTORY ../src COMPILE_DEFINITIONS)
	set(LASZIP_CONFIG_DEFINITIONS "")
	foreach(definition \${LASZIP_DEFINITIONS})
		set(LASZIP_CONFIG_DEFINITIONS "\${LASZIP_CONFIG_DEFINITIONS} -D\${definition}")
	endforeach()

	configure_file(\${CMAKE_CURRENT_SOURCE_DIR}/laszip-config.in \${CMAKE_CURRENT_BINARY_DIR}/laszip-config @ONLY)

	install(FILES \${CMAKE_CURRENT_BINARY_DIR}/laszip-config
		DESTINATION bin/
		PERMISSIONS OWNER_READ OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
	)

	# laszip_api-config
	set(libname "laszip_api")
	GET_DIRECTORY_PROPERTY(LASZIP_API_DEFINITIONS DIRECTORY ../dll COMPILE_DEFINITIONS)
	set(LASZIP_API_CONFIG_DEFINITIONS "")
	foreach(definition \${LASZIP_API_DEFINITIONS})
		set(LASZIP_API_CONFIG_DEFINITIONS "\${LASZIP_API_CONFIG_DEFINITIONS} -D\${definition}")
	endforeach()

	configure_file(\${CMAKE_CURRENT_SOURCE_DIR}/laszip-config.in \${CMAKE_CURRENT_BINARY_DIR}/laszip_api-config @ONLY)

	install(FILES \${CMAKE_CURRENT_BINARY_DIR}/laszip_api-config
		DESTINATION bin/
		PERMISSIONS OWNER_READ OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
	)


	# pkgconfig
	set(PKGCFG_PREFIX "\${CMAKE_INSTALL_PREFIX}")
	set(PKGCFG_INC_DIR "\\\${prefix}/\${LASZIP_INCLUDE_INSTALL_ROOT}")
	set(PKGCFG_LIB_DIR "\\\${exec_prefix}/\${LASZIP_LIB_INSTALL_DIR}")
	set(PKGCFG_REQUIRES  "")
	set(PKGCFG_VERSION \${VERSION})
	set(PKGCFG_COMPILE_FLAGS "\${CMAKE_CXX_FLAGS}")

	set(PKGCFG_LINK_FLAGS "-llaszip")
	configure_file(\${CMAKE_CURRENT_SOURCE_DIR}/laszip.pc.in \${CMAKE_CURRENT_BINARY_DIR}/laszip.pc @ONLY)

	install(FILES \${CMAKE_CURRENT_BINARY_DIR}/laszip.pc
		DESTINATION \${LASZIP_LIB_INSTALL_DIR}/pkgconfig
		PERMISSIONS OWNER_READ GROUP_READ WORLD_READ
	)

	set(PKGCFG_LINK_FLAGS "-llaszip_api")
	configure_file(\${CMAKE_CURRENT_SOURCE_DIR}/laszip.pc.in \${CMAKE_CURRENT_BINARY_DIR}/laszip_api.pc @ONLY)

	install(FILES \${CMAKE_CURRENT_BINARY_DIR}/laszip_api.pc
		DESTINATION \${LASZIP_LIB_INSTALL_DIR}/pkgconfig
		PERMISSIONS OWNER_READ GROUP_READ WORLD_READ
	)

endif(UNIX)
EOF


}

src_configure() {
	local mycmakeargs=(
		-DLASZIP_INCLUDE_INSTALL_ROOT="include/laszip-3"
	)

	cmake-utils_src_configure
}

src_install() {
	cmake-utils_src_install
	#Create symlink so "#include <laszip/laszip_api.h>" works as expected
	dodir "${EPREFIX}/usr/include/laszip-3"
	dosym  . "${EPREFIX}/usr/include/laszip-3/laszip"
}


