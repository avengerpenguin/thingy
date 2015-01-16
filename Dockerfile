FROM debian

ENV DEBIAN_FRONTEND noninteractive
ENV http_proxy http://www-cache.reith.bbc.co.uk:80
ENV https_proxy http://www-cache.reith.bbc.co.uk:80

ADD . /opt/thingy
WORKDIR /opt/thingy

RUN apt-get update && apt-get install -y python-pip git mongodb-server gcc python-dev && apt-get clean
RUN service mongodb start
RUN pip install -r requirements.txt
RUN honcho --procfile Procfile.test --env .env.test start
