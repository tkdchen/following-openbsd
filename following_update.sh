#!/bin/sh

ANONCVS_MIRROR=anoncvs@anoncvs.jp.openbsd.org

sync_src()
{
	if [ -e '/usr/src' ]
	then
		cd /usr/src
		cvs -d ${ANONCVS_MIRROR}:/cvs update -Pd
	else
		cd /usr
		cvs -d ${ANONCVS_MIRROR}:/cvs checkout -P src
	fi
}

sync_ports()
{
	if [ -e '/usr/ports' ]
	then
		cd /usr/ports
		cvs -d ${ANONCVS_MIRROR}:/cvs update -Pd
	else
		cd /usr
		cvs -d ${ANONCVS_MIRROR}:/cvs checkout -P ports
	fi
}

sync_xenocara()
{
	if [ -e '/usr/xenocara' ]
	then
		cd /usr/xenocara
		cvs -d ${ANONCVS_MIRROR}:/cvs update -Pd
	else
		cd /usr
		cvs -d ${ANONCVS_MIRROR}:/cvs checkout -P xenocara
	fi
}

build_kernel()
{
	cd /usr/src/sys/arch/i386/conf
	/usr/sbin/config GENERIC
	cd /usr/src/sys/arch/i386/compile/GENERIC
	make clean && make depend && make

	cd /usr/src/sys/arch/i386/compile/GENERIC
	make install
	echo Now, you should reboot your machine.
}

build_binaries()
{
	rm -rf /usr/obj/*
	cd /usr/src
	make obj
	cd /usr/src/etc && env DESTDIR=/ make distrib-dirs
	cd /usr/src
	make build
}

build_xenocara()
{
	cd /usr/xenocara
	rm -rf /usr/xobj/*
	make bootstrap
	make obj
	make build
}

do_rest()
{
	build_binaries
	build_xenocara
}

usage()
{
	cat <<EOF
sys_update.sh target|help

target:
	sync [src|ports|X]

		src:   sync /usr/src
		ports: sync /usr/ports
		X:	 sync /usr/xenocara
		only sync means syncing all of above

	kernel
		build and install kernel. This requires to reboot machine.

	binaries
		build and install binaries.

	X
		build and install xenocara

	rest
		a shortcut to the binaries and X after rebooting machine.

help:
	print this help text.
EOF
}

case $1 in
	"sync")
		case $2 in
		"src") sync_src ;;
		"ports" ) sync_ports ;;
		"X") sync_xenocara ;;
		*)
			sync_src
			sync_ports
			sync_xenocara
			;;
		esac
		;;

	"kernel") build_kernel ;;
	"binaries") build_binaries ;;
	"X") build_xenocara ;;
	"help") usage ;;
	*)
		echo Unknown argument.
		echo
		usage
		;;
esac
