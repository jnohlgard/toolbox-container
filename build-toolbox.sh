#!/bin/bash
set -euxo pipefail

toolbox_tag=dev-toolbox

packages_file=my-dev-packages

clion_version=2020.3
base_image=clion-toolbox:${clion_version}

# Create a container
container=$(buildah from "${base_image}")
buildah config --label maintainer="Joakim Nohlgård <joakim@nohlgard.se>" ${container}

buildah run ${container} rpm --import https://yum.corretto.aws/corretto.key 
buildah run ${container} curl -f -L -o /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo
buildah run ${container} dnf -y remove vim-minimal
buildah run ${container} dnf -y install vim-enhanced
buildah run ${container} dnf -y install $(<"${packages_file}")
buildah run ${container} dnf clean all
buildah commit --rm ${container} ${toolbox_tag}
