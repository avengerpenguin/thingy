FROM debian

RUN apt-get update && apt-get dist-upgrade -y && apt-get install -y apt-transport-https gdebi-core build-essential debhelper python-dev && apt-get clean
RUN echo 'deb https://ross-deb-repo.s3.amazonaws.com/ stable main' >>/etc/apt/sources.list
RUN apt-get update && apt-get install -y --force-yes dh-virtualenv && apt-get clean

ADD . /app
WORKDIR /app

RUN dpkg-buildpackage -us -uc
RUN gdebi -n ../thingy_0.0.0_amd64.deb

EXPOSE 8000
ENV MONGO_URI mongodb://localhost:27017/thingy
CMD service mongodb start && /usr/share/python/thingy/bin/gunicorn thingy:app --log-file=- --bind=0.0.0.0:8000
