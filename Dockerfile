FROM ubuntu:16.04

ENV DEBIAN_FRONTEND noninteractive
ENV TERM xterm-256color

ENV RIEMANN_SERVER 0.2.11

WORKDIR /opt

# requirements
RUN apt-get update -qq && \
apt-get install -y --no-install-recommends wget bzip2 vim git ca-certificates \
python python-dev python-pip python-django-tagging python-twisted-core \
python-cairo-dev python-setuptools gcc libffi-dev libtool libyaml-dev lsof

# dumb-init
RUN wget --no-check-certificate https://github.com/Yelp/dumb-init/releases/download/v1.0.1/dumb-init_1.0.1_amd64.deb
RUN dpkg -i dumb-init_1.0.1_amd64.deb && rm dumb-init_1.0.1_amd64.deb

# Java 8
RUN echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" | tee /etc/apt/sources.list.d/webupd8team-java.list
RUN echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886
RUN apt-get update
RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
apt-get install -y oracle-java8-installer
RUN rm -rf /var/cache/oracle-jdk8-installer

# Riemann
RUN wget --no-check-certificate https://aphyr.com/riemann/riemann-${RIEMANN_SERVER}.tar.bz2
RUN tar jxvf riemann-${RIEMANN_SERVER}.tar.bz2
RUN rm riemann-${RIEMANN_SERVER}.tar.bz2
RUN ln -s riemann-${RIEMANN_SERVER} riemann

# Graphite-Carbon
RUN apt update && apt-get install -y graphite-carbon
RUN wget https://raw.githubusercontent.com/jamtur01/aom-code/master/4/graphite/carbon-cache-ubuntu.init
RUN cp carbon-cache-ubuntu.init /etc/init.d/carbon-cache
RUN chmod 0755 /etc/init.d/carbon-cache
RUN update-rc.d carbon-cache defaults

RUN wget https://raw.githubusercontent.com/jamtur01/aom-code/master/4/graphite/carbon-relay-ubuntu.init
RUN cp carbon-relay-ubuntu.init /etc/init.d/carbon-relay
RUN chmod 0755 /etc/init.d/carbon-relay
RUN update-rc.d carbon-relay defaults

# Graphite
RUN pip install -U six pyparsing websocket urllib3
RUN pip install graphite-api gunicorn
RUN useradd graphite
RUN update-rc.d carbon-relay defaults

# init
ADD init.d/graphite-api /etc/init.d/graphite-api
RUN chmod 0755 /etc/init.d/graphite-api
WORKDIR /opt
ADD init/init.sh /usr/bin/init.sh
RUN chmod u+x /usr/bin/init.sh

RUN rm -rf /var/lib/apt/lists/* && apt-get clean

ADD graphite-carbon /etc/default/graphite-carbon
ADD opt/graphite/conf /opt/graphite/conf
ADD etc/carbon/relay-rules.conf /etc/carbon/relay-rules.conf

CMD [ "init.sh" ]
