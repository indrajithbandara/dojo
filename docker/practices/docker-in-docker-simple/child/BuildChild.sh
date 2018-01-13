#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd ${SCRIPT_DIR}

CGROUP_DIR=/sys/fs/cgroup

[ -d ${CGROUP_DIR} ] || mkdir ${CGROUP_DIR}

mountpoint -q ${CGROUP_DIR} || {
    mount -n -t tmpfs -o uid=0,gid=0,mode=0755 cgroup ${CGROUP_DIR} || {
        echo "Could not mount tmpsfs. Did you use --privileged?" >&2
        exit 1
    }
}

for SUBSYS in $(cut -d: -f2 /proc/1/cgroup); do
    [ -d ${CGROUP}/${SUBSYS} ] || mkdir ${CGROUP}/${SUBSYS}
    mountpoint -q ${CGROUP}/${SUBSYS} || {
        mount -n -t cgroup -o ${SUBSYS} cgroup ${CGROUP}/${SUBSYS}
    }
done

pushd /proc/self/fd
for FD in *; do
    case "${FD}" in
    [012])
        ;;
    *)
        eval exec "$FD>&-"
        ;;
    esac
done

popd

ensure_loop(){
    num="$1"
    dev="/dev/loop$num"
    if test -b "$dev"; then
        echo "$dev is a usable loop device."
        return 0
    fi

    echo "Attempting to create $dev for docker ..."
    if ! mknod -m660 $dev b 7 $num; then
        echo "Failed to create $dev!" 1>&2
        return 3
    fi

    return 0
}

LOOP_A=$(losetup -f)
LOOP_A=${LOOP_A#/dev/loop}
LOOP_B=$(expr $LOOP_A + 1)

ensure_loop $LOOP_A || exit 1
ensure_loop $LOOP_B || exit 1

[ -f /var/run/docker.pid ] && {
    pgrep docker > /dev/null && {
        echo "Some docker daemons are already running." >&2
        exit 1
    } || {
        rm -f /var/run/docker.pid
    }
}

docker daemon --storage-driver="devicemapper" &
sleep 1

docker build -t="taro/docker-in-docker-child:latest" .
docker run --rm -p 0.0.0.0:80:80 --name docker-child -h docker-child -ti "taro/docker-in-docker-child" /bin/bash

