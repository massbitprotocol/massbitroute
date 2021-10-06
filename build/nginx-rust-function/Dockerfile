FROM debian:9

ENV CARGO_BUILD_TARGET_DIR=/tmp/target

RUN apt-get update && \
    apt-get install -y \
            libpcre3-dev \
            zlib1g-dev \
            curl \
            unzip \
            make \
            clang \
            tar && \
    curl -L -O https://github.com/Taymindis/nginx-link-function/archive/3.2.1.zip && \
    curl -L -O http://nginx.org/download/nginx-1.10.3.tar.gz && \
    unzip 3.2.1.zip -d /opt/ && \
    install -m 644 /opt/nginx-link-function-3.2.1/src/ngx_link_func_module.h /usr/include/ && \
    tar -xzvf nginx-1.10.3.tar.gz && \
    cd nginx-1.10.3/ && \
    ./configure --add-module=/opt/nginx-link-function-3.2.1 && \
    make -j2 && \
    make install 

WORKDIR /work

COPY ./nginx.conf /usr/local/nginx/conf/
COPY ./src /work/src
COPY ./Cargo.* /work/

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y && \
    . ~/.cargo/env && \
    cd /work && \
    cargo build --target-dir /tmp/target

CMD ["/usr/local/nginx/sbin/nginx", "-g", "daemon off;"] 