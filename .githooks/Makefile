.PHONY: init
init:
	git config core.hooksPath .githooks
.PHONY: docker-init
init:
	git config core.hooksPath .githooks
	ifeq ($(OS), linux)
		cat precommit-docker.sample >> pre-commit
		cat prepush-docker.sample >> pre-push
	ifeq ($(OS), windows)
		type precommit-docker.sample >> pre-commit
		type prepush-docker.sample >> pre-push
	else
		echo "OS support not"			
.PHONY: docker-sudo-init
init:
	git config core.hooksPath .githooks
	ifeq ($(OS), linux)
		cat precommit-docker-sudo.sample >> pre-commit
		cat prepush-docker-sudo.sample >> pre-push
	ifeq ($(OS), windows)
		type precommit-docker-sudo.sample >> pre-commit
		type prepush-docker-sudo.sample >> pre-push
	else
		echo "OS support not"	
.PHONY: docker-custom-init
init:
	git config core.hooksPath .githooks
	ifeq ($(OS), linux)
		cat precommit-docker-custom.sample >> pre-commit
		cat prepush-docker-custom.sample >> pre-push
	ifeq ($(OS), windows)
		type precommit-docker-custom.sample >> pre-commit
		type prepush-docker-custom.sample >> pre-push
	else
		echo "OS support not"	
.PHONY: windows-init
init:
	git config core.hooksPath .githooks
	cat precommit-windows.sample >> pre-commit
	cat prepush-windows.sample >> pre-push

.PHONY: linux-init
init:
	git config core.hooksPath .githooks
	cat precommit-linux.sample >> pre-commit
	cat prepush-linux.sample >> pre-push