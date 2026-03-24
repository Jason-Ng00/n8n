# Use the official n8n image
FROM n8nio/n8n:latest

# Switch to root to install system packages
USER root

# Install Python and pip using apt-get (the current n8n image is Debian/Ubuntu-based)
RUN apt-get update && \
    apt-get install -y python3 python3-pip python3-venv && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python packages
COPY requirements.txt /tmp/requirements.txt
RUN if [ -s /tmp/requirements.txt ] && grep -q '[^[:space:]]' /tmp/requirements.txt; then \
      pip3 install --no-cache-dir --break-system-packages -r /tmp/requirements.txt; \
    fi

# Switch back to the 'node' user for security
USER node

# Expose port (Render will automatically detect this or it can be bound via PORT env var)
EXPOSE 5678
