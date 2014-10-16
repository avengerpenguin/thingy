import hyperspace
from rdflib import URIRef, Literal, Namespace
import pytest

SCHEMA = Namespace(URIRef('http://schema.org/'))
KEVIN_BACON = URIRef('http://dbpedia.org/resource/Kevin_Bacon')


def english(string):
    return Literal(string, lang='en')


@pytest.fixture
def home_url():
    return 'http://localhost:5000'


@pytest.fixture
def thingy_home(home_url):
    hyperspace.session.headers['Accept'] = 'text/turtle'
    return hyperspace.jump(home_url)


@pytest.fixture
def kevin_bacon(thingy_home):
    return thingy_home.queries['lookup'][0].build(
        {'iri': 'http://dbpedia.org/resource/Kevin_Bacon'}).submit().data


def test_name(kevin_bacon):
    assert (KEVIN_BACON, SCHEMA.name, english('Kevin Bacon')) in kevin_bacon


def test_description(kevin_bacon):
    descriptions = kevin_bacon.objects(KEVIN_BACON, SCHEMA.description)

    english_description = [
        description for description in descriptions
        if description.language == 'en'
    ][0].toPython()

    assert 'Kevin Norwood Bacon' in english_description


