# Stage 1: Build stage to get static apk tools
FROM alpine:3.20 AS builder
WORKDIR /tmp
# Fetch the apk-tools-static binary which doesn't rely on dynamically linked libraries
RUN apk update && \
    apk fetch apk-tools-static && \
    tar -xzf apk-tools-static-*.apk

# Stage 2: Final n8n image
FROM n8nio/n8n:latest

USER root

# The latest official n8n images are "distroless" and strip out package managers.
# We bring the static apk binary back into the n8n environment to install Python natively.
COPY --from=builder /tmp/sbin/apk.static /sbin/apk

# Initialize the apk database and install python, pip, pandas, and requests.
# We explicitly point to Alpine v3.20 repositories since distroless drops /etc/apk/repositories.
RUN apk --initdb --no-cache \
        --repository https://dl-cdn.alpinelinux.org/alpine/v3.20/main \
        --repository https://dl-cdn.alpinelinux.org/alpine/v3.20/community \
        add python3 py3-pip py3-pandas py3-requests

# Copy requirements and install pure Python packages
COPY requirements.txt /tmp/requirements.txt
RUN if [ -s /tmp/requirements.txt ] && grep -q '[^[:space:]]' /tmp/requirements.txt; then \
      pip3 install --no-cache-dir --break-system-packages -r /tmp/requirements.txt; \
    fi

# Switch back to the 'node' user for security
USER node

# Expose port (Render will automatically detect this or it can be bound via PORT env var)
EXPOSE 5678
