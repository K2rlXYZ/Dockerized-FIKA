##
## Dockerfile
## FIKA LINUX Container
##

FROM ubuntu:latest AS builder
ARG FIKA=HEAD^
ARG FIKA_BRANCH=main
ARG SPT=HEAD^
ARG SPT_BRANCH=master
ARG NODE=20.11.1

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
WORKDIR /opt

# Install git git-lfs curl
RUN apt update && apt install -yq git git-lfs curl
# Install Node Version Manager and NodeJS
RUN git clone https://github.com/nvm-sh/nvm.git $HOME/.nvm || true
RUN \. $HOME/.nvm/nvm.sh && nvm install $NODE
## Clone the SPT AKI repo or continue if it exist
RUN git clone --branch $SPT_BRANCH https://dev.sp-tarkov.com/SPT-AKI/Server.git srv || true

## Check out and git-lfs (specific commit --build-arg SPT=xxxx)
WORKDIR /opt/srv/project 
RUN git checkout $SPT
RUN git-lfs pull

## remove the encoding from aki - todo: find a better workaround
RUN sed -i '/setEncoding/d' /opt/srv/project/src/Program.ts || true

## Install npm dependencies and run build
RUN \. $HOME/.nvm/nvm.sh && npm install && npm run build:release -- --arch=$([ "$(uname -m)" = "aarch64" ] && echo arm64 || echo x64) --platform=linux
## Move the built server and clean up the source
RUN mv build/ /opt/server/
WORKDIR /opt
RUN rm -rf srv/
## Grab FIKA Server Mod or continue if it exist
RUN git clone --branch $FIKA_BRANCH https://github.com/project-fika/Fika-Server.git ./server/user/mods/fika-server
RUN \. $HOME/.nvm/nvm.sh && cd ./server/user/mods/fika-server && git checkout $FIKA && npm install
RUN rm -rf ./server/user/mods/FIKA/.git

FROM ubuntu:latest
WORKDIR /opt/
RUN apt update && apt upgrade -yq && apt install -yq dos2unix
COPY --from=builder /opt/server /opt/srv
COPY fcpy.sh /opt/fcpy.sh
# Fix for Windows
RUN dos2unix /opt/fcpy.sh

# Set permissions
RUN chmod o+rwx /opt -R

# Exposing ports
EXPOSE 6969

# Specify the default command to run when the container starts
CMD bash ./fcpy.sh