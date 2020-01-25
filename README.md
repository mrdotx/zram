# zram systemd service

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
