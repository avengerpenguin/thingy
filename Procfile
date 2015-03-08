web: gunicorn thingy:app --log-file=-
worker: celery -A thingy.celery worker
schedule: celery -A thingy.celery beat
