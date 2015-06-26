#!/bin/bash

set -x
set -e

SYSTEMD_REPOSITORY=https://github.com/gmacario/systemd.git
#SYSTEMD_BRANCH=bootchart-hackme
#SYSTEMD_BRANCH=fix-issue139
#SYSTEMD_BRANCH=fix-issue139-v2

# -------------------------------------------------------------------
# Poor-man-bisect to find the "CPU utilization" regression
#
# Bad "CPU utilization" graph
#SYSTEMD_BRANCH=v220
#SYSTEMD_BRANCH=af672f0
#SYSTEMD_BRANCH=1f2ecb0
#
# Test
#
# Good "CPU utilization" graph
#SYSTEMD_BRANCH=f917813
#SYSTEMD_BRANCH=c87664f
#SYSTEMD_BRANCH=v219
#SYSTEMD_BRANCH=v217
#SYSTEMD_BRANCH=v215
#SYSTEMD_BRANCH=v210
#SYSTEMD_BRANCH=v209
#SYSTEMD_BRANCH=v208
#SYSTEMD_BRANCH=v206
#SYSTEMD_BRANCH=v204
#
#	$ git log --oneline v219..v220 -- src/bootchart
# 	5d236c1 bootchart: kill newline characters from log_error_errno() calls
# 	eaf1560 bootchart: fix check for no fd
# BAD	af672f0 bootchart: assorted coding style fixes
# BAD 	1f2ecb0 bootchart: kill a bunch of global variables
# OK 	f917813 bootchart: clean up sysfd and proc handling
# 	34a4071 bootchart: clean up control flow logic
# 	0399586 bootchart: switch to log_* helpers
# OK	c87664f systemd-bootchart: Repair Entropy Graph
# 	58ec01b systemd-bootchart: Prevent leaking file descriptors in open-fdopen combination
# 	9964a9e systemd-bootchart: Prevent closing random file descriptors
# 	de49f27 bootchart: more useful error message for common error
# 	b53a248 bootchart: remove duplicated code, prevent creating empty files
# 	0c90070 Add type specifier for int
# 	d92f98b bootchart: use _cleanup_
# 	e93549e Do not advertise .d snippets over main config file
# 	c1682f1 bootchart: svg: fix checking of list end
# 	a804d84 bootchart: fix default init path
# 	2eec67a remove unused includes
# 	$
# -------------------------------------------------------------------

dnf upgrade -y

# -------------------------------------------------------------------
# Install prerequisite packages
# -------------------------------------------------------------------

# Prereq for getting systemd sources
dnf install -y git
# Prereq for building systemd
dnf install -y dbus-devel glib2-devel gperf intltool libcap-devel libgcrypt-devel libmount-devel libtool 
dnf install -y xz-devel libxslt docbook-style-xsl make
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
#/shared/systemd/systemd-bootchart --rel --freq=50 --samples=1000 --scale-x=100 --scale-y=20 --cmdline
#/shared/systemd/systemd-bootchart --rel --freq=50 --samples=1000 --scale-x=100 --scale-y=20 --no-filter --cmdline
#/shared/systemd/systemd-bootchart --rel --freq=50 --samples=5000 --scale-x=5 --scale-y=20 --no-filter --cmdline --per-cpu
#/shared/systemd/systemd-bootchart --rel --freq=50 --samples=500 --scale-x=100 --scale-y=20 --no-filter --cmdline --per-cpu
#/shared/systemd/systemd-bootchart --rel --freq=50 --samples=500 --scale-x=100 --scale-y=20 --no-filter --cmdline
/shared/systemd/systemd-bootchart --rel --freq=50 --samples=10 --scale-x=100 --scale-y=20 --no-filter --cmdline

ps ax -L
killall hello-thread

# Export SVG
mv /run/log/*.svg /shared/

# EOF
