#### Log

```shell

#on arm it fails to resolve some libs
docker build --platform linux/amd64  --log-driver json-file --log-opt max-size=10m -t hadoop-build-2.10.2 -f hadoop-build-env.dockerfile .

docker run -it --platform linux/amd64 hadoop-build-2.10.2 /bin/bash 


```
thereafter built,installed hadoop from the container

```shell
mvn package -Pdist,native -DskipTests -Dtar -Drequire.snappy

```

```shell
docker commit udayaw/hadoop
docker tag <image_id> udayaw/hadoop:latest
docker push udayaw/hadoop:latest

```
