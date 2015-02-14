#!/bin/bash
set -e

declare -A aliases
aliases=(
	[0.12.0]='0.12 latest' [0.10.36]='0.10' [0.11.16]='0.11' [0.9.12]='0.9' [0.8.28]='0.8'
)

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( */ )
versions=( "${versions[@]%/}" )
url='git://github.com/resin-io-library/docker-node'

echo '# maintainer: Joyent Image Team <image-team@joyent.com> (@joyent)'
echo '# maintainer: Trong Nghia Nguyen - resin.io <james@resin.io>'

for version in "${versions[@]}"; do
	cd $version
	fullVersions=( */ )
	fullVersions=( "${fullVersions[@]%/}" )
	for fullVersion in "${fullVersions[@]}"; do
		commit="$(git log -1 --format='format:%H' -- "$fullVersion")"
		versionAliases=( $fullVersion ${aliases[$fullVersion]} )
		
		echo 
		for va in "${versionAliases[@]}"; do
			echo "$va: ${url}@${commit} $version/$fullVersion"
		done
		
		for variant in onbuild slim wheezy; do
			commit="$(git log -1 --format='format:%H' -- "$fullVersion/$variant")"
			echo
			for va in "${versionAliases[@]}"; do
				if [ "$va" = 'latest' ]; then
					va="$variant"
				else
					va="$va-$variant"
				fi
				echo "$va: ${url}@${commit} $version/$fullVersion/$variant"
			done
		done
	done
	cd ..
done
