# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

inherit eutils

DESCRIPTION=".NET Core SDK - binary precompiled for glibc"
HOMEPAGE="https://www.microsoft.com/net/core"
LICENSE="MIT"

SRC_URI="
amd64? ( https://download.visualstudio.microsoft.com/download/pr/c58adb8a-49cf-466c-9b72-e4c51edae0e5/f915b953a5bfdafc300bd277d80c3513/dotnet-sdk-5.0.100-preview.8.20417.9-linux-x64.tar.gz )
arm? ( https://download.visualstudio.microsoft.com/download/pr/372de9c1-b63c-4df8-9250-00e107c1d6f7/ee94093420b5c001eaabecdb41621950/dotnet-sdk-5.0.100-preview.8.20417.9-linux-arm.tar.gz )
arm64? ( https://download.visualstudio.microsoft.com/download/pr/a1e93182-8026-4330-b78a-ee7d721107a2/003c59fc228a220df40d90d5ac434873/dotnet-sdk-5.0.100-preview.8.20417.9-linux-arm64.tar.gz )"

SLOT="5.0"
KEYWORDS="~amd64 ~arm ~arm64"

QA_PREBUILT="*"
RESTRICT="splitdebug"

# The sdk includes the runtime-bin and aspnet-bin so prevent from installing at the same time
# dotnetcore-sdk is the source based build
IUSE="libressl"
RDEPEND="
	>=dev-dotnet/dotnetcore-sdk-bin-common-${PV}
	>=sys-apps/lsb-release-1.4
	>=sys-devel/llvm-4.0
	>=dev-util/lldb-4.0
	>=sys-libs/libunwind-1.1-r1
	>=dev-libs/icu-57.1
	>=dev-util/lttng-ust-2.8.1
	!libressl? ( >=dev-libs/openssl-1.0.2h-r2 )
	libressl? ( >=dev-libs/libressl-3.2.1 )
	>=net-misc/curl-7.49.0
	>=app-crypt/mit-krb5-1.14.2
	>=sys-libs/zlib-1.2.8-r1
	!dev-dotnet/dotnetcore-sdk
	!dev-dotnet/dotnetcore-sdk-bin:0
	!dev-dotnet/dotnetcore-runtime-bin
	!dev-dotnet/dotnetcore-aspnet-bin
"

S=${WORKDIR}

src_prepare() {
	default

	# For current .NET Core versions, all the directories contain versioned files,
	# but the top-level files (the dotnet binary for example) are shared between versions,
	# and those are backward-compatible.
	# The exception from this above rule is packs/NETStandard.Library.Ref which is shared between >=3.0 versions.
	# These common files are installed by the non-slotted dev-dotnet/dotnetcore-sdk-bin-common
	# package, while the directories are installed by dev-dotnet/dotnetcore-sdk-bin which uses
	# slots depending on major .NET Core version.
	# This makes it possible to install multiple major versions at the same time.

	# Skip the common files
	find . -maxdepth 1 -type f -exec rm -f {} \; || die
	rm -rf ./packs/NETStandard.Library.Ref || die
}

src_install() {
	local dest="opt/dotnet_core"
	dodir "${dest}"

	local ddest="${D}/${dest}"
	cp -a "${S}"/* "${ddest}/" || die
}
