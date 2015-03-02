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

PYSRC := $(shell find {thingy,tests} -iname '*.py')
TARGET := $(PWD)/target


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

$(TARGET)/test-results.xml: $(PIP) $(VENV)/deps.touch $(PYSRC) $(PYTEST) $(HONCHO)
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

deb: venv
	virtualenv ${VENV}-tools
	${PIP} install virtualenv-tools

	${VENV}-tools/bin/virtualenv-tools --update-path=/opt/${ORG}/${NAME}/${VENV} ${VENV}

	gem list fpm | grep fpm || gem install fpm --user-install
	${HOME}/.gem/ruby/1.8/bin/fpm --verbose --license GPLv3+ -m "Ross Fenning <deb@rossfenning.co.uk>" -s dir -t deb -n ${ORG}-${NAME} --version $(shell $(VENV)/bin/python setup.py --version) --exclude '*.pyc' --exclude '*.pyo' thingy=${INSTALLDIR} ${VENV}=${INSTALLDIR} Procfile=${INSTALLDIR}

	${VENV}-tools/bin/virtualenv-tools --update-path=${VENV} ${VENV}


deploy: deb
	scp $(ORG)-$(NAME)_*.deb $(REMOTE):/tmp
	ssh $(REMOTE) "cd /tmp ; dpkg -i $(ORG)-$(NAME)_*.deb"
