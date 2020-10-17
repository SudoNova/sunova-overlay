# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit wxwidgets xdg-utils

if [[ ${PV} == 9999 ]] ; then
	EGIT_REPO_URI="https://github.com/amule-project/amule"
	inherit autotools git-r3
else
	MY_P="${PN/m/M}-${PV}"
	SRC_URI="https://download.sourceforge.net/${PN}/${MY_P}.tar.xz"
	S="${WORKDIR}/${MY_P}"
	KEYWORDS="~alpha ~amd64 ~arm ~ppc ~ppc64 ~sparc ~x86"
fi

DESCRIPTION="aMule, the all-platform eMule p2p client"
HOMEPAGE="http://www.amule.org/"

LICENSE="GPL-2+"
SLOT="0"
IUSE="daemon debug geoip nls plasma webserver stats upnp +X xas"

BOOST_MIN_VER=1.47
CRYPTOPP_MIN_VER=5.1
GETTEXT_MIN_VER=0.11.5
GDLIB_MIN_VER=2
LIBPNG_MIN_VER=1.2.3
LIBUPNP_MIN_VER=1.6.6
WX_GTK_VER="3.1-gtk3"
ZLIB_MIN_VER=1.1.4

RDEPEND="
	>=dev-libs/boost-${BOOST_MIN_VER}:=
	>=dev-libs/crypto++-${CRYPTOPP_MIN_VER}:=
	sys-libs/binutils-libs:0=
	sys-libs/readline:0=
	>=sys-libs/zlib-${ZLIB_MIN_VER}:0=
	>=x11-libs/wxGTK-3.0.4:${WX_GTK_VER}=[X?]
	daemon? ( acct-user/amule )
	geoip? ( dev-libs/geoip )
	nls? ( virtual/libintl )
	webserver? (
		acct-user/amule
		>=media-libs/libpng-${LIBPNG_MIN_VER}:0=
	)
	stats? ( >=media-libs/gd-${GDLIB_MIN_VER}:=[jpeg,png] )
	upnp? ( >=net-libs/libupnp-${LIBUPNP_MIN_VER}:0= )
	xas? ( net-irc/hexchat )
"
DEPEND="${RDEPEND}
	X? ( dev-util/desktop-file-utils )
"
BDEPEND="
	virtual/pkgconfig
	nls? ( >=sys-devel/gettext-${GETTEXT_MIN_VER} )
"

PATCHES=(
	"${FILESDIR}/moc-qt5.patch"
)

pkg_setup() {
	setup-wxwidgets
}

src_prepare() {
	default

	if [[ ${PV} == 9999 ]]; then
		./autogen.sh || die
	fi
}

src_configure() {
	local myconf=(
		--with-denoise-level=0
		--with-wx-config="${WX_CONFIG}"
		--enable-amulecmd
		--enable-fileview
		--with-boost
		$(use_enable debug)
		$(use_enable daemon amule-daemon)
		$(use_enable geoip)
		$(use_enable nls)
		$(use_enable webserver)
		$(use_enable stats cas)
		$(use_enable stats alcc)
		$(use_enable upnp)
		$(use_enable xas)
	)

	if use X; then
		myconf+=(
			--enable-amule-gui
			$(use_enable plasma plasmamule)
			$(use_enable stats alc)
			$(use_enable stats wxcas)
		)
	else
		myconf+=(
			--disable-monolithic
			--disable-amule-gui
			--disable-alc
			--disable-wxcas
		)
	fi

	econf "${myconf[@]}"
}

src_install() {
	default

	if use daemon; then
		newconfd "${FILESDIR}"/amuled.confd-r1 amuled
		newinitd "${FILESDIR}"/amuled.initd amuled
	fi
	if use webserver; then
		newconfd "${FILESDIR}"/amuleweb.confd-r1 amuleweb
		newinitd "${FILESDIR}"/amuleweb.initd amuleweb
	fi

	if use daemon || use webserver; then
		keepdir /var/lib/${PN}
		fowners amule:amule /var/lib/${PN}
		fperms 0750 /var/lib/${PN}
	fi
}

pkg_postinst() {
	local ver

	if use daemon || use webserver; then
		for ver in ${REPLACING_VERSIONS}; do
			if ver_test ${ver} -lt "2.3.2-r4"; then
				elog "Default user under which amuled and amuleweb daemons are started"
				elog "have been changed from p2p to amule. Default home directory have been"
				elog "changed as well."
				echo
				elog "If you want to preserve old download/share location, you can create"
				elog "symlink /var/lib/amule/.aMule pointing to the old location and adjust"
				elog "files ownership *or* restore AMULEUSER and AMULEHOME variables in"
				elog "/etc/conf.d/{amuled,amuleweb} to the old values."

				break
			fi
		done
	fi

	use X && xdg_desktop_database_update
}

pkg_postrm() {
	use X && xdg_desktop_database_update
}
