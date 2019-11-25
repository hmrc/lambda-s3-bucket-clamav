#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

AMZ_LINUX_VERSION:=2
current_dir := $(shell pwd)
container_dir := /opt/app
ARTIFACT := clamav-scanner-lambda.zip

.PHONY: help
help:  ## Print the help documentation
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

all: build  ## Build the entire project

.PHONY: clean
clean:  ## Clean build artifacts
	rm -rf bin/
	rm -rf build/
	find ./ -type d -name '__pycache__' -delete
	find ./ -type f -name '*.pyc' -delete

.PHONY: build 
build: clean  
	docker run --rm -i \
		-v $(current_dir):$(container_dir) \
		amazonlinux:$(AMZ_LINUX_VERSION) \
		/bin/bash -c "cd $(container_dir) && ./build_lambda.sh $(ARTIFACT)"
	docker run --rm -i \
		-v $(current_dir):$(container_dir) \
		amazonlinux:$(AMZ_LINUX_VERSION) \
		chown -R $(shell id -u):$(shell id -g) $(container_dir)/build $(container_dir)/env $(container_dir)/bin

push-s3:
	@aws s3 cp target/$(ARTIFACT) s3://$(S3_BUCKET)/$(ARTIFACT) --acl=bucket-owner-full-control
	@aws s3 cp target/$(ARTIFACT).base64sha256 s3://$(S3_BUCKET)/$(ARTIFACT).base64sha256 --acl=bucket-owner-full-control --content-type=text/plain


test-dependencies:
	@pipenv install --dev

test-format: ## Test code formatting
	@pipenv run flake8 *.py

test-safety: ## Python module safety checks
	@pipenv check

.PHONY: test
test: test-dependencies clean  ## Run python tests
	pipenv run nosetests

test-all: test-format test-safety test ## Run all tests
