#!/bin/bash

set -x
set -e

SYSTEMD_REPOSITORY=https://github.com/gmacario/systemd.git
#SYSTEMD_BRANCH=bootchart-hackme
#SYSTEMD_BRANCH=fix-issue139
#SYSTEMD_BRANCH=fix-issue139-v2
#SYSTEMD_BRANCH=v210
#SYSTEMD_BRANCH=v220

dnf upgrade -y

# -------------------------------------------------------------------
# Install prerequisite packages
# -------------------------------------------------------------------

# Prereq for getting systemd sources
dnf install -y git
# Prereq for building systemd
dnf install -y glib2-devel gperf intltool libcap-devel libgcrypt-devel libmount-devel libtool 
dnf install -y libxslt docbook-style-xsl make
# Additional tools for debugging et al.
dnf install -y gdb openssh-clients procps-ng psmisc tig

# -------------------------------------------------------------------
# Compile testcase for systemd issue 139
# -------------------------------------------------------------------

cd /shared
[ ! -e hello-thread ] && git clone https://github.com/gmacario/hello-thread
cd /shared/hello-thread
make build-native

# -------------------------------------------------------------------
# Compile systemd from sources
# -------------------------------------------------------------------

cd /shared
[ ! -e systemd ] && git clone ${SYSTEMD_REPOSITORY}
cd /shared/systemd
[ "${SYSTEMD_BRANCH}" != "" ] && git checkout ${SYSTEMD_BRANCH}

./autogen.sh

./configure CFLAGS='-g -O0 -ftrapv' \
    --enable-compat-libs \
    --sysconfdir=/etc \
    --localstatedir=/var \
    --libdir=/usr/lib64
# --enable-kdbus \

make

# -------------------------------------------------------------------
# Test: Run systemd-bootchart
# -------------------------------------------------------------------

(/shared/hello-thread/hello-thread &>/tmp/hello-thread.$$) &
sleep 10
ps ax -L

mkdir -p /run/log
#./systemd-bootchart --rel --freq=50 --samples=1000 --scale-x=100 --scale-y=20 --cmdline --per-cpu
/shared/systemd/systemd-bootchart --rel --freq=50 --samples=1000 --scale-x=100 --scale-y=20 --cmdline

ps ax -L
killall hello-thread

# Export SVG
mv /run/log/*.svg /shared/

# EOF
