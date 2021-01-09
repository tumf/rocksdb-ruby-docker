FROM golang:alpine as build-stage

ARG rocksdb_version="6.15.2"
ARG ruby_version="2.7"

RUN apk add --update --no-cache build-base linux-headers git cmake bash perl
RUN apk add --update --no-cache zlib zlib-dev bzip2 bzip2-dev snappy snappy-dev lz4 lz4-dev zstd zstd-dev gflags

# Install Rocksdb
RUN cd /tmp && \
    git clone --depth 1 https://github.com/facebook/rocksdb.git -b v${rocksdb_version} && \
    cd rocksdb && \
    make shared_lib && \
    mkdir -p /usr/local/rocksdb/lib && \
    mkdir /usr/local/rocksdb/include && \
    cp librocksdb.so* /usr/local/rocksdb/lib && \
    cp /usr/local/rocksdb/lib/librocksdb.so* /usr/lib/ && \
    cp -r include /usr/local/rocksdb/ && \
    cp -r include/* /usr/include/ && \
    rm -R /tmp/rocksdb/

FROM ruby:${ruby_version}-alpine
COPY --from=build-stage /usr/local/rocksdb /usr/local/

RUN apk add --no-cache --update --virtual=build-dependencies build-base linux-headers gcc g++ && \
  gem install rocksdb-ruby && \
  apk del build-dependencies && \
  rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

RUN apk add --update --no-cache snappy gflags libbz2 zlib lz4-libs zstd-libs

