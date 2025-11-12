# Repository Guidelines

## Project Structure & Module Organization
- `docker-compose.yaml` orchestrates the Nginx reverse proxy container and is the single entry point for local orchestration.  
- `nginx/nginx.conf` holds the virtual host, TLS, and upstream rules; keep related directives grouped and favor include blocks when adding new services.  
- `nginx/certs/` stores the local CA (`fireflyCA.crt`) and leaf keys (`server.key`, `server.crt`). Replace these files when rotating certificates; never commit production secrets.

## Build, Test, and Development Commands
- `docker compose up -d` spins up the HTTPS-ready Nginx stack; always run from the repo root.  
- `docker compose logs -f nginx` tails runtime logs to validate routing rules during development.  
- `docker compose exec nginx nginx -t` lints the active config and should pass before every push.  
- `docker compose down -v` stops containers and clears ephemeral volumes when you need a clean slate.

## Coding Style & Naming Conventions
- YAML and Conf files use two-space indentation and lowercase directive names.  
- Mirror the existing `feat:`/`fix:` Conventional Commit prefixes (e.g., `feat: adiciona upstream app`) and write subjects in the imperative mood.  
- Certificate artifacts follow the `server.*` naming pattern; create new services under `nginx/<service>.conf` and reference them from `nginx.conf`.

## Testing Guidelines
- Validate syntax with `docker compose exec nginx nginx -t` before reloading.  
- Hit `https://localhost` (or the mapped host) with `curl -vk https://localhost` to confirm TLS chains and headers.  
- When adjusting certificates, regenerate via your preferred tool, drop them into `nginx/certs/`, and rerun the curl check to ensure the chain matches the CA.

## Commit & Pull Request Guidelines
- Keep commits focused: config change + cert rotation + doc update should be separate commits.  
- Pull requests must describe the motivation, reference any related issue, and list verification steps (commands run, curl output, screenshots if UI proxies are involved).  
- Mention breaking changes such as new ports or certificate authorities so downstream agents can update their environments promptly.

## Security & Configuration Tips
- Store private keys with restrictive permissions locally and rotate them before sharing builds.  
- Never push environment-specific secrets; instead, document required variables in the PR and use `.env` overrides locally.  
- When debugging, prefer temporary overrides in `docker-compose.override.yml` so the base manifest stays production-ready.
