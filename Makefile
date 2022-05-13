default: install

h help:
	@grep '^[a-z]' Makefile

install:
	bundle config set --local path vendor/bundle
	bundle

s serve:
	bundle exec jekyll serve
