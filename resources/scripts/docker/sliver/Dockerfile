# References:
# https://github.com/BishopFox/sliver/blob/master/Dockerfile
# https://docs.docker.com/build/building/multi-stage/
# https://stackoverflow.com/a/69948610

# Author: Roberto Rodriguez (@Cyb3rWard0g)
FROM alpine/git:latest
WORKDIR /clone-workspace
RUN git config --global http.postBuffer 524288000 \
    && git clone https://github.com/BishopFox/sliver

FROM golang:1.22.5 as build
WORKDIR /go/src/github.com/bishopfox/sliver
COPY --from=0 /clone-workspace/sliver /go/src/github.com/bishopfox/sliver
RUN apt-get update --fix-missing && apt-get -y install \
    git build-essential zlib1g zlib1g-dev \
    libxml2 libxml2-dev libxslt-dev locate curl \
    libreadline6-dev libcurl4-openssl-dev git-core \
    libssl-dev libyaml-dev openssl autoconf libtool \
    ncurses-dev bison curl wget xsel postgresql \
    postgresql-contrib postgresql-client libpq-dev \
    libapr1 libaprutil1 libsvn1 \
    libpcap-dev libsqlite3-dev libgmp3-dev \
    zip unzip mingw-w64 binutils-mingw-w64 g++-mingw-w64 \
    nasm
RUN make clean-all
RUN make

FROM golang:1.22.5
COPY --from=build /go/src/github.com/bishopfox/sliver/sliver-server /opt/sliver-server
    # Add Sliver user
RUN groupadd -g 999 sliver && useradd -r -u 999 -g sliver sliver \
    && mkdir -p /home/sliver/ && chown -R sliver:sliver /home/sliver \
    # Install packages
    && apt-get update --fix-missing && apt-get -y install tmux curl wget \
    && /opt/sliver-server unpack --force \
    # Install Metasploit
    && curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall \
    && chmod 755 msfinstall \
    && ./msfinstall
RUN mkdir -p ~/.msf4/ && touch ~/.msf4/initial_setup_complete \
    && su -l sliver -c 'mkdir -p ~/.msf4/ && touch ~/.msf4/initial_setup_complete'

USER sliver
WORKDIR /home/sliver/

CMD ["/opt/sliver-server"]