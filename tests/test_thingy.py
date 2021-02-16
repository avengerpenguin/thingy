import os

import hyperspace
import laconia
import pymongo
import pytest
import requests
from rdflib import Namespace, URIRef

SCHEMA = Namespace(URIRef("http://schema.org/"))
KEVIN_BACON = URIRef("http://dbpedia.org/resource/Kevin_Bacon")


def url2entity(url):
    client = requests.Session()
    client.headers["Accept"] = "text/turtle"
    thingy_home = hyperspace.jump("http://localhost:5100", client=client)
    graph = thingy_home.queries["lookup"][0].build({"iri": url}).submit().data
    factory = laconia.ThingFactory(graph)
    return factory(url)


@pytest.fixture
def kevin_bacon():
    return url2entity("http://dbpedia.org/resource/Kevin_Bacon")


@pytest.fixture
def apollo13():
    return url2entity("http://dbpedia.org/resource/Apollo_13_(film)")


@pytest.fixture
def question_time():
    return url2entity("http://www.bbc.co.uk/programmes/b006t1q9")


@pytest.fixture(autouse=True)
def clear_mongo():
    client = pymongo.MongoClient(os.getenv("MONGO_URI"))
    db = client.thingy
    db.things.remove()
    assert db.things.count() == 0


def test_name(kevin_bacon):
    assert "Kevin Bacon" in set(kevin_bacon.schema_name)


def test_description(kevin_bacon):
    kevin_bacon.lang = "en"
    assert "Kevin Norwood Bacon" in list(kevin_bacon.schema_description)[0]


def test_thumbnail(kevin_bacon):
    expected_url = (
        "http://commons.wikimedia.org/wiki/Special:FilePath/Kevin_"
        "Bacon_Comic-Con_2012.jpg?width=300"
    )
    first_thumbnail_found = str(list(kevin_bacon.schema_thumbnailUrl)[0])
    assert expected_url == first_thumbnail_found


def test_image(kevin_bacon):
    expected_url = (
        "http://commons.wikimedia.org/wiki/Special:FilePath/Kevin_"
        "Bacon_Comic-Con_2012.jpg"
    )
    first_image_found = str(list(kevin_bacon.schema_image)[0])
    assert expected_url == first_image_found


def test_starring(kevin_bacon, apollo13):
    assert apollo13 in kevin_bacon.schema_actor_of
    assert kevin_bacon in apollo13.schema_actor


# def test_name_of_linked_item_accessible(kevin_bacon):
#    assert 'Apollo 13 (Film)' in sum([list(film.schema_name) for film in kevin_bacon.schema_actor_of], [])


def test_schema_org_properties_passed_through(question_time):
    print(
        question_time._id,
        question_time._store.serialize(format="turtle").decode("utf-8"),
    )
    assert "Question Time" in set(question_time.schema_name)
