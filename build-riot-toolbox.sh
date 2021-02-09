#!/bin/bash
set -euxo pipefail
mydir=$(cd "$(dirname "$0")"; pwd)

arch=$(uname -m)

toolbox_tag=riotbuild
base_image=registry.fedoraproject.org/f33/fedora-toolbox:33
dnf_packages_file=riot-packages.txt

arm_gcc_version=10-2020-q4-major
mips_mti_gcc_version=2020.06-01
riscv_gcc_version=10.1.0-2020.08.2
msp430_gcc_version=10.1.0-18

arm_gcc_package=gcc-arm-none-eabi-${arm_gcc_version}-${arch}-linux.tar.bz2
mips_gcc_package=Codescape.GNU.Tools.Package.${mips_mti_gcc_version}.for.MIPS.MTI.Bare.Metal.CentOS-6.${arch}.tar.gz
riscv_gcc_package=riscv64-unknown-elf-gcc-${riscv_gcc_version}-${arch}-linux-centos6.tar.gz
msp430_gcc_package=riot-msp430-elf-${msp430_gcc_version}.tgz

dist_dir=${mydir}/dist
manifest_downloader=${mydir}/download-verify/manifest-download.sh
manifest=${dist_dir}/RIOT.manifest

opt_packages=(
  "${arm_gcc_package}"
  "${mips_gcc_package}"
  "${riscv_gcc_package}"
  "${msp430_gcc_package}"
)

# Ensure packages are downloaded
( cd "${dist_dir}" && "${manifest_downloader}" "${manifest}" "${opt_packages[@]}" )

# Create a container
container=$(buildah from --pull "${base_image}")
buildah config --label maintainer="Joakim Nohlgård <joakim@nohlgard.se>" ${container}

buildah run ${container} dnf -y install $(<"${dnf_packages_file}")
buildah run ${container} dnf clean all
( cd "${dist_dir}" && buildah add ${container} "${opt_packages[@]}" /opt/ )
buildah config --env PATH="$(buildah run $container printenv PATH):/opt/gcc-arm-none-eabi-${arm_gcc_version}/bin/:/opt/mips-mti-elf/${mips_mti_gcc_version}/bin/:/opt/riscv64-unknown-elf-gcc-${riscv_gcc_version}-${arch}-linux-centos6/bin:/opt/riot-toolchain/msp430-elf/${msp430_gcc_version}/bin/" ${container}
buildah commit --rm ${container} ${toolbox_tag}
