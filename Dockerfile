# A Docker container capable of running all GRR components.
# Xenial has the correct version of the protobuf compiler (2.6.1).
FROM ubuntu:xenial
MAINTAINER Greg Castle github@mailgreg.com

RUN apt-get update && \
  apt-get install -y \
  debhelper \
  dpkg-dev \
  libssl-dev \
  protobuf-compiler \
  python-dev \
  python-pip \
  rpm \
  wget \
  zip && \
  pip install --upgrade pip && \
  pip install virtualenv && \
  pip install setuptools --upgrade && \
  virtualenv /usr/share/grr-server

# Pull dependencies and templates from pypi and build wheels so docker can cache
# them. This just makes the actual install go faster.
RUN . /usr/share/grr-server/bin/activate && \
mkdir /wheelhouse && \
pip wheel --wheel-dir=/wheelhouse --pre grr-response-server && \
pip wheel --wheel-dir=/wheelhouse -f https://storage.googleapis.com/releases.grr-response.com/index.html grr-response-templates

# Copy the GRR code over.
ADD . /usr/src/grr/

# Now install the current version over the top.
RUN . /usr/share/grr-server/bin/activate && \
pip install --find-links=/wheelhouse /usr/src/grr/ && \
pip install --find-links=/wheelhouse /usr/src/grr/grr/config/grr-response-server

COPY scripts/docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]

# Port for the admin UI GUI
EXPOSE 8000

# Port for clients to talk to
EXPOSE 8080

# Server config, logs, sqlite db
VOLUME ["/etc/grr", "/var/log", "/var/grr-datastore"]

CMD ["grr"]
