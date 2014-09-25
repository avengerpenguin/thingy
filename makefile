ORG=ross
NAME=thingy
VENV=venv
INSTALLDIR=/opt/${ORG}/${NAME}
PIP=${VENV}/bin/pip

BINTRAY_API := https://api.bintray.com
BINTRAY_CURL := curl -u${BINTRAY_USER}:${BINTRAY_KEY} -H Content-Type:application/json -H Accept:application/json
BINTRAY_PACKAGE_DATA := "{\"name\":\"$(ORG)-$(NAME)\",\"licenses\":[\"GPL-3.0\"]}"
BINTRAY_REPO := ${BINTRAY_USER}

clean:
	rm -rf ${VENV} celerybeat-schedule celerybeat.pid ${ORG}-${NAME}_*.deb

venv:
	virtualenv ${VENV}
	${PIP} install 'git+git://github.com/avengerpenguin/FuXi.git#egg=FuXi'
	${PIP} install -r requirements.txt


run: venv
	${VENV}/bin/honcho start

deb: venv
	${PIP} install virtualenv-tools

	find ${VENV} -iname '*.pyc' -delete
	find ${VENV} -iname '*.pyo' -delete

	${VENV}/bin/virtualenv-tools --update-path=/opt/${ORG}/${NAME}/${VENV} ${VENV}

	gem install fpm --user-install
	${HOME}/.gem/ruby/1.8/bin/fpm -s dir -t deb -n ${ORG}-${NAME}  --deb-user ${NAME} --deb-group ${NAME} thingy=${INSTALLDIR} ${VENV}=${INSTALLDIR} Procfile=${INSTALLDIR}

	rm -rf venv


ARTEFACT_FILE := $(ORG)-$(NAME)_*.deb

deploy: deb
	VERSION=$(shell $(dpkg-deb -f ${ORG}-${NAME}_*.deb Version))
	@echo "Checking if package exists on Bintray..." \
	&& echo test $(shell $(BINTRAY_CURL) --write-out %{http_code} --silent --output /dev/null \
		-X GET $(BINTRAY_API)/packages/$(BINTRAY_USER)/$(BINTRAY_REPO)/$(ORG)-$(NAME)) == 200 \
	|| echo "Package does not exist; creating..." \
		&& $(BINTRAY_CURL) -X POST -d $(BINTRAY_PACKAGE_DATA) \
			$(BINTRAY_API)/packages/$(BINTRAY_USER)/$(BINTRAY_REPO) && echo

	@echo "Uploading artefact to Bintray..." \
		&& ${BINTRAY_CURL} -T $(ARTEFACT_FILE) -H X-Bintray-Package:${ORG}-${NAME} -H X-Bintray-Version:${VERSION} \
			${BINTRAY_API}/content/${BINTRAY_USER}/${BINTRAY_REPO}/${ARTEFACT_FILE}\;publish=1 \
	&& echo
