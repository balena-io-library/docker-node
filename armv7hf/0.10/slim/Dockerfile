FROM resin/armv7hf-debian:jessie

ENV NODE_VERSION 0.10.36
ENV NPM_VERSION 2.5.0

RUN buildDeps='curl' \
	&& set -x \
	&& apt-get update && apt-get install -y $buildDeps --no-install-recommends \
	&& rm -rf /var/lib/apt/lists/* \
	&& curl -SLO "http://resin-packages.s3.amazonaws.com/node/v$NODE_VERSION/node-v$NODE_VERSION-linux-armv6hf.tar.gz" \
	&& tar -xzf "node-v$NODE_VERSION-linux-armv6hf.tar.gz" -C /usr/local --strip-components=1 \
	&& rm "node-v$NODE_VERSION-linux-armv6hf.tar.gz" \
	&& apt-get purge -y --auto-remove $buildDeps \
	&& npm install -g npm@"$NPM_VERSION" \
	&& npm cache clear

CMD [ "node" ]
