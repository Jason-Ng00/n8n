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

# ── Build the venv at a fixed absolute path ────────
# Instead of wrestling with pnpm symlinks and hoisted node_modules, we build a
# pristine virtual environment at /opt/venv and patch the n8n application to use it.
RUN mkdir -p /opt/venv && \
    python3 -m venv /opt/venv && \
    /opt/venv/bin/pip install --no-cache-dir --upgrade pip && \
    /opt/venv/bin/pip install --no-cache-dir "websockets>=15.0.1"

# ── Install user Python packages into the venv ────────────────────────────────
COPY requirements.txt /tmp/requirements.txt
RUN if [ -s /tmp/requirements.txt ] && grep -q '[^[:space:]]' /tmp/requirements.txt; then \
      /opt/venv/bin/pip install --no-cache-dir -r /tmp/requirements.txt; \
    fi

# ── Patch n8n to force it to use /opt/venv and exact Paths ─────────────────
# We find the JS file `task-runner-process-py.js` which is responsible for returning
# the absolute path to the Python environment, and we patch `getVenvPath` method
# to return our custom path unconditionally. We also resolve the execution CWD dynamically.
RUN JS_FILE=$(find /usr/local/lib/node_modules/n8n -type f -name "task-runner-process-py.js" | head -n 1) && \
    if [ -n "$JS_FILE" ]; then \
      echo "Target file found: $JS_FILE" && \
      TASK_RUNNER_DIR=$(node -p "require('path').dirname(require.resolve('@n8n/task-runner-python/package.json'))") && \
      echo "Task Runner Absolute Dir: $TASK_RUNNER_DIR" && \
      python3 -c "import re, sys; c=open(sys.argv[1]).read(); c=re.sub(r'getVenvPath\(\)\s*\{[^}]+\}', 'getVenvPath() { return \"/opt/venv/bin/python\"; }', c); c=re.sub(r'const pythonDir =[^;]+;', 'const pythonDir = \"' + sys.argv[2] + '\";', c); open(sys.argv[1], 'w').write(c)" "$JS_FILE" "$TASK_RUNNER_DIR" && \
      echo "Successfully patched n8n Python task runner paths!"; \
    else \
      echo "WARNING: Could not find Python task runner JS file to patch. Build might fail at runtime."; \
    fi

# ── Fix ownership ─────────────────────────────────────────────────────────────
RUN chown -R node:node /opt/venv

# Switch back to the 'node' user for security
USER node

# Officially set n8n to accept the internal runner
ENV N8N_RUNNERS_MODE=internal

# Expose port
EXPOSE 5678
