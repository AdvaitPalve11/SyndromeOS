FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
        build-essential \
        gcc \
        g++ \
        binutils \
        cmake \
        make \
        gnu-efi \
        ovmf \
        dosfstools \
        mtools \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Compatibility links for /usr/local
RUN ln -sf /usr/include/efi /usr/local/include/efi && \
    ln -sf /usr/lib/libefi.a /usr/local/lib/libefi.a && \
    ln -sf /usr/lib/libgnuefi.a /usr/local/lib/libgnuefi.a && \
    ln -sf /usr/lib/crt0-efi-x86_64.o /usr/local/lib/crt0-efi-x86_64.o && \
    ln -sf /usr/lib/elf_x86_64_efi.lds /usr/local/lib/elf_x86_64_efi.lds

WORKDIR /workspaces/SyndromeOS