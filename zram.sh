#!/bin/sh

# path:   /home/klassiker/.local/share/repos/zram/zram.sh
# author: klassiker [mrdotx]
# github: https://github.com/mrdotx/zram
# date:   2024-07-24T22:43:15+0200

# speed up script by using standard c
LC_ALL=C
LANG=C

# config
num_devices=1       # number of swaps to create
algorithm="lz4"     # the default algorithm is zstd (lzo,lzo-rle,lz4,lz4hc,842)
zram_percent=       # without a specified percentage of ram,
                    # the stored value of the algorithm is used
max_size=4096       # maximum size of the swaps in MiB (<=0 use max calculated)
priority=42         # higher numbers indicate higher swap priority (0 - 32767)

# functions
check_root() {
    [ "$(id -u)" -ne 0 ] \
        && printf "this script needs root privileges to run\n" \
        && exit 1
}

set_sysfs() {
    [ -e "$1" ] \
        && printf "Set %s = %s\n" "$1" "$2" \
        && printf "%s" "$2" > "$1"
}

enable_optimizations() {
    # optimizing swap on zram (https://wiki.archlinux.org/title/Zram)
    case $1 in
        1)  # optimized values
            set_sysfs '/sys/module/zswap/parameters/enabled' N
            set_sysfs '/proc/sys/vm/swappiness' 180
            set_sysfs '/proc/sys/vm/watermark_boost_factor' 0
            set_sysfs '/proc/sys/vm/watermark_scale_factor' 125
            set_sysfs '/proc/sys/vm/page-cluster' 0
            ;;
        0)  # default values
            set_sysfs '/proc/sys/vm/page-cluster' 3
            set_sysfs '/proc/sys/vm/watermark_scale_factor' 10
            set_sysfs '/proc/sys/vm/watermark_boost_factor' 15000
            set_sysfs '/proc/sys/vm/swappiness' 60
            set_sysfs '/sys/module/zswap/parameters/enabled' Y
            ;;
    esac
}

activate_devices() {
    # enable optimizations
    [ "$1" = 'optimized' ] \
        && enable_optimizations 1

    # add zram to kernel modules
    modprobe zram num_devices="$num_devices"

    # calculate zram size
    [ -z "$zram_percent" ] \
        && case $algorithm in
            zstd)   zram_percent='73';;
            842)    zram_percent='48';;
            lz4hc)  zram_percent='66';;
            lz4)    zram_percent='62';;
            *)      zram_percent='63';;
        esac

    memory=$(free -b | awk 'NR==2 {print $2}')
    size=$((memory * zram_percent / 100 / num_devices))

    [ $max_size -gt 0 ] \
        && max_size=$((max_size * 1024 * 1024 / num_devices)) \
        && size=$((max_size > size ? size : max_size))

    # activate zram swaps
    for device in $(seq 0 "$((num_devices - 1))"); do
        set_sysfs "/sys/block/zram$device/comp_algorithm" "$algorithm" \
            && set_sysfs "/sys/block/zram$device/disksize" "$size" \
            && mkswap --quiet --uuid clear --label "zram$device" \
                "/dev/zram$device" \
            && swapon --priority $priority "/dev/zram$device"
    done
}

deactivate_devices() {
    # deactivate zram
    awk 'NR>1 {print $1}' /proc/swaps \
        | while read -r swaps; do
            swapoff "$swaps"
        done

    # remove zram from kernel modules
    modprobe --remove zram

    # disable optimizations
    [ "$1" = 'optimized' ] \
        && enable_optimizations 0
}

# options
case "$1" in
    --start)
        check_root
        activate_devices "$2"
        ;;
    --stop)
        check_root
        deactivate_devices "$2"
        ;;
    --restart)
        check_root
        deactivate_devices "$2"
        activate_devices "$2"
        ;;
    *)
        printf "usage: %s [--start] [--stop] [--restart] [optimized]\n" \
            "$(basename "$0")"
        exit 1
esac
