REGISTRY_OWNER:=fazenda
MULTIARCH:=true
ARCHS:=linux/amd64
PROJECT_TAG:=latest

ifeq (true, $(MULTIARCH))
	ARCHS:=linux/amd64,linux/arm64/v6,linux/arm64/v7,linux/arm64/v8
endif

all: install setup

install:
	@curl -fSL https://get.docker.com | sh
	@sudo usermod -aG docker $USER
	@sudo systemctl enable docker
	@sudo systemctl start docker

# https://github.com/docker/buildx/issues/132#issuecomment-847136842
setup:
	@LATEST=$(shell wget -qO- "https://api.github.com/repos/docker/buildx/releases/latest" | jq -r .name); \
		wget https://github.com/docker/buildx/releases/download/$$LATEST/buildx-$$LATEST.linux-amd64; \
		chmod a+x buildx-$$LATEST.linux-amd64; \
		mkdir -p ~/.docker/cli-plugins; \
		mv buildx-$$LATEST.linux-amd64 ~/.docker/cli-plugins/docker-buildx;
	@docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
	@docker buildx rm builder
	@docker buildx create --name builder --driver docker-container --use
	@docker buildx inspect --bootstrap

build:
	@docker buildx build --platform $(ARCHS) --push --tag ${REGISTRY_OWNER}/hello-world:${PROJECT_TAG} .
