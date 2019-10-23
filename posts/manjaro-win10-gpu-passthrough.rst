.. title: Manjaro - Win10 GPU passthrough
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


Enable IOMMU
------------


Enable VFIO for your device(s)
------------------------------

For the non familiar people with Arch Linux specific commands, coming from another OS like Fedora (like I was) this was the most painful experience to port from that other OS to Arch Linux, however I found that the way to do it in Arch Linux to make a lot of sense and be very clean, just would benefit a lot from more steps and details from people online!


Install OVMF
------------

That's it, now for the steps to create the Windows 10 Virtual Machine and work around the core error 43 of NVIDIA, follow the instructions in `my previous blog post <https://thereisnospoon.ews-network.net/>`_
