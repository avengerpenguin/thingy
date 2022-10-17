.PHONY: clean deb default deploy

################
# Build Info   #
################

NAME := thingy
VERSION := $(shell python setup.py --version)

PYSRC := $(shell find thingy)
TARGET := $(PWD)/target

PYTHON_VERSION = 2

###############
# Boilerplate #
###############

default: test

clean:
	rm -rf $(TARGET)

$(TARGET):
	mkdir -p $(TARGET)


################
# Code Quality #
################

$(TARGET)/pep8.errors: $(TARGET) $(PYSRC)
	pep8 --exclude="venv" . | tee $(TARGET)/pep8.errors || true


####################
# Building the deb #
####################

debNAME := $(NAME)_$(VERSION)_amd64.deb

$(TARGET)/$(DEBNAME): $(TARGET) setup.py $(PYSRC)
# Check if we're running Debian...
ifeq ($(wildcard /etc/debian_version),)
	docker stop $(NAME) || true
	docker rm $(NAME) || true
	docker build -t $(NAME) .
	chmod 777 $(TARGET)
	docker run -v $(TARGET):/target -w /target $(NAME) cp -r /app/target/$(DEBNAME) /target
else
	rm -rf $(TARGET)/venv
	virtualenv -p python$(PYTHON_VERSION) $(TARGET)/venv
	$(TARGET)/venv/bin/pip install -r requirements.txt
	$(TARGET)/venv/bin/python setup.py install
	virtualenv --relocatable $(TARGET)/venv
	fpm -s dir -t deb -n $(NAME) --force \
		--package $(TARGET)/$(DEBNAME) --version $(VERSION) --iteration $(RELEASE_VER) \
		$(TARGET)/venv/{bin,lib,src,include}=/opt/$(NAME)
endif

deb: $(TARGET)/$(DEBNAME)


##############
# Deployment #
##############

deploy: $(TARGET)/$(DEBNAME)
	deb-s3 --bucket=ross-deb-repo --codename=jessie upload $(TARGET)/$(DEBNAME)
