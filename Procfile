web: ./venv/bin/gunicorn thingy:app --log-file=-
worker: ./venv/bin/celery -A thingy.celery beat
