from flask import Flask, render_template, request
from flask.ext.pymongo import PyMongo
from rdflib import Graph, URIRef, Namespace
from flask_rdf import flask_rdf
from FuXi.Rete.RuleStore import SetupRuleStore
from FuXi.Rete.Util import generateTokenSet
from FuXi.Horn.HornRules import HornFromN3
import datetime
from celery import Celery
import logging
import os


app = Flask(__name__)
app.config['MONGO_PORT'] = 27017
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

celery.conf.BROKER_URL = os.getenv(
    'MONGOLAB_URI', 'mongodb://localhost:27017/thingy')

rule_store, rule_graph, network = SetupRuleStore(makeNetwork=True)
rules = HornFromN3(os.path.join(os.path.dirname(os.path.realpath(__file__)), 'rules.n3'))


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


def infer_schema(graph):
    closure_delta = Graph()
    network.inferredFacts = closure_delta
    for rule in rules:
        network.buildNetworkFromClause(rule)

    network.feedFactsToAdd(generateTokenSet(graph))
    closure_delta.bind('schema', Namespace('http://schema.org/'))
    return closure_delta


def update_thing(iri):
    logging.info('Adding/updating: %s', iri)

    raw_graph = Graph()
    raw_graph.parse(iri)

    graph = infer_schema(raw_graph)

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
    app.run()
