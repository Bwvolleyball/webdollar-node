FROM ubuntu:20.04

ENV TERM xterm
ENV TZ UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN mkdir -p /usr/local/.nvm
WORKDIR /usr/local
ENV HOME /usr/local

ENV NVM_DIR /usr/local/.nvm
ENV NODE_VERSION 8.2.1

RUN apt-get update && apt-get install -y git curl wget build-essential software-properties-common clang cmake libtool autoconf psmisc opencl-headers ocl-icd-libopencl1 pciutils python2 jq

# Install nvm with node and npm
RUN curl https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH      $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH
ENV NODE_TLS_REJECT_UNAUTHORIZED 0

# Build the custom argon2 package

ARG ARGON=1

RUN git clone https://github.com/WebDollar/argon2
WORKDIR /usr/local/argon2
RUN autoreconf -i
RUN bash configure
RUN cmake -DCMAKE_BUILD_TYPE=Release .
RUN make

WORKDIR /usr/local

ARG WEBDOLLAR=1

RUN git clone https://github.com/WebDollar/Node-WebDollar.git miner
# A backup location of the repo in case I need to test new code not in the project.
#RUN git clone https://github.com/bwvolleyball/Node-WebDollar.git miner

WORKDIR /usr/local/miner
RUN cp -a ../argon2/* dist_bundle/CPU/

ENV PYTHON /usr/bin/python2

RUN . $NVM_DIR/nvm.sh \
    && (printf "n" && cat) | bash install-miner.sh && npm install


RUN npm run build_terminal_menu && npm run build_terminal_worker

ARG DEVELOPMENT=1

ENV SOLO_MINING=false

ADD master_mining_setup.sh .
ADD start_pool_mining.sh .
ADD start_mining.sh .

CMD [ "./master_mining_setup.sh" ]
