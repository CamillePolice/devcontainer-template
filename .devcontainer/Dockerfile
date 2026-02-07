FROM mcr.microsoft.com/devcontainers/base:debian

# Install Node.js and npm
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends nodejs npm jq tmux xclip \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Install n (Node version manager) and latest Node.js
RUN npm install -g n \
    && n latest \
    && npm install -g npm@latest