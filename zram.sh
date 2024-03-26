#!/bin/sh

# path:   /home/klassiker/.local/share/repos/zram/zram.sh
# author: klassiker [mrdotx]
# github: https://github.com/mrdotx/zram
# date:   2024-03-25T22:35:07+0100

# speed up script by using standard c
LC_ALL=C
LANG=C

# config
num_devices="1"     # number of swaps
algorithm="zstd"    # lzo-rle is used without specified algorithm
zram_percent=       # without a specified percentage of ram,
                    # the stored value of the algorithm is used
max_size=4096       # maximum size of the swaps in kb
swap_prio=42        # higher numbers indicate higher swap priority (0 - 32767)

# functions
check_root() {
    [ "$(id -u)" -ne 0 ] \
        && printf "this script needs root privileges to run\n" \
        && exit 1
}

activate_devices() {
    memory=$( \
        free \
        | grep -e "^Mem:" \
        | sed -e 's/^Mem: *//' -e 's/  *.*//' \
    )

    [ -z "$zram_percent" ] \
        && case $algorithm in
            zstd)
                zram_percent="72"
                ;;
            842)
                zram_percent="47"
                ;;
            lz4hc)
                zram_percent="65"
                ;;
            lz4)
                zram_percent="61"
                ;;
            *)
                zram_percent="62"
                ;;
        esac

    size=$((memory * 1024 * zram_percent / 100 / num_devices))

    [ $max_size -gt 0 ] \
        && max_size=$((max_size * 1024 * 1024 / num_devices)) \
        && size=$((max_size > size ? size : max_size))

    # add zram to kernel modules
    modprobe zram num_devices="$num_devices"

    for i in $(seq "$num_devices"); do
        device=$((i - 1))

        [ -n "$algorithm" ] \
            && algorithm="--algorithm $algorithm"
        cmd="zramctl $algorithm --size $size /dev/zram$device"
        eval "$cmd"

        mkswap --label "zram$device" "/dev/zram$device"
        swapon --priority $swap_prio "/dev/zram$device"
    done

    unset i
}

deactivate_devices() {
    devices=$(grep zram /proc/swaps | cut -d " " -f1) \
        && for i in $devices; do
            swapoff "$i"
        done

    # remove zram from kernel modules
    modprobe --remove zram

    unset i
}

# options
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
        printf "usage: %s [--start] [--stop] [--restart]\n" "$(basename "$0")"
        exit 1
esac
