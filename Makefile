.DEFAULT_GOAL:=all

all: convert build-minial

convert:
	emacs --batch -l publish.el --eval "(publish-all)"

build:
	hugo

build-minial:
	hugo --minify

serve:
	hugo server
