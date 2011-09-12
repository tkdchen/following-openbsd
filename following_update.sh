#!/bin/sh

ANONCVS_MIRROR=anoncvs@anoncvs.jp.openbsd.org
AUTOMATIC_REBOOT=F
ACTION=unknown

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

    if [ -n AUTOMATIC_REBOOT -a "$AUTOMATIC_REBOOT" == "T" ]
    then
        reboot
    else
        echo Now, you should reboot your machine manually.
    fi
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

usage()
{
    cat <<EOF
# sys_update.sh [options] action [targets]

Options:
    -d Same as the -d option for CVS. Specify an anonmynous CVS mirror.
    -r Reboot automatically after building kernel successfully.
       This only applies to the build of kernel.
       By default, anoncvs@anoncvs.jp.openbsd.org:/cvs is used because that
       it fast enough for me in Beijing, China.
    -h Print this usage.

Actions:
    sync    Synchronize the source tree.
    build    build from the source tree to update the system.

Targets:
    For the sync action:
    - src:   sync /usr/src
    - ports: sync /usr/ports
    - X:     sync /usr/xenocara
    - all:   sync all of them in the order of src, ports and X

    For the build action:
    - kernel
        build and install kernel. This requires to reboot machine.
    - binaries
        build and install binaries.
    - X
        build and install xenocara
    You should pass them to the build action explicitly.
EOF
}

while [ $# != 0 ]
do
    case $1 in
        "-r" | "--reboot")
            AUTOMATIC_REBOOT=T
            ;;
        "-d" | "--anoncvs-mirror")
            shift
            ANONCVS_MIRROR=$1
            ;;
        "-h" | "--help")
            usage
            exit
            ;;
        "sync") ACTION=sync ;;
        "build") ACTION=build ;;
        *)
            if [ "$ACTION" == "sync" ]
            then
                case $1 in
                    "src")   sync_src ;;
                    "ports") sync_ports ;;
                    "X")     sync_xenocara ;;
                    "all")
                        sync_src
                        sync_ports
                        sync_xenocara
                        ;;
                esac
            fi
            if [ "$ACTION" == "build" ]
            then
                case $1 in
                    "kernel")   build_kernel ;;
                    "binaries") build_binaries ;;
                    "X")        build_xenocara ;;
                esac
            fi
    esac
    shift
done

