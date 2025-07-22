# Dockerfile
FROM ubuntu:22.04

# 기본 패키지 설치
RUN apt-get update && apt-get install -y \
    gdb \
    python3 \
    python3-pip \
    git \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

# pwndbg 설치
RUN git clone https://github.com/pwndbg/pwndbg.git && \
    cd pwndbg && \
    ./setup.sh

# Python 의존성 설치
RUN pip3 install fastmcp

# 작업 디렉토리 생성
RUN mkdir -p /app /workspace

WORKDIR /app