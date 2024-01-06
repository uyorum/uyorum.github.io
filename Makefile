.PHONY: help post deploy

REPO := git@github.com:uyorum/uyorum.github.io

## Print help
help:
	make2help

## Subtree add
prepare: public
	rm -rf public
	git subtree add --prefix=public $(REPO) master

## Create new post
post:
	$(eval FILENAME := $(shell bash -c 'read -p "Enter filename: " filename; echo $$filename'))
	hugo new post/$(FILENAME).md

## Remove EXIF tag from jpg
removeexif:
	jhead -purejpg $$(git status -s static/*/*.jpg | grep -oP '(?<=^\?\? ).+')
# git status -s static/*/*.jpg | grep -oP '(?<=^\?\? ).+' | jhead -purejpg static/*/*.jpg

## Deploy blog and push source
deploy:
	echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"
	hugo
	git pull
	scripts/update-date.sh
	git add -A
	git commit -m "Rebuilding site"
	git subtree push --prefix=public $(REPO) master
	git push origin source
