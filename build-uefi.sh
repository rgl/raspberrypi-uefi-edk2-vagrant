#!/bin/bash
set -euxo pipefail

su vagrant -c bash <<'EOF'
set -euxo pipefail

cd ~/rpi4-uefi

./rpi4-uefi-build-release.sh
EOF
