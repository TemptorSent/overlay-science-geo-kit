# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit eutils cmake-utils

DESCRIPTION="Scientific library and interface for array oriented data access"
HOMEPAGE="http://www.unidata.ucar.edu/software/netcdf/"
SRC_URI="https://github.com/Unidata/netcdf-c/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="UCAR-Unidata"
SLOT="0/11"
KEYWORDS="~amd64 ~arm ~ia64 ~ppc ~ppc64 ~x86 ~amd64-linux ~x86-linux"
IUSE="+dap examples +hdf +hdf5 mpi +static-libs +szip test +tools"

RDEPEND="
	dap? ( net-misc/curl:0= )
	hdf? ( sci-libs/hdf:0= sci-libs/hdf5:0= )
	hdf5? ( sci-libs/hdf5:0=[hl(+),mpi=,szip=,zlib] )"
DEPEND="${RDEPEND}"
# doc generation is missing many doxygen files in tar ball
#	doc? ( app-doc/doxygen[dot] )"

REQUIRED_USE="test? ( tools ) szip? ( hdf5 ) mpi? ( hdf5 )"

S="${WORKDIR}/${PN}-c-${PV}"

src_prepare() {
	cmake-utils_src_prepare
	# Fix detection of hdf includes to use /usr/include/hdf
	sed -e 's/FIND_PATH(MFHDF_H_INCLUDE_DIR mfhdf.h)/FIND_PATH(MFHDF_H_INCLUDE_DIR mfhdf.h PATH_SUFFIXES hdf)/' -i CMakeLists.txt
	# Give ourselves a sane way of passing CFLAGS
	sed -e 's/: ${CFLAGS=""}/: ${CFLAGS="${NC_CFLAGS}")/'
}

src_configure() {
#	local myconf
#	if use mpi; then
#		export CC=mpicc
#		myconf="--enable-parallel"
#		use test && myconf+=" --enable-parallel-tests"
#	fi
#	econf "${myconf}" \
#		--disable-examples \
#		--disable-dap-remote-tests \
#		$(use_enable dap) \
#		$(use_enable hdf hdf4) \
#		$(use_enable hdf5 netcdf-4) \
#		$(use_enable static-libs static) \
#		$(use_enable tools utilities)

#	NC_CFLAGS="-I${EPREFIX}/usr/include/hdf"
	mycmakeargs=(
		-DENABLE_DAP=$(usex dap)
		-DENABLE_HDF4=$(usex hdf)
		-DUSE_HDF5=$(usex hdf5)
		-DENABLE_NETCDF_4=$(usex hdf5)
		-BUILD_UTILITIES=$(usex tools)
	)
	cmake-utils_src_configure
}

#src_test() {
#	# fails parallel tests: bug #621486
#	emake check -j1
#}

#src_install() {
#	default
#	use examples && dodoc -r examples
#	prune_libtool_files
#}
