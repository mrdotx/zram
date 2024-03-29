# zram

Prior to kernel 3.15, each zram device contains it's own compression buffer, memory pools and other metadata as well as per-device locks. This can become a serious bottleneck for multi-core machines. To work around this problem, zram is capable of initializing multiple devices. **For this reason, the recommended amount of devices for swap is 1 per cpu core for kernels prior to 3.15.** [Gentoo Wiki][gentoowiki]

## comparison of compression algorithms

[LinuxReviews][linuxreviews]

| algorithm | time    | data | compressed | total  | ratio | percent |
| :-------- | ------: | ---: | ---------: | -----: | ----: | :-----: |
| lzo       | 4.571s  | 1.1G | 387.8M     | 409.8M | 2.68  | 63      |
| lzo-rle   | 4.471s  | 1.1G | 388.0M     | 410.0M | 2.68  | 63      |
| lz4       | 4.467s  | 1.1G | 403.4M     | 426.4M | 2.57  | 62      |
| lz4hc     | 14.584s | 1.1G | 362.8M     | 383.2M | 2.87  | 66      |
| 842       | 22.574s | 1.1G | 538.6M     | 570.5M | 1.92  | 48      |
| [zstd]    | 7.897s  | 1.1G | 285.3M     | 298.8M | 3.68  | 73      |

[default algorithm]

The size of the zram device controls the maximum uncompressed amount of data it can store, not the maximum compressed size. The zram size can be equal to or even greater than the systems physical RAM capacity, as long as the compressed size on physical RAM will not exceed the systems physical RAM capacity (e.g. theoretically 368% for zstd). To avoid problems with complete physical RAM allocation and to take into account the degree of compression, the percentage values in the table are fictitious calculations as a proven method (e.g. 100-(100/3.68)=72,8261 for zstd). [ArchWiki][archwiki]

## create compressed zram swaps

### install zram.service

- cp zram.service /etc/systemd/system/zram.service
- adjust the paths for execstart/-stop

### enable zram.service

- systemctl enable zram.service --now

### check zram swaps

- systemctl status zram.service
- zramctl --output-all
- swapon --show

[gentoowiki]: https://wiki.gentoo.org/wiki/Zram#Caveats.2FCons
[linuxreviews]: https://linuxreviews.org/Comparison_of_Compression_Algorithms#zram_block_drive_compression
[archwiki]: https://wiki.archlinux.org/title/Zram#Using_as_swap
