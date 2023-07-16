### Building Native Hadoop Libraries for 2.10.1 on OSX Ventura

I had to build hadoop native libraries to tryout org.apache.hadoop.io.compress.SnappyCodec

Refer https://github.com/apache/hadoop/blob/trunk/BUILDING.txt for dependencies for specific versions.

***Brew install dependencies***
```
brew install gcc autoconf automake libtool cmake snappy gzip bzip2 zlib openssl
```

***Protobuf 2.5***
```
wget https://github.com/google/protobuf/releases/download/v2.5.0/protobuf-2.5.0.tar.gz
tar -xzf protobuf-2.5.0.tar.gz
cd protobuf-2.5.0

./configure
make
make check
sudo make install
# And just to check if everything is ok.
# This should print libprotoc 2.5.0
protoc --version

```

`make uninstall` to remove outdated protoc out of your system after hadoop build.

Resolve Issue#1
```
./google/protobuf/stubs/atomicops_internals_macosx.h:162:50: error: unknown type name 'Atomic64'; did you mean 'Atomic32'?
inline Atomic64 Barrier_AtomicIncrement(volatile Atomic64* ptr,
                                                 ^~~~~~~~
                                                 Atomic32
./google/protobuf/stubs/atomicops.h:65:15: note: 'Atomic32' declared here
```
https://github.com/protocolbuffers/protobuf/issues/8836#issuecomment-892391885



### Building Hadoop
```
git clone https://github.com/apache/hadoop
git checkout branch-2.10.1
mvn package -Pdist,native -DskipTests -Dtar -Drequire.snappy -Dbundle.snappy -Dsnappy.lib=/opt/homebrew/Cellar/snappy/1.1.10/lib/
``` 

***Issue#1 :hadoop-common Missing ZLIB_LIBRARY***
```
[WARNING] 
[WARNING] CMake Deprecation Warning at CMakeLists.txt:23 (cmake_minimum_required):
[WARNING]   Compatibility with CMake < 2.8.12 will be removed from a future version of
[WARNING]   CMake.
[WARNING] 
[WARNING]   Update the VERSION argument <min> value or use a ...<max> suffix to tell
[WARNING]   CMake that the project does not need compatibility with older versions.
[WARNING] 
[WARNING] 
[WARNING] CMake Error at /opt/homebrew/Cellar/cmake/3.26.4/share/cmake/Modules/FindPackageHandleStandardArgs.cmake:230 (message):
[WARNING]   Could NOT find ZLIB (missing: ZLIB_LIBRARY) (found version "1.2.11")
[WARNING] Call Stack (most recent call first):
[WARNING]   /opt/homebrew/Cellar/cmake/3.26.4/share/cmake/Modules/FindPackageHandleStandardArgs.cmake:600 (_FPHSA_FAILURE_MESSAGE)
[WARNING]   /opt/homebrew/Cellar/cmake/3.26.4/share/cmake/Modules/FindZLIB.cmake:200 (FIND_PACKAGE_HANDLE_STANDARD_ARGS)
[WARNING]   CMakeLists.txt:47 (find_package)
[WARNING] 
[WARNING] 
[WARNING] -- Configuring incomplete, errors occurred!
```
Looking at /opt/homebrew/Cellar/cmake/3.26.4/share/cmake/Modules/FindZLIB.cmake
set
`export ZLIB_ROOT=/opt/homebrew/Cellar/zlib/1.2.13/`
which produced
```[WARNING] CMake Warning (dev) at CMakeLists.txt:47 (find_package):
[WARNING]   Policy CMP0074 is not set: find_package uses <PackageName>_ROOT variables.
[WARNING]   Run "cmake --help-policy CMP0074" for policy details.  Use the cmake_policy
[WARNING]   command to set the policy and suppress this warning.
[WARNING] 
[WARNING]   Environment variable ZLIB_ROOT is set to:
[WARNING] 
[WARNING]     /opt/homebrew/Cellar/zlib/1.2.13/
[WARNING] 
[WARNING]   For compatibility, CMake is ignoring the variable.
[WARNING] This warning is for project developers.  Use -Wno-dev to suppress it.
[WARNING] 
[WARNING] CMake Error at /opt/homebrew/Cellar/cmake/3.26.4/share/cmake/Modules/FindPackageHandleStandardArgs.cmake:230 (message):
[WARNING]   Could NOT find ZLIB (missing: ZLIB_LIBRARY) (found version "1.2.11")
[WARNING] Call Stack (most recent call first):
[WARNING]   /opt/homebrew/Cellar/cmake/3.26.4/share/cmake/Modules/FindPackageHandleStandardArgs.cmake:600 (_FPHSA_FAILURE_MESSAGE)
[WARNING]   /opt/homebrew/Cellar/cmake/3.26.4/share/cmake/Modules/FindZLIB.cmake:200 (FIND_PACKAGE_HANDLE_STANDARD_ARGS)
[WARNING]   CMakeLists.txt:47 (find_package)
[WARNING] 
[WARNING] 
[WARNING] -- Configuring incomplete, errors occurred!
```
After reading

