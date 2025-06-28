FROM ubuntu:20.04
LABEL maintainer="Hari Shankar <harishankarm04@gmail.com>"

# Avoid tzdata prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Kolkata

# Defining dynamic linker path
ENV LD_LIBRARY_PATH=/usr/local/lib

# Arguments
ARG USERNAME=embedded

# ========= Uncomment for Mac OS ============ #
# ARG USER_UID=1000
# ARG USER_GID=$USER_UID

# COPY entrypoint.sh /entrypoint.sh
# RUN chmod +x /entrypoint.sh
# ENTRYPOINT ["/entrypoint.sh"]
# ========= Uncomment for Mac OS ============ #

# Install packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo \
    tzdata \
    git \
    cmake \
    wget \
    make \
    usbutils \
    software-properties-common \
    build-essential \
    curl \
    ninja-build \
    ca-certificates

# OPENOCD support packages
RUN apt-get install -y --no-install-recommends \ 
    libtool \
    pkg-config \
    autoconf \
    automake \
    libjim-dev \
    libusb-1.0-0-dev \
    libusb-dev \
    libftdi1-dev \
    libhidapi-dev

# Install to use SEGGER J-Link debug probes
RUN git clone https://github.com/syntacore/libjaylink.git \
    && cd libjaylink \
    && ./autogen.sh \
    && ./configure \
    && make \
    && make install

RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install ARM GNU Toolchain manually
    # Version : 14.2.rel1
    # Architecture : x86_64 Linux Hosted
    # Target : ARM Cortex-M (Baremetal)
RUN curl -LO https://developer.arm.com/-/media/Files/downloads/gnu/14.2.rel1/binrel/arm-gnu-toolchain-14.2.rel1-aarch64-arm-none-eabi.tar.xz && \
    tar -xf arm-gnu-toolchain-14.2.rel1-aarch64-arm-none-eabi.tar.xz -C /opt && \
    ln -s /opt/arm-gnu-toolchain-14.2.rel1-aarch64-arm-none-eabi/bin/* /usr/local/bin/ && \
    rm arm-gnu-toolchain-14.2.rel1-aarch64-arm-none-eabi.tar.xz

# Build and install OPENOCD from repository
RUN cd /usr/src/ \
    && git clone --depth 1 https://github.com/openocd-org/openocd.git \
    && cd /usr/src/openocd \
    && ./bootstrap \
    && ./configure --enable-stlink --enable-jlink --enable-ftdi --enable-cmsis-dap 

RUN cd /usr/src/openocd && \
    make -j"$(nproc)" && \
    make install && \
    cd .. && \
    rm -rf openocd

# Create user and group (Linux-friendly)
RUN groupadd --gid 1000 $USERNAME && \
    useradd -ms /bin/bash --uid 1000 --gid 1000 $USERNAME && \
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

#OpenOCD talks to the chip through USB, so we need grant our account access to the FTDI. 
RUN cp /usr/local/share/openocd/contrib/60-openocd.rules /etc/udev/rules.d/60-openocd.rules

USER $USERNAME
WORKDIR /home/$USERNAME

CMD [ "bash" ]
