# Use the official n8n image
FROM n8nio/n8n:latest

# Switch to root to install system packages
USER root

# Install Python3, pip, and commonly compiled packages via Alpine's package manager
# Installing pandas/numpy via pip on Alpine fails due to missing C compilers.
RUN apk add --update --no-cache python3 py3-pip py3-pandas py3-requests

# Copy requirements and install pure Python packages
COPY requirements.txt /tmp/requirements.txt
RUN if [ -s /tmp/requirements.txt ] && grep -q '[^[:space:]]' /tmp/requirements.txt; then \
      pip3 install --no-cache-dir --break-system-packages -r /tmp/requirements.txt; \
    fi

# Switch back to the 'node' user for security
USER node

# Expose port (Render will automatically detect this or it can be bound via PORT env var)
EXPOSE 5678
