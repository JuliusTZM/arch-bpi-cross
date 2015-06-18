#!/bin/bash

set -e

force=
if [ "$1" = "-f" ]; then
    force="-f"
fi

arch="$(uname -m)"
prefix=arm-linux-gnueabihf
binutils_version=2.25-1-${arch}
gcc_stage1_version=4.9.2-1-${arch}
linux_api_headers_version=4.0.1-1-any
glibc_headers_version=2.21-1-any
gcc_stage2_version=4.9.2-1-${arch}
glibc_version=2.21-1-any
gcc_version=4.9.2-1-${arch}

gcc_filename="gcc-${gcc_version%%-*}.tar.bz2"
glibc_filename="glibc-${glibc_version%%-*}.tar.xz"

function build() {
    eval "version=\${${1//-/_}_version}"
    pkg="${prefix}-$1/${prefix}-$1-${version}.pkg.tar.xz"
    if [ -n "${force}" -o ! -f "${pkg}" ]; then
	(cd "./${prefix}-$1"
	    if [ $1 == "glibc-headers" ]; then
	        wget http://ftp2.ie.freesbie.org/pub/ftp.frugalware.org/pub/frugalware/frugalware-current/source/base/glibc/glibc-2.21-roundup.patch
	    elif [ $1 == "binutils" ]; then
		wget https://raw.githubusercontent.com/archlinuxarm/PKGBUILDs/master/core/binutils/binutils-2.25-roundup.patch
	    fi
         makepkg "${force}")
    fi
    if [ $1 == "binutils" ]; then
	sudo pacman -U "${prefix}-$1/${prefix}-$1-ldscripts-${version}.pkg.tar.xz"
    fi
    sudo pacman -U "${pkg}"
}

build binutils
build gcc-stage1

build linux-api-headers
build glibc-headers
ln -sf "../${prefix}-gcc-stage1/${gcc_filename}" "${prefix}-gcc-stage2/${gcc_filename}"
build gcc-stage2

ln -sf "../${prefix}-glibc-headers/${glibc_filename}" "${prefix}-glibc/${glibc_filename}"
build glibc
ln -sf "../${prefix}-gcc-stage2/${gcc_filename}" "${prefix}-gcc/${gcc_filename}"
build gcc
