# Ollama Devcontainer Configuration

This directory contains the Ollama Docker configuration files cloned from your GitHub repository.

## GitHub Repository Structure

Your Ollama repository should contain at minimum:

```
ollama-devcontainer/
├── docker-compose.yml    # Required - Ollama service definition
├── README.md             # Optional - Documentation
└── .env.example          # Optional - Environment variables template
```

## Required: docker-compose.yml

The `docker-compose.yml` should define Ollama services with CPU and GPU profiles:

```yaml
# Ollama Local LLM Service
# Usage:
#   CPU mode: docker compose --profile ollama up -d
#   GPU mode: docker compose --profile ollama-gpu up -d

services:
  ollama:
    image: ollama/ollama:latest
    container_name: ollama-local
    restart: unless-stopped
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama
    environment:
      - OLLAMA_KEEP_ALIVE=${OLLAMA_KEEP_ALIVE:-5m}
      - OLLAMA_MAX_LOADED_MODELS=${OLLAMA_MAX_LOADED_MODELS:-1}
      - OLLAMA_HOST=0.0.0.0
    profiles:
      - ollama
    deploy:
      resources:
        limits:
          memory: ${OLLAMA_MEMORY_LIMIT:-8G}
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:11434/api/tags"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s

  ollama-gpu:
    image: ollama/ollama:latest
    container_name: ollama-local-gpu
    restart: unless-stopped
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama
    environment:
      - OLLAMA_KEEP_ALIVE=${OLLAMA_KEEP_ALIVE:-5m}
      - OLLAMA_MAX_LOADED_MODELS=${OLLAMA_MAX_LOADED_MODELS:-1}
      - OLLAMA_HOST=0.0.0.0
    profiles:
      - ollama-gpu
    deploy:
      resources:
        limits:
          memory: ${OLLAMA_MEMORY_LIMIT:-8G}
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:11434/api/tags"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s

volumes:
  ollama_data:
    name: ollama_models_cache
```

## Environment Variables

Configure in `devcontainer.json`:

| Variable | Default | Description |
|----------|---------|-------------|
| `USE_OLLAMA` | `false` | Enable Ollama installation |
| `OLLAMA_REPO` | `CamillePolice/ollama` | GitHub repository |
| `OLLAMA_DEFAULT_MODEL` | `qwen2.5-coder:7b` | Model to pull on setup |
| `OLLAMA_GPU_ENABLED` | `auto` | GPU mode: `true`/`false`/`auto` |
| `OLLAMA_KEEP_ALIVE` | `5m` | Model keep-alive time |
| `OLLAMA_MEMORY_LIMIT` | `8G` | Container memory limit |

## Usage

After setup:

```bash
# Start interactive session
ollama-run qwen2.5-coder:7b

# Pull additional models
ollama-pull codellama:7b

# List models
ollama-list

# Check status
ollama-status

# Quick access (cost optimization)
cc1                  # Local LLM (free)
cc                   # Claude default (paid)
```

## Recommended Models

| Model | Size | Use Case |
|-------|------|----------|
| `qwen2.5-coder:7b` | 4.7GB | Best balance for coding |
| `qwen2.5-coder:1.5b` | 1.1GB | Quick completions, low resources |
| `codellama:7b` | 3.8GB | Fast inference |
| `deepseek-coder:6.7b` | 3.8GB | Complex code quality |
