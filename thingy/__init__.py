from flask import Flask, render_template, request
from flask.ext.pymongo import PyMongo
import hyperspace
from rdflib import Graph, URIRef, Namespace
from flask_rdf import flask_rdf
from FuXi.Rete.RuleStore import SetupRuleStore
from FuXi.Rete.Util import generateTokenSet
from FuXi.Horn.HornRules import HornFromN3
import datetime
from celery import Celery
import logging
import os
from httplib2 import iri2uri
import requests


app = Flask(__name__)
app.config['MONGO_URI'] = os.getenv('MONGO_URI')
app.config['DEBUG'] = True
mongo = PyMongo(app)


celery = Celery()
celery.conf.update(
    CELERY_ENABLE_UTC=True,
    CELERY_TIMEZONE='Europe/London',
)
celery.conf.CELERYBEAT_SCHEDULE = {
    'update_thing_store': {
        'task': 'thingy.update_all',
        'schedule': datetime.timedelta(hours=1),
    },
}

celery.conf.BROKER_URL = os.getenv('MONGO_URI')

rule_store, rule_graph, network = SetupRuleStore(makeNetwork=True)
rules = HornFromN3(os.path.join(
    os.path.dirname(os.path.realpath(__file__)), 'rules.n3'))


@app.route('/')
def home():
    return render_template('index.html')


@app.route('/lookup')
@flask_rdf
def find_uri():

    iri = request.args['iri']

    entry = mongo.db.things.find_one({'_id': iri})

    if entry:
        graph = Graph()
        graph.parse(data=entry['graph'].encode('utf-8'), format='turtle')
    else:
        graph = update_thing(iri)

    return graph


def infer_schema(graph, rules, network):
    closure_delta = Graph()
    network.inferredFacts = closure_delta
    for rule in rules:
        network.buildNetworkFromClause(rule)

    network.feedFactsToAdd(generateTokenSet(graph))
    closure_delta.bind('schema', Namespace('http://schema.org/'))
    return graph + closure_delta


def add_labels_for_linked_things(iri, graph):
    thing = URIRef(iri)

    predicates = [URIRef('http://dbpedia.org/ontology/starring')]
    subjects = sum([list(graph.subjects(object=thing, predicate=predicate))
                    for predicate in predicates], [])
    objects = sum([list(graph.objects(subject=thing, predicate=predicate))
                   for predicate in predicates], [])

    linked_things = [linked_thing
                     for linked_thing in set(subjects + objects)
                        if isinstance(linked_thing, URIRef)]

    for linked_thing in linked_things:
        try:
            uri = str(linked_thing)
            if not uri == iri2uri(iri):
                graph.parse(uri)
        except:
            # We can gracefully degrade by simply not adding data from bad URIs
            continue

    return graph


def filter_for_schema_org_properties(graph):
    for s, p, o in graph:
        if not p.startswith('http://schema.org/'):
            graph.remove((s, p, o))
    return graph


def update_thing(iri):
    logging.info('Adding/updating: %s', iri)

    graph = Graph()
    graph.parse(iri2uri(iri))

    graph = add_labels_for_linked_things(iri, graph)
    graph = infer_schema(graph, rules, network)
    graph = filter_for_schema_org_properties(graph)

    rdf_string = graph.serialize(format='turtle').decode('utf-8')
    mongo.db.things.insert({
        '_id': iri, 'graph': rdf_string, 'updated': datetime.datetime.utcnow()
    })

    return graph


@celery.task
def update_all():
    logging.info('Checking for old things to update...')
    stale_date = datetime.datetime.utcnow() - datetime.timedelta(hours=1)
    for entry in mongo.db.things.find({'updated': {'$lt': stale_date}}):
        logging.info('Found stale: %s', entry['_id'])
        update_thing(entry['_id'])


if __name__ == "__main__":
    app.run(debug=True)
