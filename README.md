# n8n with Python Support

A minimal Docker wrapper around the official [n8n](https://n8n.io/) image, adding Python 3 support out of the box. This enables executing Python scripts within your n8n workflows using the **Execute Command** node or other custom scripts.

## Features
- Base image: `n8nio/n8n:latest`
- Includes `python3` and `pip`
- Easily customizable Python dependencies via `requirements.txt`
- Extremely lightweight, ready for deployment on platforms like Render.

## How to add Python packages
Add your desired libraries to the `requirements.txt` file (e.g., `requests`, `pandas`), and they will be installed automatically when the Docker image builds.

## Deployment on Render
1. Create a new **Web Service** on Render.
2. Select **"Build and deploy from a Git repository"** and connect this repo.
3. Render will detect the `Dockerfile` and build the image.
4. Go to **Environment Variables** in Render and optionally set:
   - `PORT`: `5678` (Render often detects the `EXPOSE 5678` instruction automatically)
5. Add any n8n environment variables you might need (e.g., `N8N_ENCRYPTION_KEY`, `WEBHOOK_URL`).
6. Deploy and start building workflows!
