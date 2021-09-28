.DEFAULT_GOAL:=all

# Don't use quotes in .env
ifneq (,$(wildcard ./.env))
	include .env
	export
endif

all: convert build serve

release: convert build-minial

convert:
	emacs --batch -l publish.el --eval "(publish-all)"

build:
	hugo

build-minial:
	hugo --minify

serve:
	hugo server

clean:
	rm -rf .emacs.d public
