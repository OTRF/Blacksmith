# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

FROM ubuntu:19.10
LABEL maintainer="Roberto Rodriguez @Cyb3rWard0g"
LABEL description="Dockerfile ATTACK website Image.."

ENV DEBIAN_FRONTEND noninteractive
ENV ATTACK_UID 710
ENV ATTACK_GID 100
ENV ATTACK_USER attackuser
ENV HOME /home/${ATTACK_USER}
ENV PATH "$HOME/.local/bin:$PATH"

# *********** Installing Prerequisites ***************
# -qq : No output except for errors
RUN apt-get update --fix-missing \
  && apt-get install -qqy --no-install-recommends \
  locales nano sudo git pelican apt-transport-https ca-certificates python3-pip python3-setuptools \
  && apt-get -qy clean autoremove \
  && rm -rf /var/lib/apt/lists/* \
  # ********** Set Locale **********************
  &&  echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
  && locale-gen \
  # *********** Create ATTACK user **************
  && echo "auth requisite pam_deny.so" >> /etc/pam.d/su \
  && sed -i.bak -e 's/^%admin/#%admin/' /etc/sudoers \
  && sed -i.bak -e 's/^%sudo/#%sudo/' /etc/sudoers \
  && useradd -m -s /bin/bash -N -u ${ATTACK_UID} ${ATTACK_USER} \
  && git clone https://github.com/mitre-attack/attack-website ${HOME}/ATTACK \
  && chown -R ${ATTACK_USER}:${ATTACK_GID} ${HOME}/ATTACK

USER ${ATTACK_USER}

ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8

RUN  python3 -m pip install wheel \
  && cd ${HOME}/ATTACK \
  && python3 -m pip install -r requirements.txt

COPY scripts/* ${HOME}/ATTACK/

WORKDIR ${HOME}/ATTACK
ENTRYPOINT ./attack-entrypoint.sh
CMD /bin/bash