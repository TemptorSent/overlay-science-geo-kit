# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: fossil.eclass
# @MAINTAINER:
# portage
# @AUTHOR:
# Chris A. Giorgi <chrisgiorgi@gmail.com>
# @BLURB: Eclass for fetching and unpacking fossil-scm repositories.
# @DESCRIPTION:
# Eclass to ease the pain of maintaining ebuilds based on fossil-scm hosted sources.

# This eclass heavily based on git-r3.eclass

case "${EAPI:-0}" in
	0|1|2|3|4|5|6)
		;;
	*)
		die "Unsupported EAPI=${EAPI} (unknown) for ${ECLASS}"
		;;
esac

if [ -z "$_FOSSIL" ] ; then

EXPORT_FUNCTIONS src_unpack

DEPEND="dev-vcs/fossil"

# @ECLASS-VARIABLE: EFOSSIL_STORE_DIR
# @DESCRIPTION:
# Storage directory for fossil sources.
#
# This is intended to be set by user in make.conf. Ebuilds must not set
# it.
#
# EFOSSIL_STORE_DIR=${DISTDIR}/fossil-src

# @ECLASS-VARIABLE: EFOSSIL_MIRROR_URI
# @DEFAULT_UNSET
# @DESCRIPTION:
# 'Top' URI to a local fossil mirror. If specified, the eclass will try
# to fetch from the local mirror instead of using the remote repository.
#
# The mirror needs to follow EFOSSIL_STORE_DIR structure. The directory
# created by eclass can be used for that purpose.
#
# Example:
# @CODE
# EFOSSIL_MIRROR_URI="fossil://mirror.lan/"
# @CODE

# @ECLASS-VARIABLE: EFOSSIL_REPO_URI
# @REQUIRED
# @DESCRIPTION:
# URIs to the repository, e.g. fossil://foo, https://foo. If multiple URIs
# are provided, the eclass will consider them as fallback URIs to try
# if the first URI does not work. For supported URI syntaxes, read up
# the manpage for fossil(1).
#
# It can be overriden via env using ${PN}_LIVE_REPO variable.
#
# Can be a whitespace-separated list or an array.
#
# Example:
# @CODE
# EFOSSIL_REPO_URI="fossil://a/b.fossil https://c/d.fossil"
# @CODE

# @ECLASS-VARIABLE: EVCS_OFFLINE
# @DEFAULT_UNSET
# @DESCRIPTION:
# If non-empty, this variable prevents any online operations.

# @ECLASS-VARIABLE: EVCS_UMASK
# @DEFAULT_UNSET
# @DESCRIPTION:
# Set this variable to a custom umask. This is intended to be set by
# users. By setting this to something like 002, it can make life easier
# for people who do development as non-root (but are in the portage
# group), and then switch over to building with FEATURES=userpriv.
# Or vice-versa. Shouldn't be a security issue here as anyone who has
# portage group write access already can screw the system over in more
# creative ways.

# @ECLASS-VARIABLE: EFOSSIL_BRANCH
# @DEFAULT_UNSET
# @DESCRIPTION:
# The branch name to check out. If unset, the upstream default (HEAD)
# will be used.
#
# It can be overriden via env using ${PN}_LIVE_BRANCH variable.

# @ECLASS-VARIABLE: EFOSSIL_COMMIT
# @DEFAULT_UNSET
# @DESCRIPTION:
# The tag name or commit identifier to check out. If unset, newest
# commit from the branch will be used. Note that if set to a commit
# not on HEAD branch, EFOSSIL_BRANCH needs to be set to a branch on which
# the commit is available.
#
# It can be overriden via env using ${PN}_LIVE_COMMIT variable.

# @ECLASS-VARIABLE: EFOSSIL_COMMIT_DATE
# @DEFAULT_UNSET
# @DESCRIPTION:
# Attempt to check out the repository state for the specified timestamp.
# The date should be in format understood by 'fossil rev-list'. The commits
# on EFOSSIL_BRANCH will be considered.
#
# The eclass will select the last commit with commit date preceding
# the specified date. When merge commits are found, only first parents
# will be considered in order to avoid switching into external branches
# (assuming that merges are done correctly). In other words, each merge
# will be considered alike a single commit with date corresponding
# to the merge commit date.
#
# It can be overriden via env using ${PN}_LIVE_COMMIT_DATE variable.

# @ECLASS-VARIABLE: EFOSSIL_CHECKOUT_DIR
# @DESCRIPTION:
# The directory to check the fossil sources out to.
#
# EFOSSIL_CHECKOUT_DIR=${WORKDIR}/${P}

