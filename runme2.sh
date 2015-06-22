#!/bin/sh

set -x
set -e

SYSTEMD_REPOSITORY=https://github.com/gmacario/systemd.git
#SYSTEMD_BRANCH=bootchart-hackme
SYSTEMD_BRANCH=fix-issue139

dnf upgrade -y

# Prereq for getting systemd sources
dnf install -y git
# Prereq for building systemd
dnf install -y gperf intltool libcap-devel libgcrypt-devel libmount-devel libtool 
dnf install -y libxslt docbook-style-xsl make
# Additional tools for debugging et al.
dnf install -y gdb openssh-clients tig

cd /shared
[ ! -e systemd ] && git clone ${SYSTEMD_REPOSITORY}
cd /shared/systemd
git checkout ${SYSTEMD_BRANCH}

./autogen.sh

./configure CFLAGS='-g -O0 -ftrapv' \
    --enable-compat-libs \
    --sysconfdir=/etc \
    --localstatedir=/var \
    --libdir=/usr/lib64
# --enable-kdbus \

make

# Test
mkdir -p /run/log
./systemd-bootchart --rel --freq=50 --samples=1000 --scale-x=100 --scale-y=20 --cmdline --per-cpu
cp /run/log/*.svg /shared/

# EOF
