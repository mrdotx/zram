# zram systemd service

Prior to kernel 3.15, each zram device contains it's own compression buffer, memory pools and other metadata as well as per-device locks. This can become a serious bottleneck for multi-core machines. To work around this problem, zram is capable of initializing multiple devices. For this reason, the recommended amount of devices for swap is 1 per cpu core for kernels prior to 3.15. [Gentoo Wiki zram][reference]

service to create 4 compressed zram swaps

## installation

- copy file zram-modules.conf to /etc/modules-load.d
- copy file zram-modprobe.conf to /etc/modprobe.d
- copy file zram-setup@.service to /etc/systemd/system
- copy folder zram.conf.d to /etc
- copy file 99-vm.conf to /etc/sysctl.d

## enable service

- systemctl enable zram-setup@zram0.service
- systemctl enable zram-setup@zram1.service
- systemctl enable zram-setup@zram2.service
- systemctl enable zram-setup@zram3.service

## check after reboot

- systemctl status dev-zram0.swap
- systemctl status zram-setup@zram0.service
- zramctl --output-all

[reference]: https://wiki.gentoo.org/wiki/Zram#Caveats.2FCons
