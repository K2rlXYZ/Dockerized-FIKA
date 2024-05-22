# Dockerized-FIKA
A modified version of bullets [SIT.Docker](https://github.com/stayintarkov/SIT.Docker)

You can change the [FIKA](https://github.com/project-fika/Fika-Server)_BRANCH and [SPT](https://dev.sp-tarkov.com/SPT-AKI/Server)_BRANCH args to match the version you want. For example.

```
ARG SPT_BRANCH=3.8.1
```
```
ARG FIKA_BRANCH=v2.0
```

With docker:
```
docker build --no-cache --label FIKA -t fika .
docker run --pull=never -v [server files]:/opt/server --net=host -it --name fika fika
docker start fika
docker update --restart unless-stopped fika
```