# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

FROM nginx:1.17.9
LABEL maintainer="Roberto Rodriguez @Cyb3rWard0g"
LABEL description="Dockerfile base for the HELK Nginx."

ENV DEBIAN_FRONTEND noninteractive

# *********** Installing Prerequisites ***************
# -qq : No output except for errors
RUN echo "Updating Ubuntu base image.." \
  && apt-get update -qq
RUN apt-get install -qqy curl
RUN apt-get -qy clean \
  autoremove

# *********** Adding and files to Container ***************
COPY scripts/nginx-entrypoint.sh /opt/scripts/
RUN chmod +x /opt/scripts/nginx-entrypoint.sh

# *********** RUN HELK ***************
EXPOSE 80 443
WORKDIR "/opt/scripts/"
ENTRYPOINT ["./nginx-entrypoint.sh"]