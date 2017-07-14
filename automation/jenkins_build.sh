#!/bin/bash

# comparing version: http://stackoverflow.com/questions/16989598/bash-comparing-version-numbers
function version_ge() { test "$(echo "$@" | tr " " "\n" | sort -V | tail -n 1)" == "$1"; }

# extract checksum for node binary
function extract_checksum()
{
	# $1: binary type, 0: in-house, 1: official.
	# $2: node version
	# $3: variable name for result

	local __resultVar=$3

	if [ $1 -eq 0 ]; then
		local __checksum=$(grep " node-v$2-linux-$binaryArch.tar.gz" SHASUMS256.txt)
	else
		curl -SLO "https://nodejs.org/dist/v$2/SHASUMS256.txt.asc" \
		&& gpg --verify SHASUMS256.txt.asc \
		&& local __checksum=$(grep " node-v$2-linux-$binaryArch.tar.gz\$" SHASUMS256.txt.asc) \
		&& rm -f SHASUMS256.txt.asc
	fi
	eval $__resultVar="'$__checksum'"
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
56730D5401028683275BD23C23EFEFE93C4CFFFE \
; do \
	gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
done

resinUrl="http://resin-packages.s3.amazonaws.com/node/v\$NODE_VERSION/node-v\$NODE_VERSION-linux-#{TARGET_ARCH}.tar.gz"
nodejsUrl="http://nodejs.org/dist/v\$NODE_VERSION/node-v\$NODE_VERSION-linux-#{TARGET_ARCH}.tar.gz"
dateStamp=$(date +'%Y%m%d' -u)
baseVersion=$(expr match "$NODE_VERSION" '\([0-9]*\.[0-9]*\)')

for ARCH in $ARCHS
do
	case "$ARCH" in
		'rpi')
			baseImage='resin/rpi-raspbian:jessie'
			binaryArch='armv6l'
			binaryUrl=$nodejsUrl
			extract_checksum 1 $NODE_VERSION "checksum"
		;;
		'armv7hf')
			baseImage='resin/armv7hf-debian:jessie'
			binaryArch='armv7hf'
			binaryUrl=$resinUrl
			extract_checksum 0 $NODE_VERSION "checksum"
		;;
		'armel')
			baseImage='resin/armel-debian:jessie'
			binaryArch='armel'
			binaryUrl=$resinUrl
			extract_checksum 0 $NODE_VERSION "checksum"
		;;
		'aarch64')
			baseImage='resin/aarch64-debian:jessie'
			binaryArch='arm64'
			binaryUrl=$nodejsUrl
			extract_checksum 1 $NODE_VERSION "checksum"
		;;
		'i386')
			baseImage='resin/i386-debian:jessie'
			binaryArch='x86'
			binaryUrl=$nodejsUrl
			extract_checksum 1 $NODE_VERSION "checksum"
		;;
		'amd64')
			baseImage='resin/amd64-debian:jessie'
			binaryArch='x64'
			binaryUrl=$nodejsUrl
			extract_checksum 1 $NODE_VERSION "checksum"
		;;
		#'alpine-armhf')
		#	sed -e s~#{FROM}~resin/armhf-alpine:latest~g Dockerfile.alpine.tpl > Dockerfile
		#;;
		#'alpine-i386')
		#	sed -e s~#{FROM}~resin/i386-alpine:latest~g Dockerfile.alpine.tpl > Dockerfile
		#;;
		#'alpine-amd64')
		#	sed -e s~#{FROM}~resin/amd64-alpine:latest~g Dockerfile.alpine.tpl > Dockerfile
		#;;
	esac

	if [ $baseVersion != '0.10' ] && [ $binaryArch == "armel" ]; then
		# we only build armel node v0.10.x.
		continue
	fi

	sed -e s~#{FROM}~"$baseImage"~g \
			-e s~#{BINARY_URL}~$binaryUrl~g \
			-e s~#{NODE_VERSION}~$NODE_VERSION~g \
			-e s~#{CHECKSUM}~"$checksum"~g \
			-e s~#{TARGET_ARCH}~$binaryArch~g Dockerfile.debian.slim.tpl > Dockerfile

	docker build -t resin/$ARCH-node:$baseVersion-slim .
	docker tag resin/$ARCH-node:$baseVersion-slim resin/$ARCH-node:$baseVersion-slim-$dateStamp
	docker push resin/$ARCH-node:$baseVersion-slim
	docker push resin/$ARCH-node:$baseVersion-slim-$dateStamp
	docker rmi -f resin/$ARCH-node:$baseVersion-slim resin/$ARCH-node:$baseVersion-slim-$dateStamp
done