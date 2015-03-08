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

PYSRC := $(shell find thingy tests -iname '*.py')
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

$(GEMBIN)/%:
	gem install $* --user-install

deb: $(TARGET) $(PIP) requirements.txt $(PYSRC) Dockerfile
	sudo docker build -t $(ORG)/$(NAME) .
	sudo docker stop $(NAME) || true
	sudo docker rm $(NAME) || true
	sudo docker run -v $(PWD)/dist:/deb -w /deb -u $(shell id -u) $(ORG)/$(NAME) cp /$(NAME)_0.0.0_amd64.deb /deb
