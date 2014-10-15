import hyperspace
from rdflib import URIRef, Literal, Namespace
import pytest

SCHEMA = Namespace(URIRef('http://schema.org/'))
KEVIN_BACON = URIRef('http://dbpedia.org/resource/Kevin_Bacon')


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
        KEVIN_BACON,
        SCHEMA.name,
        Literal('Kevin Bacon', lang='en')
    ) in graph