https://www.cnblogs.com/shoufeng/p/14942271.html
https://github.com/MarkDana/Compile-Hadoop2.2.0-on-MacOS

added `cmake_policy(SET CMP0074 NEW)` at `hadoop-common-project/hadoop-common/src/CMakeLists.txt`
after the line `cmake_minimum_required(VERSION 2.6 FATAL_ERROR)`

Thank you! MarkDana.


***Issue#2 :hadoop-common Missing Snappy***



```
[WARNING] 
[WARNING] CMake Error at CMakeLists.txt:94 (message):
[WARNING]   Required snappy library could not be found.
[WARNING]   SNAPPY_LIBRARY=SNAPPY_LIBRARY-NOTFOUND, SNAPPY_INCLUDE_DIR=,
[WARNING]   CUSTOM_SNAPPY_INCLUDE_DIR=, CUSTOM_SNAPPY_PREFIX=, CUSTOM_SNAPPY_INCLUDE=
[WARNING] 
[WARNING] 
[WARNING] -- Configuring incomplete, errors occurred!

```
update hadoop-common/pom.xml with `SNAPPY_LIBRARY` and `SNAPPY_INCLUDE_DIR`
```
<configuration>
  <source>${basedir}/src</source>
  <vars>
    <GENERATED_JAVAH>${project.build.directory}/native/javah</GENERATED_JAVAH>
    <JVM_ARCH_DATA_MODEL>${sun.arch.data.model}</JVM_ARCH_DATA_MODEL>
    <REQUIRE_BZIP2>${require.bzip2}</REQUIRE_BZIP2>
    <REQUIRE_SNAPPY>${require.snappy}</REQUIRE_SNAPPY>
    <CUSTOM_SNAPPY_PREFIX>${snappy.prefix}</CUSTOM_SNAPPY_PREFIX>
    <CUSTOM_SNAPPY_LIB>${snappy.lib} </CUSTOM_SNAPPY_LIB>
    <CUSTOM_SNAPPY_INCLUDE>${snappy.include} </CUSTOM_SNAPPY_INCLUDE>
    <REQUIRE_ZSTD>${require.zstd}</REQUIRE_ZSTD>
    <CUSTOM_ZSTD_PREFIX>${zstd.prefix}</CUSTOM_ZSTD_PREFIX>
    <CUSTOM_ZSTD_LIB>${zstd.lib}</CUSTOM_ZSTD_LIB>
    <CUSTOM_ZSTD_INCLUDE>${zstd.include}</CUSTOM_ZSTD_INCLUDE>
    <REQUIRE_OPENSSL>${require.openssl} </REQUIRE_OPENSSL>
    <CUSTOM_OPENSSL_PREFIX>${openssl.prefix} </CUSTOM_OPENSSL_PREFIX>
    <CUSTOM_OPENSSL_LIB>${openssl.lib} </CUSTOM_OPENSSL_LIB>
    <CUSTOM_OPENSSL_INCLUDE>${openssl.include} </CUSTOM_OPENSSL_INCLUDE>
    <EXTRA_LIBHADOOP_RPATH>${extra.libhadoop.rpath}</EXTRA_LIBHADOOP_RPATH>
    <SNAPPY_LIBRARY>/opt/homebrew/Cellar/snappy/1.1.10/lib/</SNAPPY_LIBRARY>
    <SNAPPY_INCLUDE_DIR>/opt/homebrew/Cellar/snappy/1.1.10/include/</SNAPPY_INCLUDE_DIR>
  </vars>
</configuration>
```


