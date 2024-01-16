# syntax=docker/dockerfile:1.6

ARG PYTHON_VERSION=3.11.6

FROM python:${PYTHON_VERSION}-slim-bullseye AS builder

LABEL org.opencontainers.image.description "Python toy app"

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get -qq update && apt-get -qq install \
    --no-install-recommends -y \
    curl \
    gcc \
    libpq-dev \
    python3-dev \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/cache/debconf/*

ENV PIP_NO_CACHE_DIR=off
ENV PIP_DISABLE_PIP_VERSION_CHECK=on
ENV PIP_DEFAULT_TIMEOUT=100
ENV POETRY_HOME="/opt/poetry"
ENV POETRY_VERSION=1.7.1
ENV POETRY_VIRTUALENVS_IN_PROJECT=true
ENV POETRY_NO_INTERACTION=1

ENV VENV="/opt/venv"
ENV PATH="$POETRY_HOME/bin:$VENV/bin:$PATH"

WORKDIR /app

COPY requirements.txt requirements.txt

RUN python -m venv $VENV \
    && . "${VENV}/bin/activate" \
    && python -m pip install "poetry==${POETRY_VERSION}" \
    && python -m pip install -r requirements.txt

FROM python:${PYTHON_VERSION}-slim-bullseye AS dev

ENV HOSTNAME="${HOST:-localhost}"
ENV VENV="/opt/venv"
ENV PATH="${VENV}/bin:${VENV}/lib/python${PYTHON_VERSION}/site-packages:/usr/local/bin:${HOME}/.local/bin:/bin:/usr/bin:/usr/share/doc:$PATH"

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONFAULTHANDLER 1

ENV WEB_CONCURRENCY=2

ARG DEBIAN_FRONTEND=noninteractive

ARG USER_NAME=appuser
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USER_NAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USER_NAME

WORKDIR /app

COPY --from=builder $VENV $VENV
COPY . .

USER $USER_NAME

RUN tee -a "$HOME/.bashrc" <<EOF
# aliases
alias ..='cd ../'
alias ...='cd ../../'
alias ll='ls -la --color=auto'

EOF

RUN tee -a "$HOME/.bash_profile" <<EOF
[[ -s ~/.bashrc ]] && . ~/.bashrc

EOF

FROM dev AS runner

WORKDIR /app

ENV PATH=$VENV_PATH/bin:$HOME/.local/bin:$PATH

EXPOSE 8000

# CMD ["sleep", "infinity"]
CMD ["gunicorn", "-w", "4", "-k", "uvicorn.workers.UvicornWorker", "-b", "0.0.0.0:8000", "app:app", "--reload"]
