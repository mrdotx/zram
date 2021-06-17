# zram systemd service

Prior to kernel 3.15, each zram device contains it's own compression buffer, memory pools and other metadata as well as per-device locks. This can become a serious bottleneck for multi-core machines. To work around this problem, zram is capable of initializing multiple devices. **For this reason, the recommended amount of devices for swap is 1 per cpu core for kernels prior to 3.15.** [Gentoo Wiki][reference]

## create compressed zram swap

### install zram.service

- cp zram-modules.conf /etc/modules-load.d/zram.conf
- cp zram-modprobe.conf /etc/modprobe.d/zram.conf
  - if needed change zram num_devices
- cp zram.service /etc/systemd/system/zram.service
- cp 99-vm.conf /etc/sysctl.d/99-vm.conf

### enable zram.service

- systemctl enable zram.service --now

### check zram.service

- systemctl status dev-zram0.swap
- systemctl status zram.service
- zramctl --output-all

[reference]: https://wiki.gentoo.org/wiki/Zram#Caveats.2FCons
