import hyperspace
from rdflib import URIRef, Literal
import pytest


@pytest.fixture
def home_url():
    return 'http://localhost:5000'


@pytest.fixture
def thingy_home(home_url):
    hyperspace.session.headers['Accept'] = 'text/turtle'
    return hyperspace.jump(home_url)


def test_name(thingy_home):
    graph = thingy_home.queries['lookup'][0].build(
        {'iri': 'http://dbpedia.org/resource/Kevin_Bacon'}).submit().data

    assert (
        URIRef('http://dbpedia.org/resource/Kevin_Bacon'),
        URIRef('http://schema.org/name'),
        Literal('Kevin Bacon', lang='en')
    ) in graph
