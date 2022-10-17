FROM debian:jessie

# Install from main repos all tools needed in this build file
RUN apt-get update && apt-get dist-upgrade -y && apt-get install -y gdebi-core lintian virtualenv git python-setuptools && apt-get clean

# Add custom repo
#RUN echo 'deb https://ross-deb-repo.s3.amazonaws.com/ stable main' >>/etc/apt/sources.list
#RUN gpg ; gpg --recv-keys 40A3BE105F6243A4
#RUN gpg --fingerprint 40A3BE105F6243A4 | grep 'EB09 42E4 3515 8BC2 06B2  4B07 4040 A484 B63B A1CE'
#RUN gpg --export 40A3BE105F6243A4 | apt-key add -

# Install tools only available in custom repo
#RUN apt-get update && apt-get install -y dh-virtualenv && apt-get clean

# Copy across our project
ADD . /app
WORKDIR /app

RUN make deb
RUN dpkg --info target/thingy_0.0.0_amd64.deb
RUN dpkg --contents target/thingy_0.0.0_amd64.deb
RUN lintian target/thingy_0.0.0_amd64.deb || true
RUN gdebi -n target/thingy_0.0.0_amd64.deb

EXPOSE 8000
ENV MONGO_URI mongodb://localhost:27017/thingy
CMD service mongodb start && /opt/thingy/bin/gunicorn thingy:app --log-file=- --bind=0.0.0.0:8000
