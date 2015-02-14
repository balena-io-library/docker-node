all: rpi-node

REPO_NAMES="resin/rpi-node"
clean:
	rm -rf Dockerfiles/rpi-node
	for name in $(REPO_NAMES); do \
		docker rmi -f $$(docker images | grep "^$$name" | awk '{print $$3}'); \
	done

rpi-node-%: 
	$(eval nodeVersion=$*)
	$(eval baseVersion=`expr match "$(nodeVersion)" '\([0-9]*\.[0-9]*\)'`)
	$(eval dockerfilePath=Dockerfiles/$(baseVersion)/$(nodeVersion))
	mkdir -p $(dockerfilePath)
	sed -e s~#{FROM}~resin/rpi-raspbian:jessie~g \
		-e s~#{NODE_VERSION}~$(nodeVersion)~g Dockerfile.tpl > $(dockerfilePath)/Dockerfile

	mkdir -p $(dockerfilePath)/onbuild
	sed -e s~#{FROM}~resin/rpi-node:$(nodeVersion)~g Dockerfile.onbuild.tpl > $(dockerfilePath)/onbuild/Dockerfile

	mkdir -p $(dockerfilePath)/slim
	sed -e s~#{FROM}~resin/rpi-raspbian:jessie~g \
		-e s~#{NODE_VERSION}~$(nodeVersion)~g Dockerfile.tpl > $(dockerfilePath)/slim/Dockerfile

	mkdir -p $(dockerfilePath)/wheezy
	ed -e s~#{FROM}~resin/rpi-raspbian:wheezy~g \
		-e s~#{NODE_VERSION}~$(nodeVersion)~g Dockerfile.tpl > $(dockerfilePath)/Dockerfile

.PHONY: rpi-node rpi-node-%

# List all the rpi-node versions..
rpi-node: rpi-node-0.8.28
rpi-node: rpi-node-0.9.12
rpi-node: rpi-node-0.10.22
rpi-node: rpi-node-0.10.23
rpi-node: rpi-node-0.10.24
rpi-node: rpi-node-0.10.25
rpi-node: rpi-node-0.10.26
rpi-node: rpi-node-0.10.27
rpi-node: rpi-node-0.10.28
rpi-node: rpi-node-0.10.29
rpi-node: rpi-node-0.10.30
rpi-node: rpi-node-0.10.31
rpi-node: rpi-node-0.10.32
rpi-node: rpi-node-0.10.33
rpi-node: rpi-node-0.10.34
rpi-node: rpi-node-0.10.35
rpi-node: rpi-node-0.10.36
rpi-node: rpi-node-0.11.1
rpi-node: rpi-node-0.11.2
rpi-node: rpi-node-0.11.3
rpi-node: rpi-node-0.11.4
rpi-node: rpi-node-0.11.5
rpi-node: rpi-node-0.11.6
rpi-node: rpi-node-0.11.7
rpi-node: rpi-node-0.11.8
rpi-node: rpi-node-0.11.9
rpi-node: rpi-node-0.11.10
rpi-node: rpi-node-0.11.11
rpi-node: rpi-node-0.11.12
rpi-node: rpi-node-0.11.13
rpi-node: rpi-node-0.11.14
rpi-node: rpi-node-0.11.15
rpi-node: rpi-node-0.11.16
rpi-node: rpi-node-0.12.0