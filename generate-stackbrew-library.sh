#!/bin/bash
set -e

declare -A aliases
aliases=(
	[0.12.0]='0.12 latest' [0.10.36]='0.10' [0.11.16]='0.11' [0.9.12]='0.9' [0.8.28]='0.8'
)

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

repos=( "$@" )
if [ ${#repos[@]} -eq 0 ]; then
	repos=( */ )
fi
repos=( "${repos[@]%/}" )

echo '# maintainer: Joyent Image Team <image-team@joyent.com> (@joyent)'
echo '# maintainer: Trong Nghia Nguyen - resin.io <james@resin.io>'

for repo in "${repos[@]}"; do

	cd $repo
	versions=( */ )
	versions=( "${versions[@]%/}" )
	cd ..
	url='git://github.com/resin-io-library/docker-node'
	for version in "${versions[@]}"; do
		commit="$(git log -1 --format='format:%H' -- "$repo/$version")"
		fullVersion="$(grep -m1 'ENV NODE_VERSION ' "$repo/$version/Dockerfile" | cut -d' ' -f3)"
		versionAliases=( $fullVersion $version ${aliases[$version]} )

		echo
		for va in "${versionAliases[@]}"; do
			echo "$va: ${url}@${commit} $repo/$version"
		done
	
		for variant in onbuild slim wheezy; do
			commit="$(git log -1 --format='format:%H' -- "$repo/$version/$variant")"
			echo
			for va in "${versionAliases[@]}"; do
				if [ "$va" = 'latest' ]; then
					va="$variant"
				else
					va="$va-$variant"
				fi
				echo "$va: ${url}@${commit} $repo/$version/$variant"
			done
		done
	done
done
