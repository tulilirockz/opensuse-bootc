# OpenSUSE Bootc

Experiment to see if Bootc could work on OpenSUSE

<img width="2201" height="1239" alt="image" src="https://github.com/user-attachments/assets/2d906848-ee82-40b1-8c3d-91e83ef7e492" />

## Building

In order to get a running ubuntu-bootc system you can run the following steps:
```shell
just build-containerfile # This will build the containerfile and all the dependencies you need
just generate-bootable-image # Generates a bootable image for you using bootc!
```

Then you can run the `bootable.img` as your boot disk in your preferred hypervisor.

# Fixes

- `mount /dev/vda2 /sysroot/boot` - You need this to get `bootc status` and other stuff working

Initramfs seems to be failing to mount composefs because of missing `erofs` kernel module during boot. If this happens to you, drop to the shell, `modprobe erofs`, then `systemctl start sysroot.mount` and `systemctl start bootc-initramfs-setup.service`
