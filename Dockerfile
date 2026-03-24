# Stage 1: Fetch apk-tools-static so we can install Alpine packages
# in the distroless n8n image which has no native package manager.
FROM alpine:3.20 AS builder
WORKDIR /tmp
RUN apk update && \
    apk fetch apk-tools-static && \
    tar -xzf apk-tools-static-*.apk

# Stage 2: Final n8n image
FROM n8nio/n8n:latest

USER root

# ── Inject apk back into the distroless n8n environment ──────────────────────
# The current n8n image strips out all package managers for security.
# We bring the static apk binary back to bootstrap Python.
COPY --from=builder /tmp/sbin/apk.static /sbin/apk

# ── Install Python + venv support via Alpine ──────────────────────────────────
RUN apk --initdb --no-cache \
        --repository https://dl-cdn.alpinelinux.org/alpine/v3.20/main \
        --repository https://dl-cdn.alpinelinux.org/alpine/v3.20/community \
        add python3 py3-pip py3-virtualenv

# ── Pre-build the Python virtual environment n8n's task runner expects ────────
# n8n (internal mode) looks for a venv at /home/node/python/venv.
# Creating it at build-time avoids the runtime "venv missing" error.
RUN python3 -m venv /home/node/python/venv && \
    /home/node/python/venv/bin/pip install --no-cache-dir --upgrade pip

# ── Install Python packages into the venv ────────────────────────────────────
COPY requirements.txt /tmp/requirements.txt
RUN if [ -s /tmp/requirements.txt ] && grep -q '[^[:space:]]' /tmp/requirements.txt; then \
      /home/node/python/venv/bin/pip install --no-cache-dir -r /tmp/requirements.txt; \
    fi

# ── Ensure the node user owns the venv directory ─────────────────────────────
RUN chown -R node:node /home/node/python

# ── Expose Python venv on PATH ────────────────────────────────────────────────
ENV PATH="/home/node/python/venv/bin:$PATH"

# Switch back to the 'node' user for security
USER node

# Expose port
EXPOSE 5678
