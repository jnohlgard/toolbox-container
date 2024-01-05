FROM registry.fedoraproject.org/fedora-toolbox:latest

RUN sh -c 'dnf -y install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm'

COPY dev-packages.d/ /tmp/packagelists.d
COPY user-packages.d/ /tmp/packagelists.d

RUN sh -c 'cat /tmp/packagelists.d/*.dnf.txt' | sed -e '/^[ \t]*#/d' -e 's/[ \t]#.*$//' | xargs dnf -y install && \
  dnf clean all

ARG arm_gcc_version=13.2.rel1
ARG aarch64_gcc_version=${arm_gcc_version}
ARG riscv_gcc_version=10.2.0-2020.12.8
ARG arch=x86_64

ADD toolchain-resources/arm/arm-gnu-toolchain-${arm_gcc_version}-${arch}-arm-none-eabi.tar.xz /opt/
ADD toolchain-resources/arm/arm-gnu-toolchain-${aarch64_gcc_version}-${arch}-aarch64-none-linux-gnu.tar.xz /opt/
ADD toolchain-resources/arm/arm-gnu-toolchain-${aarch64_gcc_version}-${arch}-aarch64-none-elf.tar.xz /opt/
ADD toolchain-resources/sifive/riscv64-unknown-elf-toolchain-${riscv_gcc_version}-${arch}-linux-centos6.tar.gz /opt/

RUN \
  ln -s -r -v /opt/arm-gnu-toolchain-${arm_gcc_version%rel1}Rel1-${arch}-arm-none-eabi /opt/arm-none-eabi-toolchain && \
  ln -s -r -v /opt/arm-gnu-toolchain-${arm_gcc_version%rel1}Rel1-${arch}-aarch64-none-linux-gnu /opt/aarch64-none-linux-gnu-toolchain && \
  ln -s -r -v /opt/arm-gnu-toolchain-${arm_gcc_version%rel1}Rel1-${arch}-aarch64-none-elf /opt/aarch64-none-elf-toolchain && \
  ln -s -r -v /opt/riscv64-unknown-elf-toolchain-${riscv_gcc_version}-${arch}-linux-centos6 /opt/riscv64-unknown-elf-toolchain

ENV PATH="$PATH:/opt/arm-none-eabi-toolchain/bin:/opt/aarch64-none-linux-gnu-toolchain/bin:/opt/aarch64-none-elf-toolchain/bin:/opt/riscv64-unknown-elf-toolchain/bin"
