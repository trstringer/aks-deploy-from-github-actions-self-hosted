VERSION_FILE := version
VERSION := $(shell cat ${VERSION_FILE})
RESOURCE_NAME ?= aksgithub1
IMAGE_REPO := $(RESOURCE_NAME).azurecr.io/upgrade-test

.PHONY: build
build:
	docker build -t $(IMAGE_REPO):$(VERSION) .

.PHONY: infrastructure
infrastructure:
	az login --identity
	az deployment group create \
		--resource-group $(RESOURCE_NAME) \
		--template-file ./aks_cluster.bicep \
		--location eastus \
		--parameters clusterName=$(RESOURCE_NAME)
	az aks update \
		--resource-group $(RESOURCE_NAME) \
		--name $(RESOURCE_NAME) \
		--attach-acr $(RESOURCE_NAME)
	az aks get-credentials \
		--resource-group $(RESOURCE_NAME) \
		--name $(RESOURCE_NAME)

.PHONY: registry-login
registry-login:
	az login --identity
	az acr login --name $(RESOURCE_NAME)

.PHONY: push
push:
	docker push $(IMAGE_REPO):$(VERSION)

.PHONY: deploy
deploy:
	sed 's|IMAGE_REPO|$(IMAGE_REPO)|g; s/VERSION/$(VERSION)/g' ./deployment.yaml | \
		kubectl apply -f -
