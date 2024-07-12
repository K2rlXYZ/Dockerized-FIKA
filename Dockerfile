# ========================================================================= #
#  > Docker: "Builder" image stage                                          #
#    Used to install system dependencies and perform mandatory config.      #
# ========================================================================= #
FROM debian:bookworm-slim AS builder

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get install -y --no-install-recommends git git-lfs ca-certificates curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ARG NODE_VERSION="20.11.1"

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash \
    && . /root/.nvm/nvm.sh \
    && nvm install "${NODE_VERSION}" \
    && nvm alias default "${NODE_VERSION}"

ARG SPT_BRANCH="3.9.0"

RUN git clone --depth=1 --branch $SPT_BRANCH https://dev.sp-tarkov.com/SPT/Server.git /opt/spt

WORKDIR /opt/spt

RUN git lfs pull
## remove the encoding from SPT - todo: find a better workaround
RUN sed -i '/setEncoding/d' /opt/spt/project/src/Program.ts || true

WORKDIR /opt/spt/project

RUN . /root/.nvm/nvm.sh \
    && npm install \
    && npm run build:release -- --arch=$([ "$(uname -m)" = "aarch64" ] && echo arm64 || echo x64) --platform=linux \
    && mv build/ /opt/server/ \
    && rm -rf /opt/spt

ARG FIKA_SERVER_BRANCH="v2.2.1"

RUN git clone --depth=1 --branch $FIKA_SERVER_BRANCH https://github.com/project-fika/Fika-Server.git /opt/server/user/mods/fika-server

WORKDIR /opt/server/user/mods/fika-server

RUN . /root/.nvm/nvm.sh \
    && npm install \
    && rm -rf .git/

# ========================================================================= #
#  > Docker: "Final" image stage                                            #
#    Used in application deployment.                                        #
# ========================================================================= #
FROM debian:bookworm-slim AS fika

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get install -y --no-install-recommends dos2unix curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/server /opt/fika

ARG TARKOV_UID=421
ARG SPT_BRANCH="3.9.0"
ARG FIKA_SERVER_BRANCH="v2.2.1"

ENV SPT_BRANCH=$SPT_BRANCH
ENV FIKA_SERVER_BRANCH=$FIKA_SERVER_BRANCH

RUN groupadd --system --gid "${TARKOV_UID}" tarkov \
    && useradd --system --uid "${TARKOV_UID}" --gid "${TARKOV_UID}" tarkov

COPY ./entrypoint.sh /opt/entrypoint.sh

RUN chown -R tarkov:tarkov /opt \
    && chmod -R 770 /opt \
    && chmod +x /opt/entrypoint.sh \
    && dos2unix /opt/entrypoint.sh

USER tarkov
WORKDIR /opt/server
ENTRYPOINT ["/opt/entrypoint.sh"]
CMD ["./SPT.Server.exe"]
EXPOSE 6969
