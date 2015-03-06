.PHONY: clean test

ORG=ross
NAME=thingy
INSTALLDIR=/opt/${ORG}/${NAME}

VENV := venv
PYTHON := $(VENV)/bin/python
PIP := $(VENV)/bin/pip
PYTEST := $(VENV)/bin/py.test
PEP8 := $(VENV)/bin/pep8
HONCHO := $(VENV)/bin/honcho
COVERAGE := $(VENV)/bin/coverage

PYSRC := $(shell find {thingy,tests} -iname '*.py')
TARGET := $(PWD)/target

GEMBIN := ${HOME}/.gem/ruby/$(shell ruby -e 'puts RUBY_VERSION')/bin
FPM := $(GEMBIN)/fpm
FOREMAN := $(GEMBIN)/foreman

all: $(TARGET)/pep8.errors $(TARGET)/test-results.xml

clean:
	rm -rf venv results node_modules target .coverage htmlcov

$(TARGET):
	mkdir -p $(TARGET)

$(VENV)/deps.touch: $(PIP) requirements.txt
	$(PIP) install -r requirements.txt
	touch $(VENV)/deps.touch

$(VENV)/bin/%: $(PIP)
	$(PIP) install $*

$(VENV)/bin/py.test: $(PIP)
	$(PIP) install pytest pytest-cov pytest-xdist testypie

$(PYTHON) $(PIP):
	virtualenv -p python3 venv

$(TARGET)/pep8.errors: $(TARGET) $(PEP8) $(PYSRC)
	$(PEP8) --exclude=venv . | tee $(TARGET)/pep8.errors || true

$(TARGET)/test-results.xml: $(PIP) $(VENV)/deps.touch $(PYSRC) $(PYTEST) $(HONCHO) $(COVERAGE)
	export PATH=$(VENV)/bin:$(PATH) && \
		$(HONCHO) --procfile Procfile.test --env .env.test start

heroku: $(TARGET)/unit-tests.xml
	pip install django-herokuapp
	$(PYTHON) manage.py heroku_audit
	git push heroku master
	heroku run python manage.py makemigrations

migrate:
	heroku run python manage.py migrate

secret: heroku
	heroku config:set SECRET_KEY=`openssl rand -base64 32`
	heroku config:set PYTHONHASHSEED=random

$(TARGET)/init/$(NAME).conf: Procfile $(HONCHO)
	$(HONCHO) export --app-root=$(INSTALLDIR) --user=$(NAME) --app=$(NANE) supervisord $(TARGET)/init

init: $(TARGET)/init/$(NAME).conf

$(GEMBIN)/%:
	gem install $* --user-install

deb: $(TARGET) $(PIP) requirements.txt $(PYSRC) $(FPM)
	rm -rf $(TARGET)/venv
	virtualenv -p python3 $(TARGET)/build
	$(TARGET)/build/bin/pip install -r requirements.txt
	$(TARGET)/build/bin/python setup.py install
	virtualenv -p python3 --relocatable $(TARGET)/build

	${HOME}/.gem/ruby/1.9.1/bin/fpm \
		--verbose --license GPLv3+ -m "Ross Fenning <deb@rossfenning.co.uk>" \
		-s dir -t deb -n ${ORG}-${NAME} --version $(shell $(VENV)/bin/python setup.py --version) \
		--exclude '*.pyc' --exclude '*.pyo' --exclude __pycache__ \
		--depends supervisor \
		--deb-user $(NAME) --deb-group $(NAME) \
		$(TARGET)/{bin,include,lib}=${INSTALLDIR} etc=/ var=/

deploy: deb
	scp $(ORG)-$(NAME)_*.deb $(REMOTE):/tmp
	ssh $(REMOTE) "cd /tmp ; dpkg -i $(ORG)-$(NAME)_*.deb"
