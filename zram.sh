#!/bin/sh

# path:   /home/klassiker/.local/share/repos/zram/zram.sh
# author: klassiker [mrdotx]
# github: https://github.com/mrdotx/shell
# date:   2021-06-24T22:45:34+0200

# config
zram_percent=50
num_devices=1
# lzo [lzo-rle] lz4 lz4hc 842 zstd
algorithm=lzo-rle
stream=4

# functions
check_root() {
    [ "$(id -u)" -ne 0 ] \
        && printf "this script needs root privileges to run\n" \
        && exit 1
}

activate_devices() {
    memory=$( \
        LC_ALL=C free \
        | grep -e "^Mem:" \
        | sed -e 's/^Mem: *//' -e 's/  *.*//' \
    )

    size=$((memory * 1024 * zram_percent / 100 / num_devices))

    # add zram to kernel modules
    modprobe zram num_devices="$num_devices"

	for i in $(seq "$num_devices"); do
		device=$((i - 1))
        zramctl \
            --algorithm "$algorithm" \
            --stream "$stream" \
            --size "$size" \
            "/dev/zram$device"
		mkswap --label "zram$device" "/dev/zram$device"
		swapon --priority 42 "/dev/zram$device"
	done

    unset i
}

deactivate_devices() {
    if devices=$(grep zram /proc/swaps | cut -d " " -f1); then
		for i in $devices; do
			swapoff "$i"
		done
	fi

    # remove zram from kernel modules
	modprobe --remove zram

    unset i
}

case "$1" in
	--start)
        check_root
		activate_devices
		;;
	--stop)
        check_root
		deactivate_devices
		;;
	--restart)
        check_root
		deactivate_devices
		activate_devices
		;;
	*)
        script=$(basename "$0")
		printf "usage: %s [--start] [--stop] [--restart]\n" "$script"
        exit 1
esac
