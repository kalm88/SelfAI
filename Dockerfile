FROM python:3.11.6-slim-bookworm as base

# Install poetry
RUN pip install pipx
RUN pipx install poetry
ENV PATH="/root/.local/bin:$PATH"
ENV PATH=".venv/bin/:$PATH"

# https://python-poetry.org/docs/configuration/#virtualenvsin-project
ENV POETRY_VIRTUALENVS_IN_PROJECT=true

FROM base as dependencies
WORKDIR /home/worker/app
# Dependencies to build llama-cpp
RUN apt update && apt install -y \
  libopenblas-dev\
  ninja-build\
  build-essential\
  pkg-config\
  wget
COPY pyproject.toml poetry.lock ./

# Extras possible are: llms-llama-cpp embeddings-huggingface
ARG POETRY_EXTRAS="ui vector-stores-qdrant llms-ollama embeddings-ollama"
RUN poetry install --no-root --extras "${POETRY_EXTRAS}"

FROM base as app
ENV \
  PYTHONUNBUFFERED=1 \
  PORT=8080 \
  PYTHONPATH="$PYTHONPATH:/home/worker/app/private_gpt/" \
  APP_ENV=prod \
  PGPT_MODE=mock \
  PGPT_EMBEDDING_MODE=sagemaker \
  PGPT_HF_REPO_ID=TheBloke/Mistral-7B-Instruct-v0.1-GGUF \
  PGPT_HF_MODEL_FILE=mistral-7b-instruct-v0.1.Q4_K_M.gguf \
  PGPT_EMBEDDING_HF_MODEL_NAME=BAAI/bge-small-en-v1.5 \
  PGPT_SAGEMAKER_LLM_ENDPOINT_NAME= \
  PGPT_SAGEMAKER_EMBEDDING_ENDPOINT_NAME= \
  PGPT_OLLAMA_LLM_MODEL=mistral \
  PGPT_OLLAMA_EMBEDDING_MODEL=nomic-embed-text \
  PGPT_OLLAMA_API_BASE=http://ollama:11434 \
  PGPT_OLLAMA_TFS_Z=1.0 \
  PGPT_OLLAMA_TOP_K=40 \
  PGPT_OLLAMA_TOP_P=0.9 \
  PGPT_OLLAMA_REPEAT_LAST_N=64 \
  PGPT_OLLAMA_REPEAT_PENALTY=1.2 \
  PGPT_OLLAMA_REQUEST_TIMEOUT=600.0 \
  PGPT_OPENAI_API_BASE=https://api.openai.com/v1 \
  PGPT_OPENAI_API_KEY=EMPTY \
  PGPT_OPENAI_MODEL=
EXPOSE 8080

# Prepare a non-root user
ARG UID=100
ARG GID=65534
RUN adduser --system --uid ${UID} --gid ${GID} --home /home/worker worker
WORKDIR /home/worker/app

RUN mkdir local_data && chown worker local_data
RUN mkdir models && chown worker models
COPY --chown=worker --from=dependencies /home/worker/app/.venv/ .venv
COPY --chown=worker private_gpt/ private_gpt
COPY --chown=worker fern/ fern
COPY --chown=worker *.yaml .
COPY --chown=worker scripts/ scripts
COPY --chown=worker Makefile .

USER worker
ENTRYPOINT python -m private_gpt