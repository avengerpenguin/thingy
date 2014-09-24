ORG=ross
NAME=thingy
VENV=venv
INSTALLDIR=/opt/${ORG}/${NAME}
PIP=${VENV}/bin/pip

clean:
	rm -rf venv

run: venv
	${VENV}/bin/honcho start

venv:
	virtualenv ${VENV}
	${PIP} install 'git+git://github.com/RDFLib/FuXi.git#egg=FuXi'
	${PIP} install -r requirements.txt

deb: venv
	${PIP} install virtualenv-tools

	find ${VENV} -iname '*.pyc' -delete
	find ${VENV} -iname '*.pyo' -delete

	${VENV}/bin/virtualenv-tools --update-path=/opt/${ORG}/${NAME}/${VENV} ${VENV}

	gem install fpm --user-install
	${HOME}/.gem/ruby/1.8/bin/fpm -s dir -t deb -n ${ORG}-${NAME} thingy=${INSTALLDIR} ${VENV}=${INSTALLDIR} Procfile=${INSTALLDIR}

	rm -rf venv
