FROM nvidia/cuda:12.2.2-cudnn8-devel-ubuntu22.04
LABEL authors="HumanAIGC-Engineering"

ARG CONFIG_FILE=config/chat_with_minicpm.yaml

ENV DEBIAN_FRONTEND=noninteractive

# 替换为清华大学的APT源
RUN sed -i 's/archive.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list && \
    sed -i 's/security.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list

# 更新包列表并安装必要的依赖
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    apt-get install -y python3.10 python3.10-dev python3-pip git wget

# 安装 cuDNN 9.x
RUN wget https://developer.download.nvidia.com/compute/cudnn/9.1.0/local_installers/cudnn-local-repo-ubuntu2204-9.1.0_1.0-1_amd64.deb && \
    dpkg -i cudnn-local-repo-ubuntu2204-9.1.0_1.0-1_amd64.deb && \
    cp /var/cudnn-local-repo-ubuntu2204-9.1.0/cudnn-*-keyring.gpg /usr/share/keyrings/ && \
    apt-get update && \
    apt-get -y install cudnn && \
    rm cudnn-local-repo-ubuntu2204-9.1.0_1.0-1_amd64.deb

RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1

ARG WORK_DIR=/root/open-avatar-chat
WORKDIR $WORK_DIR

#安装核心依赖
COPY ./install.py $WORK_DIR/install.py
COPY ./pyproject.toml $WORK_DIR/pyproject.toml
COPY ./src/third_party $WORK_DIR/src/third_party
RUN pip install uv && \
    uv venv --python 3.10 && \
    uv sync --no-install-workspace

ADD ./src $WORK_DIR/src

#安装config依赖
RUN echo "Using config file: ${CONFIG_FILE}"
COPY $CONFIG_FILE /tmp/build_config.yaml
RUN uv run install.py \
    --config /tmp/build_config.yaml \
    --uv \
    --skip-core && \
    rm /tmp/build_config.yaml

ADD ./resource $WORK_DIR/resource
ADD ./scripts $WORK_DIR/scripts
ADD ./.env* $WORK_DIR/

WORKDIR $WORK_DIR
ENTRYPOINT ["uv", "run", "src/demo.py"]
