# FIKA (Docker)

A modified version of bullet's [SIT.Docker](https://github.com/stayintarkov/SIT.Docker).

When the server has been initialized, it'll generate an `/opt/server/version` file with the version that was last installed.

### Build Arguments:

| Argument           | Description                         | Default |
|--------------------|-------------------------------------|---------|
| NODE_VERSION       | The version of NodeJS to install.   | 20.11.1 |
| SPT_BRANCH         | The version of SPT to install.      | 3.9.1   |
| FIKA_SERVER_BRANCH | The version of FIKA to install.     | v2.2.1  |
| TARKOV_UID         | The UID of the Tarkov user & group. | 421     |

### Environment Variables:

| Variable      | Description                                                              | Default                                  |
|---------------|--------------------------------------------------------------------------|------------------------------------------|
| START_TIMEOUT | The time to wait for the server to initialize on first run.              | 40s                                      |
| HEADLESS      | Whether to boot the server immediately after first-time setup.           | false                                    |
| FORCE         | Whether to force the server to update (i.e. to re-initialize or update). | false                                    |
| HOST_IP       | The IP address of the host machine.                                      | Fetches value from `ipv4.icanhazip.com`. |

### Building & Running:

With raw Docker:

```shell
docker build --no-cache --label FIKA -t fika .
docker run --pull=never -v [server files]:/opt/server --net=host -it --name fika fika
docker start fika
docker update --restart unless-stopped fika
```

With Docker Compose (the `docker-compose.yml` file is just for demonstration, adjust it to your needs):

```shell
docker compose build
docker compose up -d
```
