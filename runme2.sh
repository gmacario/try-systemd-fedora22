#!/bin/sh

set -x
set -e

dnf update

dnf install -y openssh-clients

# Prereq for getting systemd sources
dnf install -y git
# Prereq for building systemd
dnf install -y gperf intltool libcap-devel libgcrypt-devel libmount-devel libtool 
dnf install -y libxslt make

cd /shared
[ ! -e systemd ] && git clone https://github.com/gmacario/systemd.git
cd /shared/systemd
git checkout bootchart-hackme

./autogen.sh

./configure CFLAGS='-g -O0 -ftrapv' \
    --enable-compat-libs \
    --sysconfdir=/etc \
    --localstatedir=/var \
    --libdir=/usr/lib64
# --enable-kdbus \

make

# TODO

# EOF
