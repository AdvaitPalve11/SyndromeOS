FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
        build-essential \
        gcc \
        binutils \
        cmake \
        make \
        git \
        wget \
        ca-certificates \
        dosfstools \
        mtools \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------
# Build GNU-EFI from source
# -----------------------------

WORKDIR /opt

RUN git clone --depth 1 https://git.code.sf.net/p/gnu-efi/code gnu-efi

WORKDIR /opt/gnu-efi

RUN make

RUN make install

WORKDIR /workspaces/SyndromeOS