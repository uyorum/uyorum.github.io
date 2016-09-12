.PHONY: help post deploy

## Print help
help:
	make2help

## Create new post
post:
	$(eval FILENAME := $(shell bash -c 'read -p "Enter filename: " filename; echo $$filename'))
	hugo new post/$(FILENAME).md --editor="emacsclient"

## Deploy blog and push source
deploy:
	echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"
	hugo
	git add -A
	git commit -m "Rebuilding site"
	git subtree push --prefix=public git@github.com:uyorum/uyorum.github.io master
	git push origin source
