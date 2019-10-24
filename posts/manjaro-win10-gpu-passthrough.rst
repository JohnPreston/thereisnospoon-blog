.. title: Manjaro - Win10 - GPU passthrough
.. slug: manjaro-win10-gpu-passthrough
.. date: 2019-10-21 23:42:21 UTC
.. tags: KVM,NVIDIA,Manjaro,Gaming
.. category: KVM
.. link:
.. description:
.. type: text

Just alike the waltkthrough for Fedora 30, I also did all of that work for Manjaro just because I wanted to cover those two basis.
Chances are the steps etc. are going to be rather identical for the KVM configuration part and Windows install so I won't redoing this again, KVM is consitent across OSes (phew..).

So, let's dive into it!

.. note::

   TLDR; if you are already familiar with Arch Linux and Manjaro, you could simply pull the configuration files from `Github <https://github.com/JohnPreston/manjaro-vfio-gpu-passthrough>`_



Softwares and versions used in Manjaro
--------------------------------------


.. code-block::

   # QEMU - Libvirt
   pacman -Qs qemu
   local/libvirt 5.6.0-1
     API for controlling virtualization engines (openvz,kvm,qemu,virtualbox,xen,etc)
   local/ovmf 1:r26214.20d2e5a125-1
     Tianocore UEFI firmware for qemu.
   local/qemu 4.1.0-2
     A generic and open source machine emulator and virtualizer
   local/vde2 2.3.2-11
     Virtual Distributed Ethernet for emulators like qemu

   # MANJARO
   uname -a
   Linux MANJA-02 5.3.6-1-MANJARO #1 SMP PREEMPT Sat Oct 12 09:30:05 UTC 2019 x86_64 GNU/Linux


Enable IOMMU
------------

`/etc/default/grub`

.. include:: files/vfio/manjaro/etc/default/iommu_grub
   :code: bash
   :end-line: 6


.. code-block:: bash

   update-grub

.. note::

   Just alike in Fedora, you will need to reboot and check that your IOMMU groups map properly before proceeding forward.


Enable VFIO for your device(s)
------------------------------

For the non familiar people with Arch Linux specific commands, coming from another OS like Fedora (like I was) this was the most painful experience to port from that other OS to Arch Linux, however I found that the way to do it in Arch Linux to make a lot of sense and be very clean, just would benefit a lot from more steps and details from people online!


`/etc/modprobe.d/vfio.conf`

.. include:: files/vfio/manjaro/etc/modprobe.d/vfio.conf

`/etc/mkinitcpio.conf`

.. include:: files/vfio/manjaro/etc/mkinitcpio.conf
   :code: bash


`/etc/initcpio/hooks/vfio`

.. include:: files/vfio/manjaro/etc/initcpio/hooks/vfio
   :code: bash


`/etc/initcpio/install/vfio`

.. include:: files/vfio/manjaro/etc/initcpio/install/vfio
   :code: bash


`/usr/bin/vfio-pci-override.sh`

.. include:: files/vfio/manjaro/usr/bin/vfio-pci-override.sh
   :code: bash

`/etc/default/grub`

.. include:: files/vfio/manjaro/etc/default/vfio_grub
   :end-line: 6
   :code: bash

Now we update our initramfs

.. code-block::

   $> mkinitcpio -p linux53
   ==> Building image from preset: /etc/mkinitcpio.d/linux53.preset: 'default'
   -> -k /boot/vmlinuz-5.3-x86_64 -c /etc/mkinitcpio.conf -g /boot/initramfs-5.3-x86_64.img
   ==> Starting build: 5.3.6-1-MANJARO
   -> Running build hook: [base]
   -> Running build hook: [udev]
   -> Running build hook: [autodetect]
   -> Running build hook: [modconf]
   -> Running build hook: [block]
   -> Running build hook: [keyboard]
   -> Running build hook: [keymap]
   -> Running build hook: [filesystems]
   -> Running build hook: [vfio]
   ==> Generating module dependencies
   ==> Creating gzip-compressed initcpio image: /boot/initramfs-5.3-x86_64.img
   ==> Image generation successful
   ==> Building image from preset: /etc/mkinitcpio.d/linux53.preset: 'fallback'
   -> -k /boot/vmlinuz-5.3-x86_64 -c /etc/mkinitcpio.conf -g /boot/initramfs-5.3-x86_64-fallback.img -S autodetect
   ==> Starting build: 5.3.6-1-MANJARO
   -> Running build hook: [base]
   -> Running build hook: [udev]
   -> Running build hook: [modconf]
   -> Running build hook: [block]
   -> Running build hook: [keyboard]
   -> Running build hook: [keymap]
   -> Running build hook: [filesystems]
   -> Running build hook: [vfio]
   ==> Generating module dependencies
   ==> Creating gzip-compressed initcpio image: /boot/initramfs-5.3-x86_64-fallback.img
   ==> Image generation successful

   $> update-grub


Note that the vfio module is included now in our bootstrap


.. warning::

   I have changed the script from the fedora install because for some reason it was throwing an error on condition so I decided I had better things to do and just go with a simpler script



Install OVMF
------------

.. code-block:: bash

   pacman -S ovmf


The location of the OVMF files will be likely to be different on manjaro than Fedora if you followed the previous post. Adapt the qemu configuration file accordingly.

.. code-block:: bash

   find /usr -name "*.fd" -type f -print
   /usr/share/ovmf/x64/OVMF_CODE.fd
   /usr/share/ovmf/x64/OVMF_VARS.fd

`/etc/libvirt/qemu.conf`

.. code-block::

   nvram = ["/usr/share/ovmf/x64/OVMF_CODE.fd:/usr/share/ovmf/x64/OVMF_VARS.fd"]

That's it, now for the steps to create the Windows 10 Virtual Machine and work around the core error 43 of NVIDIA, follow the instructions in `my previous blog post <https://thereisnospoon.ews-network.net/fedora-30-win10-nvidia-gpu-passthrough/>`_
