#!/bin/sh

# path:   /home/klassiker/.local/share/repos/zram/zram.sh
# author: klassiker [mrdotx]
# github: https://github.com/mrdotx/shell
# date:   2021-06-17T12:34:23+0200

# config
modprobe_file=/etc/modprobe.d/zram.conf
zram_percent=50
algorithm=lz4
stream=4

# functions
activate_devices() {
    num_devices=$( \
        grep "num_devices=" "$modprobe_file" \
        | cut -d "=" -f2 \
    )

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
            "/dev/zram${device}"
		mkswap --label zram${device} /dev/zram${device}
		swapon --priority 42 /dev/zram${device}
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
		activate_devices
		;;
	--stop)
		deactivate_devices
		;;
	--restart)
		deactivate_devices
		activate_devices
		;;
	*)
		printf "usage: %s [--start] [--stop] [--restart]\n" "$0"
esac
