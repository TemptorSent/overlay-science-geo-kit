# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION="EPSILON Wavelet compression suite by Alexander Simakov."
HOMEPAGE="https://sourceforge.net/projects/epsilon-project"
SRC_URI="mirror://sourceforge/${PN}-project/${PN}/${PV}/${P}.tar.gz"

LICENSE="GPL-3 LGPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND="dev-libs/popt"
RDEPEND="${DEPEND}"

PATCHES="${FILESDIR}/declare-xmalloc.patch"
