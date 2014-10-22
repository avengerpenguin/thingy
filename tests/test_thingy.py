import os
import hyperspace
from rdflib import URIRef, Literal, Namespace
import pytest
import laconia
import pymongo


SCHEMA = Namespace(URIRef('http://schema.org/'))
KEVIN_BACON = URIRef('http://dbpedia.org/resource/Kevin_Bacon')


@pytest.fixture
def home_url():
    return 'http://localhost:5100'


@pytest.fixture
def thingy_home(home_url):
    hyperspace.session.headers['Accept'] = 'text/turtle'
    return hyperspace.jump(home_url)


@pytest.fixture
def kevin_bacon_graph(thingy_home):
    return thingy_home.queries['lookup'][0].build(
        {'iri': 'http://dbpedia.org/resource/Kevin_Bacon'}).submit().data


@pytest.fixture
def kevin_bacon(kevin_bacon_graph):
    factory = laconia.ThingFactory(kevin_bacon_graph)
    return factory('http://dbpedia.org/resource/Kevin_Bacon')


@pytest.fixture(autouse=True)
def clear_mongo():
    client = pymongo.MongoClient(os.getenv('MONGO_URI'))
    db = client.thingy
    db.things.remove()
    assert db.things.count() == 0


def test_name(kevin_bacon):
    assert 'Kevin Bacon' in set(kevin_bacon.schema_name)


def test_description(kevin_bacon):
    kevin_bacon.lang = 'en'
    assert 'Kevin Norwood Bacon' in list(kevin_bacon.schema_description)[0]


def test_thumbnail(kevin_bacon):
    expected_url = 'http://commons.wikimedia.org/wiki/Special:FilePath/Kevin_' \
                   'Bacon_Comic-Con_2012.jpg?width=300'
    first_thumbnail_found = str(list(kevin_bacon.schema_thumbnailUrl)[0])
    assert expected_url == first_thumbnail_found


def test_image(kevin_bacon):
    expected_url = 'http://commons.wikimedia.org/wiki/Special:FilePath/Kevin_' \
                   'Bacon_Comic-Con_2012.jpg'
    first_image_found = str(list(kevin_bacon.schema_image)[0])
    assert expected_url == first_image_found


def test_starring(kevin_bacon_graph, kevin_bacon):
    factory = laconia.ThingFactory(kevin_bacon_graph)
    apollo13 = factory('http://dbpedia.org/resource/Apollo_13_(film)')
    assert apollo13 in kevin_bacon.schema_actor_of
