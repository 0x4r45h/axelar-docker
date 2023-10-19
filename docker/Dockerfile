FROM golang:1.21.2-bullseye as builder

RUN apt-get update && apt-get install -y jq bash git sed unzip wget curl coreutils lz4 build-essential
RUN go install github.com/cosmos/cosmos-sdk/cosmovisor/cmd/cosmovisor@v1.0.0

#ARG CONFIG_REPO_URL=https://github.com/lavanet/lava-config.git
#ARG CONFIG_REPO_PATH=lava-config/testnet-2
#ARG LAVAD_GENESIS_BIN=https://github.com/lavanet/lava/releases/download/v0.21.1.2/lavad-v0.21.1.2-linux-amd64
ARG REPO_URL=https://github.com/axelarnetwork/axelar-core.git
ARG REPO_TAG=v0.34.0

WORKDIR "/tmp"
#RUN git clone $CONFIG_REPO_URL
RUN git clone --branch  $REPO_TAG $REPO_URL
#RUN mkdir -p "/tmp/conf_repo" && mv $CONFIG_REPO_PATH/* /tmp/conf_repo

#RUN wget -O /tmp/lavad  $LAVAD_GENESIS_BIN
WORKDIR "/tmp/axelar-core"
# make all instead of BINs
RUN make build
# Remove the lavad binary to always use latest binary in path cosmovisor/current/bin
#RUN rm /go/bin/lavad

#final image
FROM golang:1.21.2-bullseye
RUN apt-get update && apt-get install -y \
    jq bash nano git logrotate sed unzip wget curl coreutils inotify-tools supervisor lz4 build-essential \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p "/root/.axelar/config" && mkdir -p "/root/.axelar/cosmovisor/genesis/bin/"
COPY --from=builder /go/bin/* /go/bin/
COPY --from=builder /tmp/axelar-core/bin/axelard /root/.axelar/cosmovisor/genesis/bin/
#COPY --from=builder /tmp/conf_repo/default_lavad_config_files/* /root/.axelar/config/
#COPY --from=builder /tmp/conf_repo/genesis_json/genesis.json /root/.axelar/config/genesis.json
COPY entrypoint.sh /opt/entrypoint.sh
#COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
#COPY watcher.sh /root/watcher.sh
RUN ln -s /root/.axelar/cosmovisor/genesis /root/.axelar/cosmovisor/current -f && \
    ln -s /root/.axelar/cosmovisor/current/bin/axelard /usr/local/bin/axelard -f
RUN chmod +x /opt/entrypoint.sh /root/.axelar/cosmovisor/genesis/bin/axelard
ENV PATH="/root/.axelar/cosmovisor/current/bin:$PATH"
WORKDIR "/root"
RUN wget -O root/.axelar/config/genesis.json https://snapshots.kjnodes.com/axelar/genesis.json
RUN wget -O root/.axelar/config/addrbook.json https://snapshots.kjnodes.com/axelar/addrbook.json

ENTRYPOINT ["/opt/entrypoint.sh"]
CMD ["cosmovisor --help"]