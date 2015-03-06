web: gunicorn thingy:app --log-file=-
worker: celery -A thingy.celery worker
schedule: celery -A thingy.celery beat
root@8337beb0b3f1:/app# export AWS_ACCESS_KEY_ID=AKIAJCGKCKNHMGWYOZZQ
root@8337beb0b3f1:/app# export AWS_SECRET_ACCESS_KEY='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'