***Issue#3 :hadoop-yarn-server-nodemanager failed to link inline function alloc_and_clear_memory***
```[WARNING] Undefined symbols for architecture x86_64:
[WARNING]   "_alloc_and_clear_memory", referenced from:
[WARNING]       _get_docker_pull_command in libcontainer.a(docker-util.c.o)
[WARNING]       _get_docker_run_command in libcontainer.a(docker-util.c.o)
[WARNING] ld: symbol(s) not found for architecture x86_64
[WARNING] clang: error: linker command failed with exit code 1 (use -v to see invocation)
[WARNING] make[2]: *** [target/usr/local/bin/test-container-executor] Error 1
[WARNING] make[1]: *** [CMakeFiles/test-container-executor.dir/all] Error 2
```
/hadoop-yarn-project/hadoop-yarn/hadoop-yarn-server/hadoop-yarn-server-nodemanager/src/main/native/container-executor/impl/util.h defines this inline function which failed to get linked somehow :(
don`t know much about resolvig c++ build issues, so redefined this in util.c as non-inline function and it got resolved.

```
inline void* alloc_and_clear_memory(size_t num, size_t size) {
  void *ret = calloc(num, size);
  if (ret == NULL) {
    printf("Could not allocate memory, exiting\n");
    exit(OUT_OF_MEMORY);
  }
  return ret;
}

```

***Issue#4 :hadoop-pipes openssl link failures for 86_64 in Arm***

```
[WARNING] Undefined symbols for architecture x86_64:
[WARNING]   "_BIO_ctrl", referenced from:
[WARNING]       HadoopPipes::BinaryProtocol::createDigest(std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char>>&, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char>>&) in libhadooppipes.a(HadoopPipes.cc.o)
[WARNING]   "_BIO_f_base64", referenced from:

......
[WARNING]       HadoopPipes::BinaryProtocol::createDigest(std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char>>&, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char>>&) in libhadooppipes.a(HadoopPipes.cc.o)
[WARNING]   "_HMAC_Init_ex", referenced from:
[WARNING]       HadoopPipes::BinaryProtocol::createDigest(std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char>>&, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char>>&) in libhadooppipes.a(HadoopPipes.cc.o)
[WARNING]   "_HMAC_Update", referenced from:
[WARNING]       HadoopPipes::BinaryProtocol::createDigest(std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char>>&, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char>>&) in libhadooppipes.a(HadoopPipes.cc.o)
[WARNING] ld: symbol(s) not found for architecture x86_64
[WARNING] make[1]: *** [CMakeFiles/wordcount-part.dir/all] Error 2
[WARNING] clang: error: linker command failed with exit code 1 (use -v to see invocation)
[WARNING] clang: error: linker command failed with exit code 1 (use -v to see invocation)
[WARNING] make[2]: *** [examples/wordcount-nopipe] Error 1
[WARNING] make[1]: *** [CMakeFiles/wordcount-nopipe.dir/all] Error 2
[WARNING] make[2]: *** [examples/pipes-sort] Error 1
[WARNING] make[1]: *** [CMakeFiles/pipes-sort.dir/all] Error 2
[WARNING] make: *** [all] Error 2
```

Also shown,
```
[WARNING] ld: warning: ignoring file /opt/homebrew/Cellar/openssl@1.1/1.1.1u/lib/libssl.dylib, building for macOS-x86_64 but attempting to link with file built for macOS-arm64
```

Added additional cmake arg to build for arm in /hadoop-tools/hadoop-pipes/pom.xml

```                
<configuration>
  <source>${basedir}/src</source>
  <vars>
    <JVM_ARCH_DATA_MODEL>${sun.arch.data.model}</JVM_ARCH_DATA_MODEL>
    <CMAKE_OSX_ARCHITECTURES>arm64</CMAKE_OSX_ARCHITECTURES>
  </vars>
</configuration>
```


### Build Succeded

![img](https://github.com/udayaw/osx-hadoop-native-libs/assets/2282417/688ea9b3-7c56-47b0-911b-7b79f1371e85)



`cp -R hadoop-dist/target/hadoop-<VERSION>/lib $HADOOP_HOME`


***Final Notes***

Eventhough build succeeded on OSx, dll did not get linked properly. org.apache.hadoop.util.NativeClassLoader failed to init snappy.
Although snappy lib installed was arm64 and libhadoop was build for x86_64. Also many issues with dylib cache etc.. decided never to attempt this further..

dockerized native build also not supported due to Virtualbox not being available on arm. I guess hadoop natives were never intended to be build for osx.



***References***

https://dev.to/zejnilovic/building-hadoop-native-libraries-on-mac-in-2019-1iee
