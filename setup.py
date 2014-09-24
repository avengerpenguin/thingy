#!/usr/bin/env python

from distutils.core import setup
from pip.req import parse_requirements


install_reqs = [str(r.req) for r in parse_requirements('requirements.txt')]
test_reqs = [str(r.req) for r in parse_requirements('test-requirements.txt')]

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
      install_requires=install_reqs,
      tests_require=test_reqs,
	)
