PROJECT=links-cafejosti
APP=linkscafejosti
USER=gjost
SHELL = /bin/bash

APP_VERSION := $(shell cat VERSION)
GIT_SOURCE_URL=https://github.com/gjost/$(APP)
GIT_LINKPILE=https://github.com/gjost/django-linkpile

# Release name e.g. jessie
DEBIAN_CODENAME := $(shell lsb_release -sc)
# Release numbers e.g. 8.10
DEBIAN_RELEASE := $(shell lsb_release -sr)
# Sortable major version tag e.g. deb8
DEBIAN_RELEASE_TAG = deb$(shell lsb_release -sr | cut -c1)

PROJECTDIR=.
APPDIR=$(PROJECTDIR)/$(APP)
APPSDIR=$(PROJECTDIR)/apps/
REQUIREMENTS=$(PROJECTDIR)/requirements.txt
PIP_CACHE_DIR=$(PROJECTDIR)/pip-cache

INSTALL_LINKPILE=$(APPSDIR)/django-linkpile

VIRTUALENV=$(PROJECTDIR)/venv/
SETTINGS=$(APPDIR)/$(APP)/settings.py

CONF_BASE=$(PROJECTDIR)/conf
CONF_LOCAL=$(CONF_BASE)/local.cfg

LOGS_BASE=$(PROJECTDIR)/logs

MEDIA_ROOT=$(PROJECTDIR)/media
STATIC_ROOT=$(PROJECTDIR)/static

SUPERVISOR_CONF=/etc/supervisor/conf.d/$(APP).conf
NGINX_CONF=/etc/nginx/sites-available/$(APP).conf
NGINX_CONF_LINK=/etc/nginx/sites-enabled/$(APP).conf

DEB_BRANCH := $(shell git rev-parse --abbrev-ref HEAD | tr -d _ | tr -d -)
DEB_ARCH=amd64
DEB_NAME_JESSIE=$(APP)-$(DEB_BRANCH)
DEB_NAME_STRETCH=$(APP)-$(DEB_BRANCH)
# Application version, separator (~), Debian release tag e.g. deb8
# Release tag used because sortable and follows Debian project usage.
DEB_VERSION_JESSIE=$(APP_VERSION)~deb8
DEB_VERSION_STRETCH=$(APP_VERSION)~deb9
DEB_FILE_JESSIE=$(DEB_NAME_JESSIE)_$(DEB_VERSION_JESSIE)_$(DEB_ARCH).deb
DEB_FILE_STRETCH=$(DEB_NAME_STRETCH)_$(DEB_VERSION_STRETCH)_$(DEB_ARCH).deb
DEB_VENDOR=gjost
DEB_MAINTAINER=<geoffrey@jostwebwerks.com>
DEB_DESCRIPTION=Linkpile site
DEB_BASE=opt/$(APP)


.PHONY: clean-pyc clean-build docs

help:
	@echo "clean-build - remove build artifacts"
	@echo "clean-pyc - remove Python file artifacts"
	@echo "lint - check style with flake8"
	@echo "test - run tests quickly with the default Python"
	@echo "testall - run tests on every Python version with tox"
	@echo "coverage - check code coverage quickly with the default Python"
	@echo "docs - generate Sphinx HTML documentation, including API docs"
	@echo "release - package and upload a release"
	@echo "sdist - package"


get: get-app apt-update

install: install-app

update: update-app

uninstall: uninstall-app

clean: clean-build clean-pyc


install-virtualenv:
	test -d $(VIRTUALENV) || virtualenv --python=python3 --distribute --setuptools $(VIRTUALENV)

install-setuptools: install-virtualenv
	@echo ""
	@echo "install-setuptools -----------------------------------------------------"
#	apt-get --assume-yes install python-dev
	source $(VIRTUALENV)/bin/activate; \
	pip3 install -U bpython setuptools


get-app:
	git pull
	pip3 install -U -r $(REQUIREMENTS)

get-linkpile:
	@echo ""
	@echo "get-linkpile ----------------------------------------------------------"
	-mkdir apps
	if test -d $(INSTALL_LINKPILE); \
	then cd $(INSTALL_LINKPILE) && git pull; \
	else cd $(APPSDIR) && git clone $(GIT_LINKPILE); \
	fi

setup-linkpile:
	source $(VIRTUALENV)/bin/activate; \
	pip3 install -U -r $(INSTALL_LINKPILE)/requirements.txt
	source $(VIRTUALENV)/bin/activate; \
	cd $(INSTALL_LINKPILE) && python setup.py install

install-app: install-virtualenv
	@echo ""
	@echo "install-app -----------------------------------------------------------"
	source $(VIRTUALENV)/bin/activate; \
	pip3 install -U -r $(REQUIREMENTS)
	-mkdir apps
	cp $(CONF_BASE)/settings.py $(APP)/$(APP)/
# logs dir
	-mkdir $(LOGS_BASE)
	chown -R $(USER).$(USER) $(LOGS_BASE)
	chmod -R 755 $(LOGS_BASE)

uninstall-app:
	cd $(PROJECTDIR)
	source $(VIRTUALENV)/bin/activate; \
	-pip3 uninstall -r $(REQUIREMENTS)

restart:
	/etc/init.d/supervisor restart encycrg

stop:
	/etc/init.d/supervisor stop encycrg

clean-build:
	-rm -fr $(APPDIR)/$(APP)/src
	-rm -fr build/
	-rm -fr dist/
	-rm -fr *.egg-info

clean-pyc:
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +

clean-pip:
	-rm -Rf $(PIP_CACHE_DIR)/*
