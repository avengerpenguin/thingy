db: mongod --port 5001 --dbpath ./data
web: gunicorn thingy:app --log-file=-
worker: celery -A thingy.celery beat
