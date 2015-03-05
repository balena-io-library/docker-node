#!/bin/bash
set -e

repos='armv7hf rpi'
nodeVersions='0.8.28 0.9.12 '

#0.10.x
nodeVersions+=$(seq -f "0.10.%g" -s ' ' 0 36)
nodeVersions+=' '
#0.11.x
nodeVersions+=$(seq -f "0.11.%g" -s ' ' 0 16)
nodeVersions+=' '
#0.12.x
nodeVersions+=$(seq -f "0.12.%g" -s ' ' 0 0)

for repo in $repos; do
	for nodeVersion in $nodeVersions; do
		echo $nodeVersion
		baseVersion=$(expr match "$nodeVersion" '\([0-9]*\.[0-9]*\)')
		dockerfilePath=$repo/$baseVersion/$nodeVersion
		mkdir -p $dockerfilePath
		sed -e s~#{FROM}~resin/$repo-buildpack-deps:jessie~g \
			-e s~#{NODE_VERSION}~$nodeVersion~g Dockerfile.tpl > $dockerfilePath/Dockerfile

		mkdir -p $dockerfilePath/onbuild
		sed -e s~#{FROM}~resin/$repo-node:$nodeVersion~g Dockerfile.onbuild.tpl > $dockerfilePath/onbuild/Dockerfile

		

		mkdir -p $dockerfilePath/wheezy
		sed -e s~#{FROM}~resin/$repo-buildpack-deps:wheezy~g \
			-e s~#{NODE_VERSION}~$nodeVersion~g Dockerfile.tpl > $dockerfilePath/wheezy/Dockerfile

		# Only for rpi-raspbian
		if [ $repo == "rpi" ]; then
			mkdir -p $dockerfilePath/slim
			sed -e s~#{FROM}~resin/rpi-raspbian:jessie~g \
				-e s~#{NODE_VERSION}~$nodeVersion~g Dockerfile.slim.tpl > $dockerfilePath/slim/Dockerfile
		fi 

		# Only for armv7hf-debian
		if [ $repo == "armv7hf" ]; then
			mkdir -p $dockerfilePath/sid
			sed -e s~#{FROM}~resin/$repo-buildpack-deps:sid~g \
				-e s~#{NODE_VERSION}~$nodeVersion~g Dockerfile.tpl > $dockerfilePath/sid/Dockerfile
			mkdir -p $dockerfilePath/slim
			sed -e s~#{FROM}~resin/armv7hf-debian:jessie~g \
				-e s~#{NODE_VERSION}~$nodeVersion~g Dockerfile.slim.tpl > $dockerfilePath/slim/Dockerfile
		fi
	done
done
