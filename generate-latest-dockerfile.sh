#!/bin/bash
set -e

# comparing version: http://stackoverflow.com/questions/16989598/bash-comparing-version-numbers
function version_le() { test "$(echo "$@" | tr " " "\n" | sort -V | tail -n 1)" == "$1"; }

repos='armv7hf rpi i386 amd64 armel'
nodeVersions='0.10.40 0.12.7 4.0.0 4.2.4 5.3.0'
resinUrl="http://resin-packages.s3.amazonaws.com/node/v\$NODE_VERSION/node-v\$NODE_VERSION-linux-#{TARGET_ARCH}.tar.gz"
nodejsUrl="http://nodejs.org/dist/v\$NODE_VERSION/node-v\$NODE_VERSION-linux-#{TARGET_ARCH}.tar.gz"

for repo in $repos; do
	case "$repo" in
	'rpi')
		binary_url=$resinUrl
		target_arch='armv6hf'
		baseImage='rpi-raspbian'
	;;
	'armv7hf')
		binary_url=$resinUrl
		target_arch='armv7hf'
		baseImage='armv7hf-debian'
	;;
	'i386')
		binary_url=$nodejsUrl
		target_arch='x86'
		baseImage='i386-debian'
	;;
	'amd64')
		binary_url=$nodejsUrl
		target_arch='x64'
		baseImage='amd64-debian'
	;;
	'armel')
		binary_url=$resinUrl
		target_arch='armel'
		baseImage='armel-debian'
	;;
	esac
	for nodeVersion in $nodeVersions; do
		echo $nodeVersion
		baseVersion=$(expr match "$nodeVersion" '\([0-9]*\.[0-9]*\)')

		if [ $target_arch == "armv7hf" ] || [ $target_arch == "armv6hf" ]; then
			if version_le "$nodeVersion" "4"; then
				binary_url=$nodejsUrl
				if [ $target_arch == "armv6hf" ]; then
					target_arch='armv6l'
				else
					target_arch='armv7l'
				fi
			fi
		fi

		dockerfilePath=$repo/$baseVersion
		mkdir -p $dockerfilePath/slim
			sed -e s~#{FROM}~resin/$baseImage:jessie~g \
				-e s~#{BINARY_URL}~$binary_url~g \
				-e s~#{NODE_VERSION}~$nodeVersion~g \
				-e s~#{TARGET_ARCH}~$target_arch~g Dockerfile.slim.tpl > $dockerfilePath/slim/Dockerfile
	done
done
