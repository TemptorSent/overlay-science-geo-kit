# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="5"

inherit autotools-utils


DESCRIPTION="Multiple precision interval arithmetic library based on MPFR"
HOMEPAGE="http://perso.ens-lyon.fr/nathalie.revol/software.html"

MY_FILE_ID=37332
SRC_URI="https://gforge.inria.fr/frs/download.php/${MY_FILE_ID}/${P}.tar.gz"

LICENSE="LGPL-3 GPL-3"
SLOT="0"
KEYWORDS="amd64 x86 ~amd64-linux ~x86-linux"
IUSE="static-libs"

DEPEND=">=dev-libs/gmp-4.1.2
	>=dev-libs/mpfr-2.4.2"
RDEPEND="${DEPEND}"
