# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# Referneces:
# https://github.com/mitre/caldera

FROM cyb3rward0g/docker-caldera:0.0.1
LABEL maintainer="Roberto Rodriguez @Cyb3rWard0g"
LABEL description="Dockerfile Mordor Caldera.."

USER ${USER}

RUN cd $CALDERA_HOME/plugins \
  && git clone https://github.com/d4weiss/evals_caldera.git \
  && mv $CALDERA_HOME/conf/local.yml $CALDERA_HOME/conf/local.yml.bk
  # && git clone https://github.com/mitre-attack/evals_caldera.git \

COPY config/local.yml $CALDERA_HOME/conf/local.yml

USER root

RUN chown -R ${USER} $CALDERA_HOME ${HOME}

WORKDIR $CALDERA_HOME
ENTRYPOINT ["./caldera-entrypoint.sh"]
CMD ["python3", "server.py"]

USER ${USER}