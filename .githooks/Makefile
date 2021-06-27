.PHONY: init
init:
	git config core.hooksPath .githooks

.PHONY: docker-init
init:
	git config core.hooksPath .githooks
	cat precommit-docker.sample >> pre-commit
	cat prepush-docker.sample >> pre-push	

.PHONY: docker-sudo-init
init:
	git config core.hooksPath .githooks
	cat precommit-docker-sudo.sample >> pre-commit
	cat prepush-docker-sudo.sample >> pre-push

.PHONY: linux-init
init:
	git config core.hooksPath .githooks
	cat precommit-linux.sample >> pre-commit
	cat prepush-linux.sample >> pre-push