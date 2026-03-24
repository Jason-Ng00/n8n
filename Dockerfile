# Stage 1: Fetch apk-tools-static so we can install Alpine packages
# in the distroless n8n image which has no native package manager.
FROM alpine:3.21 AS builder
WORKDIR /tmp
RUN apk update && \
    apk fetch apk-tools-static && \
    tar -xzf apk-tools-static-*.apk

# Stage 2: Final n8n image
FROM n8nio/n8n:latest

USER root

# ── Inject apk back into the distroless n8n environment ──────────────────────
COPY --from=builder /tmp/sbin/apk.static /sbin/apk

# ── Install Python 3.13 (required by n8n's python task runner) ───────────────
# Alpine 3.21 ships python3.13. We point to that repo explicitly.
RUN apk --initdb --no-cache \
        --repository https://dl-cdn.alpinelinux.org/alpine/v3.21/main \
        --repository https://dl-cdn.alpinelinux.org/alpine/v3.21/community \
        add python3 py3-pip

# ── Build the venv at the EXACT path n8n's internal task runner checks ────────
# Source: packages/cli/src/task-runners/task-runner-process-py.ts
# getVenvPath() => path.join(__dirname, '../../../@n8n/task-runner-python', '.venv', 'bin', 'python')
# __dirname resolves to: /usr/local/lib/node_modules/n8n/packages/cli/dist/task-runners
# Final venv path:       /usr/local/lib/node_modules/n8n/node_modules/@n8n/task-runner-python/.venv
# Also install the n8n python runner's own dependency (websockets) into it.
ENV PYTHON_RUNNER_DIR=/usr/local/lib/node_modules/n8n/node_modules/@n8n/task-runner-python
RUN python3 -m venv ${PYTHON_RUNNER_DIR}/.venv && \
    ${PYTHON_RUNNER_DIR}/.venv/bin/pip install --no-cache-dir --upgrade pip && \
    ${PYTHON_RUNNER_DIR}/.venv/bin/pip install --no-cache-dir "websockets>=15.0.1"

# ── Install user Python packages into the venv ────────────────────────────────
COPY requirements.txt /tmp/requirements.txt
RUN if [ -s /tmp/requirements.txt ] && grep -q '[^[:space:]]' /tmp/requirements.txt; then \
      ${PYTHON_RUNNER_DIR}/.venv/bin/pip install --no-cache-dir -r /tmp/requirements.txt; \
    fi

# ── Fix ownership ─────────────────────────────────────────────────────────────
RUN chown -R node:node ${PYTHON_RUNNER_DIR}/.venv

# Switch back to the 'node' user for security
USER node

# Expose port
EXPOSE 5678
