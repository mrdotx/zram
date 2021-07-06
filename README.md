# zram systemd service

Prior to kernel 3.15, each zram device contains it's own compression buffer, memory pools and other metadata as well as per-device locks. This can become a serious bottleneck for multi-core machines. To work around this problem, zram is capable of initializing multiple devices. **For this reason, the recommended amount of devices for swap is 1 per cpu core for kernels prior to 3.15.** [Gentoo Wiki][gentoowiki]

## comparison of compression algorithms

[default algorithm]

| algorithm | time    | data | compressed | total  | ratio | precent |
| :-------- | :------ | :--- | :--------- | :----- | :---- | :------ |
| lzo       | 4.571s  | 1.1G | 387.8M     | 409.8M | 2.68  | 62      |
| [lzo-rle] | 4.471s  | 1.1G | 388M       | 410M   | 2.68  | 62      |
| lz4       | 4.467s  | 1.1G | 403.4M     | 426.4M | 2.57  | 61      |
| lz4hc     | 14.584s | 1.1G | 362.8M     | 383.2M | 2.87  | 65      |
| 842       | 22.574s | 1.1G | 538.6M     | 570.5M | 1.92  | 47      |
| zstd      | 7.897s  | 1.1G | 285.3M     | 298.8M | 3.68  | 72      |

[LinuxReviews][linuxreviews]

## create compressed zram swap

### install zram.service

- cp zram.service /etc/systemd/system/zram.service
- cp 99-vm.conf /etc/sysctl.d/99-vm.conf

### enable zram.service

- systemctl enable zram.service --now

### check zram.service

- systemctl status dev-zram0.swap
- systemctl status zram.service
- zramctl --output-all

[gentoowiki]: https://wiki.gentoo.org/wiki/Zram#Caveats.2FCons
[linuxreviews]: https://linuxreviews.org/Comparison_of_Compression_Algorithms#zram_block_drive_compression
