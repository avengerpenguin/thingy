#!/usr/bin/env python

from distutils.core import setup
from pip.req import parse_requirements


setup(name='thingy',
      version = '0.0.0',
      author = 'Ross Fenning',
      author_email = 'ross.fenning@gmail.com',
      url = 'http://gitub.com/avengerpenguin/thingy',
      description = 'REST API for things.',
      license = 'GPLv3+',
      classifiers = [
        'License :: OSI Approved :: GNU General Public License v3 or later (GPLv3+)',
        'Operating System :: OS Independent',
        'Programming Language :: Python',
        ],
      install_requires=[
        'Flask',
        'Flask-PyMongo',
        'gunicorn',
        'honcho',
        'pymongo',
        'rdflib',
        'flask-rdf'
        ],
      )