# @FUNCTION: _fossil_env_setup
# @INTERNAL
# @DESCRIPTION:
# Set the eclass variables as necessary for operation. This can involve
# setting EFOSSIL_* to defaults or ${PN}_LIVE_* variables.
_fossil_env_setup() {
	debug-print-function ${FUNCNAME} "$@"


	local esc_pn livevar
	esc_pn=${PN//[-+]/_}
	[[ ${esc_pn} == [0-9]* ]] && esc_pn=_${esc_pn}

	livevar=${esc_pn}_LIVE_REPO
	EFOSSIL_REPO_URI=${!livevar-${EFOSSIL_REPO_URI}}
	[[ ${!livevar} ]] \
		&& ewarn "Using ${livevar}, no support will be provided"

	livevar=${esc_pn}_LIVE_BRANCH
	EFOSSIL_BRANCH=${!livevar-${EFOSSIL_BRANCH}}
	[[ ${!livevar} ]] \
		&& ewarn "Using ${livevar}, no support will be provided"

	livevar=${esc_pn}_LIVE_COMMIT
	EFOSSIL_COMMIT=${!livevar-${EFOSSIL_COMMIT}}
	[[ ${!livevar} ]] \
		&& ewarn "Using ${livevar}, no support will be provided"

	livevar=${esc_pn}_LIVE_COMMIT_DATE
	EFOSSIL_COMMIT_DATE=${!livevar-${EFOSSIL_COMMIT_DATE}}
	[[ ${!livevar} ]] \
		&& ewarn "Using ${livevar}, no support will be provided"

	if [[ ${EFOSSIL_COMMIT} && ${EFOSSIL_COMMIT_DATE} ]]; then
		die "EFOSSIL_COMMIT and EFOSSIL_COMMIT_DATE can not be specified simultaneously"
	fi

}

# @FUNCTION: _fossil_set_fossildb
# @USAGE: <repo-uri>
# @INTERNAL
# @DESCRIPTION:
# Obtain the local repository path and set it as FOSSIL_DB. Creates
# a new repository if necessary.
#
# <repo-uri> may be used to compose the path. It should therefore be
# a canonical URI to the repository.
_fossil_set_fossildb() {
	debug-print-function ${FUNCNAME} "$@"

	local repo_name=${1#*://*/}

	# strip the trailing slash
	repo_name=${repo_name%/}

	# strip common prefixes to make paths more likely to match
	# e.g. fossil://X/Y.fossil vs https://X/fossil/Y.fossil
	# (but just one of the prefixes)
	case "${repo_name}" in
		# pretty common
		fossil/*) repo_name=${repo_name#fossil/};;
		# gentoo.org
		fossilroot/*) repo_name=${repo_name#fossilroot/};;
		# sourceforge
		p/*) repo_name=${repo_name#p/};;
		# kernel.org
		pub/scm/*) repo_name=${repo_name#pub/scm/};;
	esac
	# ensure a .fossil suffix, same reason
	repo_name=${repo_name%.fossil}.fossil
	# now replace all the slashes
	repo_name=${repo_name//\//_}

	local distdir=${PORTAGE_ACTUAL_DISTDIR:-${DISTDIR}}
	: ${EFOSSIL_STORE_DIR:=${distdir}/fossil-src}

	FOSSIL_DB=${EFOSSIL_STORE_DIR}/${repo_name}

	if [[ ! -d ${EFOSSIL_STORE_DIR} && ! ${EVCS_OFFLINE} ]]; then
		(
			addwrite /
			mkdir -p "${EFOSSIL_STORE_DIR}"
		) || die "Unable to create ${EFOSSIL_STORE_DIR}"
	fi

	addwrite "${EFOSSIL_STORE_DIR}"
	if [[ ! -e ${FOSSIL_DB} ]]; then
		if [[ ${EVCS_OFFLINE} ]]; then
			eerror "A clone of the following repository is required to proceed:"
			eerror "  ${1}"
			eerror "However, networking activity has been disabled using EVCS_OFFLINE and there"
			eerror "is no local clone available."
			die "No local clone of ${1}. Unable to proceed with EVCS_OFFLINE."
		fi
	fi
}


# @FUNCTION: _fossil_is_local_repo
# @USAGE: <repo-uri>
# @INTERNAL
# @DESCRIPTION:
# Determine whether the given URI specifies a local (on-disk)
# repository.
_fossil_is_local_repo() {
	debug-print-function ${FUNCNAME} "$@"

	local uri=${1}

	[[ ${uri} == file://* || ${uri} == /* ]]
}

# @FUNCTION: fossil_fetch
# @USAGE: [<repo-uri> [<remote-ref> [<local-id> [<commit-date>]]]]
# @DESCRIPTION:
# Fetch new commits to the local clone of repository.
#
# <repo-uri> specifies the repository URIs to fetch from, as a space-
# -separated list. The first URI will be used as repository group
# identifier and therefore must be used consistently. When not
# specified, defaults to ${EFOSSIL_REPO_URI}.
#
# <remote-ref> specifies the remote ref or commit id to fetch.
# It is preferred to use 'refs/heads/<branch-name>' for branches
# and 'refs/tags/<tag-name>' for tags. Other options are 'HEAD'
# for upstream default branch and hexadecimal commit SHA1. Defaults
# to the first of EFOSSIL_COMMIT, EFOSSIL_BRANCH or literal 'HEAD' that
# is set to a non-null value.
#
# <local-id> specifies the local branch identifier that will be used to
# locally store the fetch result. It should be unique to multiple
# fetches within the repository that can be performed at the same time
# (including parallel merges). It defaults to ${CATEGORY}/${PN}/${SLOT%/*}.
# This default should be fine unless you are fetching multiple trees
# from the same repository in the same ebuild.
#
# <commit-id> requests attempting to use repository state as of specific
# date. For more details, see EFOSSIL_COMMIT_DATE.
#
# The fetch operation will affect the EFOSSIL_STORE only. It will not touch
# the working copy, nor export any environment variables.
# If the repository contains submodules, they will be fetched
# recursively.
fossil_fetch() {
	debug-print-function ${FUNCNAME} "$@"

	local repos
	if [[ ${1} ]]; then
		repos=( ${1} )
	elif [[ $(declare -p EFOSSIL_REPO_URI) == "declare -a"* ]]; then
		repos=( "${EFOSSIL_REPO_URI[@]}" )
	else
		repos=( ${EFOSSIL_REPO_URI} )
	fi

	local branch=${EFOSSIL_BRANCH:+${EFOSSIL_BRANCH}}
	local remote_ref=${2:-${EFOSSIL_COMMIT:-${branch:-trunk}}}
	local local_id=${3:-${CATEGORY}/${PN}/${SLOT%/*}}
	local commit_date=${4:-${EFOSSIL_COMMIT_DATE}}

	[[ ${repos[@]} ]] || die "No URI provided and EFOSSIL_REPO_URI unset"


	# prepend the local mirror if applicable
	if [[ ${EFOSSIL_MIRROR_URI} ]]; then
		repos=(
			"${EFOSSIL_MIRROR_URI}"
			"${repos[@]}"
		)
	fi

	# try to fetch from the remote
	local r success saved_umask
	if [[ ${EVCS_UMASK} ]]; then
		saved_umask=$(umask)
		umask "${EVCS_UMASK}" || die "Bad options to umask: ${EVCS_UMASK}"
	fi

	local -x FOSSIL_DB
	_fossil_set_fossildb "${repos[0]}"

	for r in "${repos[@]}"; do
		if [[ ! ${EVCS_OFFLINE} ]]; then
			einfo "Fetching \e[1m${r}\e[22m ..."
			if [ ! -e "$FOSSIL_DB" ] ; then
				local fetch_command=( fossil clone "${r}" "$FOSSIL_DB" )
			else
				local fetch_command=( fossil pull -R "${FOSSIL_DB}" "${r}" )
			fi

			if [[ ${r} == http://* || ${r} == https://* ]] &&
					[[ ! ${EFOSSIL_SSL_WARNED} ]] &&
					! ROOT=/ has_version 'dev-vcs/fossil[ssl]'
			then
				ewarn "fossil-: fetching from HTTP(S) requested. In order to support HTTP(S),"
				ewarn "dev-vcs/fossil needs to be built with USE=ssl. Example solution:"
				ewarn
				ewarn "	echo dev-vcs/fossil ssl >> /etc/portage/package.use"
				ewarn "	emerge -1v dev-vcs/fossil"
				ewarn
				ewarn "HTTP(S) URIs will be skipped."
				EFOSSIL_SSL_WARNED=1
			fi


			set -- "${fetch_command[@]}"
			echo "${@}" >&2
			"${@}" || continue

		fi


		if [ ! -e "${FOSSIL_DB}" ]; then
			if [[ ${EVCS_OFFLINE} ]]; then
				eerror "A clone of the following repository is required to proceed:"
				eerror "  ${repos[0]}"
			else
				die "Fetching from repo ${r} failed.."
			fi
		fi

		success=1
		break
	done
	if [[ ${saved_umask} ]]; then
		umask "${saved_umask}" || die
	fi
	[[ ${success} ]] || die "Unable to fetch from any of EFOSSIL_REPO_URI"

}

# @FUNCTION: fossil_checkout
# @USAGE: [<repo-uri> [<checkout-path> [<local-id>]]]
# @DESCRIPTION:
# Check the previously fetched tree to the working copy.
#
# <repo-uri> specifies the repository URIs, as a space-separated list.
# The first URI will be used as repository group identifier
# and therefore must be used consistently with fossil-r3_fetch.
# The remaining URIs are not used and therefore may be omitted.
# When not specified, defaults to ${EFOSSIL_REPO_URI}.
#
# <checkout-path> specifies the path to place the checkout. It defaults
# to ${EFOSSIL_CHECKOUT_DIR} if set, otherwise to ${WORKDIR}/${P}.
#
# <local-id> needs to specify the local identifier that was used
# for respective fossil-r3_fetch.
#
# The checkout operation will write to the working copy, and export
# the repository state into the environment. If the repository contains
# submodules, they will be checked out recursively.
fossil_checkout() {
	debug-print-function ${FUNCNAME} "$@"

	local repos
	if [[ ${1} ]]; then
		repos=( ${1} )
	elif [[ $(declare -p EFOSSIL_REPO_URI) == "declare -a"* ]]; then
		repos=( "${EFOSSIL_REPO_URI[@]}" )
	else
		repos=( ${EFOSSIL_REPO_URI} )
	fi

	local r="${repos[0]}"

	local out_dir=${2:-${EFOSSIL_CHECKOUT_DIR:-${WORKDIR}/${P}}}
	local local_id=${3:-${CATEGORY}/${PN}/${SLOT%/*}}

	local -x FOSSIL_DB
	_fossil_set_fossildb "${r}"

	einfo "Checking out \e[1m${r}\e[22m to \e[1m${out_dir}\e[22m ..."

	if [ ! -e "${FOSSIL_DB}" ] ; then
		die "Logic error: no local clone of ${r} at ${FOSSIL_DB}. fossil_fetch not used?"
	fi

	if [ ! -e "${out_dir}" ] ; then
		mkdir -p "${out_dir}" || die "Could not create output directory at ${out_dir}"
	fi
	
	pushd "${out_dir}" > /dev/null || die "Could not change to output directory at ${out_dir}"

	local new_commit_id=$(
		fossil timeline -n 1 -t ci -R ${FOSSIL_DB} | awk -e 'BEGIN { FS=" "} NR==2 { gsub(/[^0-9a-f]/,"", $2); printf $2 }'
	)

	local old_commit_id=$(
		if [ -e ".fslckout" ] ; then
				fossil timeline -n 1 -t ci | awk -e 'BEGIN { FS=" "} NR==2 { gsub(/[^0-9a-f]/,"", $2); printf $2 }'
		fi
	)

	if [[ ! ${old_commit_id} ]]; then
		echo "FOSSIL NEW branch -->"
		echo "   repository:               ${FOSSIL_DB}"
		echo "   at the commit:            ${new_commit_id}"
		fossil open --nested ${FOSSIL_DB} ${EFOSSIL_COMMIT:-${EFOSSIL_COMMIT_DATE}}  || die
	else
		# diff against previous revision
		echo "FOSSIL update -->"
		echo "   repository:               ${FOSSIL_DB}"
		# write out message based on the revisions
		if [[ "${old_commit_id}" != "${new_commit_id}" ]]; then
			echo "   updating from commit:     ${old_commit_id}"
			echo "   to commit:                ${new_commit_id}"
			fossil checkcout --force ${EFOSSIL_COMMIT:-${EFOSSIL_COMMIT_DATE:---latest}}  || die
		else
			echo "   at the commit:            ${new_commit_id}"
		fi
	fi

	popd

	export EFOSSIL_VERSION=${new_commit_id}
	export EFOSSIL_DB=${FOSSIL_DB}
}

fossil_src_fetch() {
	debug-print-function ${FUNCNAME} "$@"


	_fossil_env_setup
	fossil_fetch
}

fossil_src_unpack() {
	debug-print-function ${FUNCNAME} "$@"

	_fossil_env_setup
	fossil_src_fetch
	fossil_checkout
}

_FOSSIL=1
fi
