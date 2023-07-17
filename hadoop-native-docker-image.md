### udayaw/hadoop-2.10.2
https://hub.docker.com/repository/docker/udayaw/hadoop-2.10.2/general


#### build environment


```shell

#on arm it fails to resolve some libs
docker build --platform linux/amd64 -t hadoop-build-2.10.2 -f hadoop-build-env.dockerfile .

docker cp <container_id>:/root/hadoop/hadoop-dist/target/hadoop-2.10.2.tar.gz .
docker build --platform linux/amd64 -t hadoop-2.10.2 -f hadoop-2.10.2.dockerfile .

```

if all is good `docker run hadoop-2.10.2 hadoop checknative` should produce,

```23/07/16 21:57:43 INFO bzip2.Bzip2Factory: Successfully loaded & initialized native-bzip2 library system-native
23/07/16 21:57:43 INFO zlib.ZlibFactory: Successfully loaded & initialized native-zlib library
Native library checking:
hadoop:  true /usr/local/hadoop-2.10.2/lib/native/libhadoop.so.1.0.0
zlib:    true /lib/x86_64-linux-gnu/libz.so.1
snappy:  true /usr/lib/x86_64-linux-gnu/libsnappy.so.1
zstd  :  true /usr/lib/x86_64-linux-gnu/libzstd.so.1
lz4:     true revision:10301
bzip2:   true /lib/x86_64-linux-gnu/libbz2.so.1
openssl: true /usr/lib/x86_64-linux-gnu/libcrypto.so
```

#### Deploy

```shell

docker tag hadoop-2.10.2 udayaw/hadoop-2.10.2
docker push udayaw/hadoop-2.10.2

```

#### Usage

To decompress sample snappy
```
hadoop fs -text my.snappy > my.text
```
