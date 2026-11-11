# ==============================================================================
# BriskOS 1.0 LTS (Feather) - Containerized ISO Builder
# Reproducible live-build environment based on Debian 12 (Bookworm) amd64
# ==============================================================================

FROM debian:bookworm

LABEL org.opencontainers.image.title="BriskOS 1.0 ISO Builder" \
      org.opencontainers.image.description="Containerized live-build environment for BriskOS 1.0 LTS (Feather)" \
      org.opencontainers.image.authors="BriskOS Project <https://github.com/briskos/briskos>" \
      org.opencontainers.image.source="https://github.com/briskos/briskos" \
      org.opencontainers.image.version="1.0" \
      org.opencontainers.image.licenses="GPL-3.0-or-later"

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true \
    LC_ALL=C.UTF-8 \
    LANG=C.UTF-8

# Install live-build, debootstrap, xorriso, and all required ISO assembly utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    live-build \
    debootstrap \
    xorriso \
    squashfs-tools \
    dosfstools \
    mtools \
    isolinux \
    syslinux-common \
    grub-pc-bin \
    grub-efi-amd64-bin \
    binutils \
    ca-certificates \
    curl \
    wget \
    git \
    bash \
    coreutils \
    findutils \
    grep \
    gawk \
    sed \
    rsync \
    util-linux \
    procps \
    kmod \
    fdisk \
    e2fsprogs \
    file \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set default working directory for the mounted BriskOS workspace
WORKDIR /build

# Default entrypoint delegates to BriskOS build harness
ENTRYPOINT ["/bin/bash", "/build/scripts/build-iso.sh"]
CMD []
