# EaglerCraft Server

A Paper + Velocity network with Eaglercraft browser-client support.

## Architecture

```text
Eaglercraft 26.2 Zeus browser client
        | WebSocket :8082
        v
Velocity + EaglerXServer
        | private backend connection
        v
Paper :25566 (localhost)
```

Java Edition players use the Velocity Java listener on **25565**. Eaglercraft players use the additional EaglerXServer listener on **8082**. The browser game page itself can be hosted separately (for example, GitHub Pages); EaglerXServer handles the Eaglercraft protocol on the proxy. Run the bridge setup script after the first Velocity boot so the plugin has generated its config.

## Components

- **Paper** — worlds and Bukkit plugins
- **Velocity** — proxy and Java Edition listener
- **EaglerXServer 1.1.1** — Velocity bridge for documented legacy Eaglercraft clients; 26.2 Zeus support is unverified
- **ViaVersion** — needed on the Paper backend if connecting legacy Eaglercraft 1.8 clients to a newer Paper version; compatibility must be tested with the chosen releases

> This project uses EaglerXServer rather than the older EaglercraftXBungee/EaglercraftXVelocity plugins. The upstream EaglerXServer project recommends replacing those older plugins.

## Requirements

- Linux environment (GitHub Codespaces works for development)
- Java 25 or newer for Minecraft/Paper 26.3
- `curl` and `jq`

## Install

The default backend target is Minecraft Java **26.2**:

```bash
chmod +x scripts/*.sh
./scripts/install.sh
```

Override the backend version only if you intentionally want a different Paper version:

```bash
MC_VERSION=26.3 ./scripts/install.sh
```

The installer downloads Paper 26.2, Velocity, and EaglerXServer 1.1.1. It does not download the 26.2 Zeus browser client or copy client files into this repository. Get the client from the official [Eaglercraft downloads page](https://eaglercraft.com/downloads), and only add it to `web/` after checking the project's redistribution terms.

## First boot and configuration

1. Run `./scripts/start.sh` once. Paper and Velocity will generate their default configuration files.
2. Stop both with `./scripts/stop.sh`.
3. In `proxy/velocity.toml`, set the main Java listener to `bind = "0.0.0.0:25565"`.
4. Set the backend in Velocity's `[servers]` section to `127.0.0.1:25566` (the Paper port below), and make it the try/default server.
5. In `server/server.properties`, set `server-port=25566`, `server-ip=127.0.0.1`, and `online-mode=false`. Keep Paper private behind Velocity.
6. Configure Velocity modern forwarding and copy the generated forwarding secret into Paper's matching Paper/Velocity forwarding configuration. Keep that secret private.
7. Start the network again so EaglerXServer creates its configuration folder and default listener config.
8. Stop the network, then run `./scripts/configure-bridge.sh`. It adds a separate EaglerXServer listener named `eaglercraft-8082` at `0.0.0.0:8082`, with Velocity's `velocity_clone_listener` enabled. This keeps the Java listener on 25565 and Paper private on 25566.
9. Start the network again with `./scripts/start.sh`.

**Important:** EaglerXServer does not serve your browser game's HTML page. Host the client page separately and configure its WebSocket address to your public host on port 8082. Use HTTPS/WSS when the page is served over HTTPS.

## Compatibility notes

- EaglerXServer's documented client support is EaglercraftX 1.8, Eaglercraft 1.12.2, and Eaglercraft 1.5.2. It is not evidence that an unrelated client build labelled **26.3** is compatible.
- Minecraft Java 26.3 is the backend target, not the Eaglercraft client protocol version.
- For EaglercraftX 1.8 clients joining Paper 26.3, install a current ViaVersion build on the Paper backend and test login, movement, inventory, and world interactions. Compatibility is not guaranteed until tested.
- If your intended browser client is specifically a Eaglercraft 26.2 Zeus client, this stack still needs a bridge/client compatibility test before it can be called supported.

## Start / stop

```bash
./scripts/start.sh
./scripts/stop.sh
```

Logs:
- `server/paper-console.log`
- `proxy/velocity-console.log`

## Ports to forward

- **8082/TCP** — Eaglercraft WebSocket listener
- **25565/TCP** — Velocity Java Edition listener

Do not expose the Paper backend port. Keep it bound to localhost.

## Safety and repository hygiene

- Do not commit server JARs, world data, player data, logs, secrets, or generated configs.
- Use plugins that explicitly support your selected Paper version.
- Never publish the Velocity forwarding secret.
- EaglerXServer's Velocity integration injects into Velocity listeners; follow its generated config and upstream documentation rather than copying the old Bungee listener YAML.
