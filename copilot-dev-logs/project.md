# n8n Python Wrapper Deployment Repository

## Requirement Overview
- Create a minimal repository to act as a thin wrapper around the official n8n Docker image.
- Add Python 3 and pip support to use within n8n workflows (e.g., via Execute Command node).
- Ensure the setup is Docker-based, extremely minimal, and compatible with Render Web Services deployment.
- Maintain original n8n behavior without modifying source code.
- Prevent unnecessary abstraction like backend frameworks.

## Functionality
- **n8n Core:** Runs standard `n8nio/n8n:latest`.
- **Python Integration:** Installs `python3` and `pip` through Alpine's `apk`.
- **Dependency Management:** Supports installing custom Python packages through `requirements.txt` injected at build-time.
- **Render Ready:** Exposes typical n8n ports (`5678`) ensuring a smooth out-of-the-box hosting experience on Render without the need for docker-compose.
