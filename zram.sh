#!/bin/sh

# path:   /home/klassiker/.local/share/repos/zram/zram.sh
# author: klassiker [mrdotx]
# github: https://github.com/mrdotx/zram
# date:   2024-03-28T08:26:28+0100

# speed up script by using standard c
LC_ALL=C
LANG=C

# config
num_devices="1"     # number of swaps
algorithm="zstd"    # lzo-rle is used without specified algorithm
zram_percent=       # without a specified percentage of ram,
                    # the stored value of the algorithm is used
max_size=4096       # maximum size of the swaps in MiB (<1 use max calculated)
swap_prio=42        # higher numbers indicate higher swap priority (0 - 32767)

# functions
check_root() {
    [ "$(id -u)" -ne 0 ] \
        && printf "this script needs root privileges to run\n" \
        && exit 1
}

set_value() {
    [ -e "$1" ] \
        && printf "Set %s to %s\n" "$1" "$2" \
        && printf "%s" "$2" > "$1"
}

enable_optimizations() {
    # optimizing swap on zram (https://wiki.archlinux.org/title/Zram)
    case $1 in
        1)  # optimized values
            set_value "/sys/module/zswap/parameters/enabled" 0
            set_value "/proc/sys/vm/swappiness" 180
            set_value "/proc/sys/vm/watermark_boost_factor" 0
            set_value "/proc/sys/vm/watermark_scale_factor" 125
            set_value "/proc/sys/vm/page-cluster" 0
            ;;
        0)  # default values
            set_value "/proc/sys/vm/page-cluster" 3
            set_value "/proc/sys/vm/watermark_scale_factor" 10
            set_value "/proc/sys/vm/watermark_boost_factor" 15000
            set_value "/proc/sys/vm/swappiness" 60
            set_value "/sys/module/zswap/parameters/enabled" 1
            ;;
    esac
}

activate_devices() {
    # enable optimizations
    [ "$1" = "optimized" ] \
        && enable_optimizations 1

    # add zram to kernel modules
    modprobe zram num_devices="$num_devices"

    # calculate zram size
    [ -z "$zram_percent" ] \
        && case $algorithm in
            zstd)   zram_percent="73";;
            842)    zram_percent="48";;
            lz4hc)  zram_percent="66";;
            lz4)    zram_percent="62";;
            *)      zram_percent="63";;
        esac

    memory=$(free -b | awk 'NR==2 {print $2}')
    size=$((memory * zram_percent / 100 / num_devices))

    [ $max_size -gt 0 ] \
        && max_size=$((max_size * 1024 * 1024 / num_devices)) \
        && size=$((max_size > size ? size : max_size))

    # activate zram
    for i in $(seq "$num_devices"); do
        device=$((i - 1))

        [ -n "$algorithm" ] \
            && algorithm="--algorithm $algorithm"
        eval "zramctl $algorithm --size $size /dev/zram$device"

        mkswap --uuid clear --label "zram$device" "/dev/zram$device"
        swapon --priority $swap_prio "/dev/zram$device"
    done

    unset i
}

deactivate_devices() {
    # deactivate zram
    devices=$(awk 'NR>1 {print $1}' /proc/swaps) \
        && for i in $devices; do
            swapoff "$i"
        done

    # remove zram from kernel modules
    modprobe --remove zram

    # disable optimizations
    [ "$1" = "optimized" ] \
        && enable_optimizations 0

    unset i
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
