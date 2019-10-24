#!/bin/sh
for boot_vga in /sys/bus/pci/devices/*3*/boot_vga; do
    if [ $(<"${boot_vga}") -eq 0 ]; then
        dir=$(dirname -- "${boot_vga}")
        for dev in "${dir::-1}"*; do
            echo $dev
            echo 'vfio-pci' > "${dev}/driver_override"
        done
    fi
done
modprobe -i vfio-pci
