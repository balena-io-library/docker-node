FROM resin/rpi-raspbian:jessie

ENV NODE_VERSION 0.11.8
ENV NPM_VERSION 2.5.0

RUN buildDeps='curl' \
	&& set -x \
	&& apt-get update && apt-get install -y $buildDeps --no-install-recommends \
	&& rm -rf /var/lib/apt/lists/* \
	&& curl -SLO "http://resin-packages.s3.amazonaws.com/node/v$NODE_VERSION/node-v$NODE_VERSION-linux-armv6hf.tar.gz" \
	&& tar -xzf "node-v$NODE_VERSION-linux-armv6hf.tar.gz" -C /usr/local --strip-components=1 \
	&& rm "node-v$NODE_VERSION-linux-armv6hf.tar.gz" \
	&& apt-get purge -y --auto-remove $buildDeps \
	&& npm install -g npm@1.4.28 \
	&& npm install -g npm@"$NPM_VERSION" \
	&& npm cache clear

# note: we have to install npm 1.4.28 first because we can't go straight from 1.2 -> 2.0
# see also https://github.com/docker-library/node/issues/15#issuecomment-57879931

CMD [ "node" ]
http://resin-packages.s3.amazonaws.com/node/v0.10.2/node-v0.10.2-linux-armv6hf.tar.gz