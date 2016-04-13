.PHONY: deploy docker

all:
	@echo "'make deploy'\tUses cogctl to deploy the bundle"
	@echo "'make docker'\tBuilds and pushes a new Docker image"

deploy:
	cogctl bundles create ./config.yaml

docker:
