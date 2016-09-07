#!/bin/bash
set -e
set -o pipefail

# comparing version: http://stackoverflow.com/questions/16989598/bash-comparing-version-numbers
function version_ge() { test "$(echo "$@" | tr " " "\n" | sort -V | tail -n 1)" == "$1"; }

# extract checksum for node binary
function extract_checksum()
{
	# $1: binary type, 0: in-house, 1: official.
	# $2: node version

	if [ $1 -eq 0 ]; then
		checksum=$(grep " node-v$2-linux-$binary_arch.tar.gz" SHASUMS256.txt)
	else
		curl -SLO "https://nodejs.org/dist/v$2/SHASUMS256.txt.asc" \
		&& gpg --verify SHASUMS256.txt.asc \
		&& checksum=$(grep " node-v$2-linux-$binary_arch.tar.gz\$" SHASUMS256.txt.asc) \
		&& rm -f SHASUMS256.txt.asc
	fi
}

# gpg keys listed at https://github.com/nodejs/node
for key in \
9554F04D7259F04124DE6B476D5A82AC7E37093B \
94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
0034A06D9D9B0064CE8ADF6BF1747F4AD2306D93 \
FD3A5288F042B6850C66B31F09FE44734EB7990E \
71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
B9AE9905FFD7803F25714661B63B535A4C206CA9 \
C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
7937DFD2AB06298B2293C3187D33FF9D0246406D \
114F43EE0176B71C7BC219DD50A3051F888C628D \
; do \
	gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
done

QEMU_VERSION='2.5.0-resin-rc3'
QEMU_SHA256='dc36002fd3e362710e1654c4dfdc84a064b710e10a2323e8e4c8e24cb3921818'

# Download QEMU
curl -SLO https://github.com/resin-io/qemu/releases/download/$QEMU_VERSION/qemu-$QEMU_VERSION.tar.gz \
	&& echo "$QEMU_SHA256  qemu-$QEMU_VERSION.tar.gz" > qemu-$QEMU_VERSION.tar.gz.sha256sum \
	&& sha256sum -c qemu-$QEMU_VERSION.tar.gz.sha256sum \
	&& tar -xz --strip-components=1 -f qemu-$QEMU_VERSION.tar.gz

chmod +x qemu-arm-static

archs='armv7hf rpi i386 amd64 armel'
nodeVersions='0.10.46 4.4.7 5.12.0 6.5.0'
resinUrl="http://resin-packages.s3.amazonaws.com/node/v\$NODE_VERSION/node-v\$NODE_VERSION-linux-#{TARGET_ARCH}.tar.gz"
nodejsUrl="http://nodejs.org/dist/v\$NODE_VERSION/node-v\$NODE_VERSION-linux-#{TARGET_ARCH}.tar.gz"

for arch in $archs; do
	for nodeVersion in $nodeVersions; do
		case "$arch" in
		'rpi')
			binary_url=$resinUrl
			binary_arch='armv6hf'
			baseImage='rpi-raspbian'
		;;
		'armv7hf')
			binary_url=$resinUrl
			binary_arch='armv7hf'
			baseImage='armv7hf-debian'
		;;
		'i386')
			binary_url=$nodejsUrl
			binary_arch='x86'
			baseImage='i386-debian'
		;;
		'amd64')
			binary_url=$nodejsUrl
			binary_arch='x64'
			baseImage='amd64-debian'
		;;
		'armel')
			binary_url=$resinUrl
			binary_arch='armel'
			baseImage='armel-debian'
		;;
		esac

		baseVersion=$(expr match "$nodeVersion" '\([0-9]*\.[0-9]*\)')
		if [ $arch == "armel" ] && [ $nodeVersion == "6.2.0" ]; then
			continue
		fi
		# Debian.
		# For armv7hf and armv6hf, if node version is greater or equal than 4.x.x then that image will use binaries from official distribution, otherwise it will use binaries from resin.
		if [ $binary_arch == "armv7hf" ] || [ $binary_arch == "armv6hf" ]; then
			if version_ge "$nodeVersion" "4"; then
				binary_url=$nodejsUrl
				if [ $binary_arch == "armv6hf" ]; then
					binary_arch='armv6l'
				else
					binary_arch='armv7l'
				fi
			fi
		fi

		# Extract checksum
		if [ $binary_url == "$nodejsUrl" ]; then
			extract_checksum 1 $nodeVersion
		else
			extract_checksum 0 $nodeVersion
		fi

		debian_dockerfilePath=$arch/debian/$baseVersion
		mkdir -p $debian_dockerfilePath/slim
		sed -e s~#{FROM}~resin/$baseImage:jessie~g \
			-e s~#{BINARY_URL}~$binary_url~g \
			-e s~#{CHECKSUM}~"$checksum"~g \
			-e s~#{NODE_VERSION}~$nodeVersion~g \
			-e s~#{TARGET_ARCH}~$binary_arch~g Dockerfile.debian.slim.tpl > $debian_dockerfilePath/slim/Dockerfile

		# Alpine
		case "$binary_arch" in
		'x64')
			binary_arch='alpine-amd64'
			binary_url=$resinUrl
			baseImage='alpine'
			label="LABEL io.resin.architecture=\"amd64\""
			qemu=''
		;;
		'x86')
			binary_arch='alpine-i386'
			binary_url=$resinUrl
			baseImage='i386/alpine'
			label="LABEL io.resin.architecture=\"i386\""
			qemu=''
		;;
		'armel')
			# armel not supported yet.
			continue
		;;
		*)
			binary_arch='alpine-armhf'
			binary_url=$resinUrl
			baseImage='armhf/alpine'
			label="LABEL io.resin.architecture=\"armhf\" io.resin.qemu.version=\"$QEMU_VERSION\""
			qemu='COPY qemu-arm-static /usr/bin/qemu-arm-static'
		;;
		esac

		# Node 0.12.x are not supported atm.
		if [ $baseVersion == '0.12' ]; then
			continue
		fi
		extract_checksum 0 $nodeVersion

		alpine_dockerfilePath=$arch/alpine/$baseVersion
		mkdir -p $alpine_dockerfilePath/slim
		sed -e s~#{FROM}~$baseImage:latest~g \
			-e s~#{BINARY_URL}~$binary_url~g \
			-e s~#{NODE_VERSION}~$nodeVersion~g \
			-e s~#{CHECKSUM}~"$checksum"~g \
			-e s~#{TARGET_ARCH}~$binary_arch~g \
			-e s~#{LABEL}~"$label"~g \
			-e s~#{QEMU}~"$qemu"~g Dockerfile.alpine.slim.tpl > $alpine_dockerfilePath/slim/Dockerfile

		if [ $binary_arch == "alpine-armhf" ]; then
			cp qemu-arm-static $alpine_dockerfilePath/slim/
		fi
	done
done
rm -rf qemu-*
