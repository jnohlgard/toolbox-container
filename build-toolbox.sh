#!/bin/bash
set -euxo pipefail
mydir=$(cd "$(dirname "$0")"; pwd)

source "${mydir}/common.inc.sh"

toolbox_tag=cppdev:latest
base_image=registry.fedoraproject.org/fedora:latest
dnf_packages_dir=${mydir}/dev-packages.d
dnf_user_packages_dir=${mydir}/user-packages.d

arm_gcc_version=12.2.rel1
riscv_gcc_version=10.2.0-2020.12.8

arm_gcc_package=arm-gnu-toolchain-${arm_gcc_version}-${arch}-arm-none-eabi.tar.xz
riscv_gcc_package=riscv64-unknown-elf-toolchain-${riscv_gcc_version}-${arch}-linux-centos6.tar.gz

dist_dir=${mydir}/toolchain-resources
mgv=${mydir}/mgv/mgv

opt_packages=(
  "arm/${arm_gcc_package}"
  "sifive/${riscv_gcc_package}"
)

# Ensure packages are downloaded
( cd "${dist_dir}"; "${mgv}" get "${opt_packages[@]}" )

# Create a container
container=$(buildah from --pull "${base_image}")
buildah config --author "$(git config user.name) <$(git config user.email)>" ${container}
buildah config --label 'com.github.containers.toolbox=true' ${container}
# Install manpages that are not installed by default in Fedora container images
buildah run ${container} sed -i '/tsflags=nodocs/d' /etc/dnf/dnf.conf
buildah run ${container} dnf -y swap coreutils-single coreutils-full
buildah run ${container} dnf -y swap glibc-minimal-langpack glibc-all-langpacks
buildah run ${container} rm -f /etc/rpm/macros.image-language.conf
buildah run ${container} dnf -y reinstall $(<missing-docs.dnf.txt)

# Install RPMFusion repository configuration
buildah run ${container} sh -c 'dnf -y install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm'

dnf_install_from_list_files ${container} "${dnf_packages_dir}"/*.dnf.txt
if [ -d "${dnf_user_packages_dir}" ]; then
  user_dnf_lists=$(find "${dnf_user_packages_dir}" -name '*.dnf.txt' -print 2>/dev/null)

  if [ -n "${user_dnf_lists}" ]; then
    dnf_install_from_list_files ${container} ${user_dnf_lists}
  fi
fi
buildah run ${container} dnf clean all
( cd "${dist_dir}" && buildah add ${container} "${opt_packages[@]}" /opt/ )
buildah run ${container} ln -s "${riscv_gcc_package%.tar.*}" /opt/riscv64-unknown-elf-toolchain
buildah run ${container} ln -s "${arm_gcc_package%.tar.*}" /opt/arm-none-eabi-toolchain
buildah config --env PATH="$(buildah run $container printenv PATH):/opt/arm-none-eabi-toolchain/bin/:/opt/riscv64-unknown-elf-toolchain/bin" ${container}
buildah commit --rm ${container} ${toolbox_tag}
