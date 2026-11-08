# EaglerCraft Server

A fresh Eaglercraft server project built around **Paper** (game server) and **Velocity** (proxy).

## Layout

- `server/` — Paper runtime, worlds, and plugins (runtime files are not committed)
- `proxy/` — Velocity runtime and configuration (runtime files are not committed)
- `web/` — browser client files (26.3 client still needs a verified compatible build)
- `scripts/` — install, start, and stop scripts

## Requirements

- Linux environment (GitHub Codespaces works for development)
- Java 21 or newer, depending on the selected Paper version
- `curl` and `jq`

## Install

Choose a Paper/Minecraft backend version deliberately:

```bash
export MC_VERSION="YOUR_SUPPORTED_MINECRAFT_VERSION"
chmod +x scripts/*.sh
./scripts/install.sh
```

The installer downloads the latest Paper build for that selected version and the latest published Velocity build.

## Start / stop

```bash
./scripts/start.sh
./scripts/stop.sh
```

Paper listens on `127.0.0.1:25565`; Velocity listens on `0.0.0.0:25577` by default. Adjust ports through environment variables in the scripts.

## Eaglercraft 26.3 compatibility

**The browser client is not ready to connect yet.** A normal Paper + Velocity stack speaks the Java Edition protocol. Eaglercraft clients need a compatible WebSocket/translation component, and support for Eaglercraft 26.3 must be confirmed before choosing and installing that component.

Do not expose the Paper backend directly to the public internet. Keep it bound to localhost behind Velocity.

## Important

- Do not commit server JARs, world data, player data, logs, secrets, or generated configs.
- Use plugins that explicitly support your selected Paper version.
- Keep the Velocity forwarding secret private.
