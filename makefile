ORG=ross
NAME=thingy
VENV=venv
INSTALLDIR=/opt/${ORG}/${NAME}
PIP=${VENV}/bin/pip


clean:
	rm -rf ${VENV} ${VENV}-tools celerybeat-schedule celerybeat.pid ${ORG}-${NAME}_*.deb


venv:
	virtualenv --python python3 ${VENV}
	${PIP} install -r requirements.txt


test: venv
	${VENV}/bin/honcho --procfile Procfile.test --env .env.test start


run: venv
	${VENV}/bin/honcho start


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
