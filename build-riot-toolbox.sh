#!/bin/bash
set -euxo pipefail
mydir=$(cd "$(dirname "$0")"; pwd)

source "${mydir}/common.inc.sh"

toolbox_tag=riotbuild
base_image=registry.fedoraproject.org/fedora-toolbox:35
dnf_packages_dir=${mydir}/riot-packages.d

arm_gcc_version=10.3-2021.10
mips_mti_gcc_version=2020.06-01
riscv_gcc_version=10.2.0-2020.12.8
msp430_gcc_version=10.1.0-18
esp8266_gcc_version=gcc8_4_0-esp-2020r3
esp32_gcc_version=gcc8_4_0-esp-2021r2

arm_gcc_package=gcc-arm-none-eabi-${arm_gcc_version}-${arch}-linux.tar.bz2
mips_gcc_package=Codescape.GNU.Tools.Package.${mips_mti_gcc_version}.for.MIPS.MTI.Bare.Metal.CentOS-6.${arch}.tar.gz
riscv_gcc_package=riscv64-unknown-elf-toolchain-${riscv_gcc_version}-${arch}-linux-centos6.tar.gz
msp430_gcc_package=riot-msp430-elf-${msp430_gcc_version}.tgz
esp8266_gcc_package=xtensa-lx106-elf-${esp8266_gcc_version}-linux-${altarch}.tar.gz
esp32_gcc_package=xtensa-esp32-elf-${esp32_gcc_version}-linux-${altarch}.tar.gz

dist_dir=${mydir}/dist
manifest_downloader=${mydir}/download-verify/manifest-download.sh
manifest=${dist_dir}/RIOT.manifest

opt_packages=(
  "${arm_gcc_package}"
  "${mips_gcc_package}"
  "${riscv_gcc_package}"
  "${msp430_gcc_package}"
  "${esp8266_gcc_package}"
  "${esp32_gcc_package}"
)

# Ensure packages are downloaded
( cd "${dist_dir}" && "${manifest_downloader}" "${manifest}" "${opt_packages[@]}" )

# Create a container
container=$(buildah from --pull "${base_image}")
buildah config --label maintainer="Joakim Nohlgård <joakim@nohlgard.se>" ${container}

dnf_install_from_list_files ${container} "${dnf_packages_dir}"/*.dnf.txt
buildah run ${container} dnf clean all
( cd "${dist_dir}" && buildah add ${container} "${opt_packages[@]}" /opt/ )
buildah config --env PATH="$(buildah run $container printenv PATH):/opt/gcc-arm-none-eabi-${arm_gcc_version}/bin/:/opt/mips-mti-elf/${mips_mti_gcc_version}/bin/:/opt/riscv64-unknown-elf-toolchain-${riscv_gcc_version}-${arch}-linux-centos6/bin:/opt/riot-toolchain/msp430-elf/${msp430_gcc_version}/bin/:/opt/xtensa-lx106-elf/bin:/opt/xtensa-esp32-elf/bin" ${container}
buildah commit --rm ${container} ${toolbox_tag}
