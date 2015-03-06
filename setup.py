#!/usr/bin/env python

import os
from setuptools import setup


def read(readme_file):
    return open(os.path.join(os.path.dirname(__file__), readme_file)).read()



setup(name='thingy',
      version = '0.0.0',
      author = 'Ross Fenning',
      author_email = 'ross.fenning@gmail.com',
      packages=['thingy'],
      package_data={
          'thingy': ['thingy/rules.n3', 'thingy/templates/*']
      },
      url = 'https://github.com/avengerpenguin/thingy',
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
          'pymongo',
          'rdflib',
          'flask-rdf',
          'celery',
          'httplib2',
      ],
)
