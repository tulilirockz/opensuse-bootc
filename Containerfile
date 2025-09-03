FROM registry.opensuse.org/opensuse/tumbleweed:latest

COPY files/37composefs/ /usr/lib/dracut/modules.d/37composefs/
COPY files/ostree/prepare-root.conf /usr/lib/ostree/prepare-root.conf

RUN zypper install -y ostree-devel git cargo rust

RUN --mount=type=tmpfs,dst=/tmp cd /tmp && \
    git clone https://github.com/bootc-dev/bootc.git bootc && \
    cd bootc && \
    git fetch --all && \
    git switch origin/composefs-backend -d && \
    cargo build --release --bins --features "pre-6.15" && \
    install -Dpm0755 -t /usr/bin ./target/release/bootc && \
    install -Dpm0755 -t /usr/bin ./target/release/system-reinstall-bootc && \
    install -Dpm0755 -t /usr/bin ./target/release/bootc-initramfs-setup

RUN --mount=type=tmpfs,dst=/tmp cd /tmp && \
    git clone https://github.com/p5/coreos-bootupd.git bootupd && \
    cd bootupd && \
    git fetch --all && \
    git switch origin/sdboot-support -d && \
    cargo build --release --bins --features systemd-boot && \
    install -Dpm0755 -t /usr/bin ./target/release/bootupd && \
    ln -s ./bootupd /usr/bin/bootupctl

RUN zypper install -y \
  dracut \
  composefs \
  composefs-experimental \
  kernel-default \
  kernel-firmware-all \
  systemd \
  btrfs-progs \
  e2fsprogs \
  xfsprogs \
  udev \
  cpio \
  zstd \
  binutils \
  dosfstools \
  conmon \
  crun \
  netavark \
  skopeo \
  dbus-1 \
  dbus-1-daemon \
  dbus-broker \
  systemd-boot

RUN cp /usr/bin/bootc-initramfs-setup /usr/lib/dracut/modules.d/37composefs

RUN echo 'add_drivers+=" erofs "' > /etc/dracut.conf.d/composefs.conf

RUN echo "$(basename "$(find /usr/lib/modules -maxdepth 1 -type d | grep -v -E "*.img" | tail -n 1)")" > kernel_version.txt && \
    dracut --force --add debug --no-hostonly --reproducible --zstd --verbose --kver "$(cat kernel_version.txt)"  "/usr/lib/modules/$(cat kernel_version.txt)/initramfs.img" && \
    rm kernel_version.txt

# Alter root file structure a bit for ostree
RUN mkdir -p /boot /sysroot /var/home && \
    rm -rf /var/log /home /root /usr/local /srv && \
    ln -s /var/home /home && \
    ln -s /var/roothome /root && \
    ln -s /var/usrlocal /usr/local && \
    ln -s /var/srv /srv

# Setup a temporary root passwd (changeme) for dev purposes
# TODO: Replace this for a more robust option when in prod
RUN usermod -p '$6$AJv9RHlhEXO6Gpul$5fvVTZXeM0vC03xckTIjY8rdCofnkKSzvF5vEzXDKAby5p3qaOGTHDypVVxKsCE3CbZz7C3NXnbpITrEUvN/Y/' root

# If you want a desktop :)
# RUN zypper install -y -t pattern kde && zypper install -y konsole sddm-qt6 vim dolphin

# Necessary labels
LABEL containers.bootc 1
