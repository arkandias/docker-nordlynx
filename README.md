# Docker NordLynx Container

A Docker container enabling secure connections to NordVPN via NordLynx (NordVPN WireGuard-based protocol), based
on [linuxserver/wireguard][linuxserver] image and building upon [bubuntux/nordlynx][bubuntux]. Special thanks
to [@bubuntux](https://github.com/bubuntux) for his original work on NordLynx containerization.

## Prerequisites

### WireGuard

The WireGuard kernel module must be installed on your system before using this container.

* For general installation instructions, see [WireGuard installation guide][wg-install].
* For Synology NAS users, follow the instructions on [this repository][runfalk].

### NordLynx Private Key

You need a private key to connect to NordLynx. You can retrieve it using an access token:

1. Generate an access token from your NordVPN account dashboard (on [this page][token]).
2. Retrieve your private key by running the following command in a terminal:

```bash
curl -s -u token:<ACCESS_TOKEN> https://api.nordvpn.com/v1/users/services/credentials | jq -r '.nordlynx_private_key'
```

Note: Alternatively, you can use this image with just an access token rather than your private key.

## Limitations

* IPv6 is not handled (yet!). All IPv6 packets are blocked by the firewall.

## Usage

### Docker Compose (recommended)

```yaml
services:
  nordlynx:
    image: ghcr.io/arkandias/nordlynx:latest
    container_name: nordlynx
    cap_add:
      - NET_ADMIN # required
    sysctls:
      - net.ipv4.conf.all.src_valid_mark=1 # required
      - net.ipv6.conf.all.disable_ipv6=1 # recommended
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Paris
      - PRIVATE_KEY=[redacted] # required
      - COUNTRY_CODE=FR
      - CATEGORY=standard
```

### Docker CLI

```bash
docker run \
  --name=nordlynx \
  --cap-add=NET_ADMIN \
  --sysctl net.ipv4.conf.all.src_valid_mark=1 \
  --sysctl net.ipv6.conf.all.disable_ipv6=1 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Europe/Paris \
  -e PRIVATE_KEY=[redacted] \
  -e COUNTRY_CODE=FR \
  -e CATEGORY=standard \
  ghcr.io/arkandias/nordlynx:latest
```

### Routing other containers through NordLynx

This image is designed to create a VPN tunnel that can be used by other containers. Here's an example of routing a
Firefox container traffic through NordLynx:

```yaml
services:
  nordlynx:
    image: ghcr.io/arkandias/nordlynx:latest
    container_name: nordlynx
    cap_add:
      - NET_ADMIN # required
    sysctls:
      - net.ipv4.conf.all.src_valid_mark=1 # required
      - net.ipv6.conf.all.disable_ipv6=1 # recommended
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Paris
      - PRIVATE_KEY=[redacted] # required
      - COUNTRY_CODE=FR
      - CATEGORY=standard
    ports:
      - "3000:3000" # Firefox desktop GUI
      - "3001:3001" # Firefox desktop GUI HTTPS
    restart: unless-stopped

  firefox:
    image: lscr.io/linuxserver/firefox:latest
    container_name: firefox
    depends_on:
      nordlynx:
        condition: service_healthy
    network_mode: "service:nordlynx"
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Paris
    volumes:
      - /path/to/config:/config
    # ports:          # moved in nordlynx
    #   - 3000:3000   # moved in nordlynx
    #   - 3001:3001   # moved in nordlynx
    shm_size: "1gb"
    restart: unless-stopped
```

## Parameters

### Basic configuration

|      Parameter      |   Default    | Description                                                                                                                                                                    |
|:-------------------:|:------------:|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|       `PUID`        |    `911`     | Container user ID.                                                                                                                                                             |
|       `PGID`        |    `911`     | Container group ID.                                                                                                                                                            |
|        `TZ`         |  `Etc/UTC`   | Container time zone. An IANA Time Zone identifier (e.g., `Europe/Paris`, `America/New_York`, `Asia/Tokyo`; [full list][TZ]).                                                   |
|    `PRIVATE_KEY`    | **Required** | Your NordLynx private key. A base64 private key generated by `wg keygen`.                                                                                                      |
| `FILE__PRIVATE_KEY` |              | Alternative to `PRIVATE_KEY` for Docker secrets. Use path `/run/secrets/<secret_name>`.                                                                                        |
|       `TOKEN`       |              | Alternative to `PRIVATE_KEY`. A NordVPN access token.                                                                                                                          |
|   `COUNTRY_CODE`    |              | Target country for server selection. An ISO country code (e.g., `FR`, `US`, `JP`; [full list][CC]).                                                                            |
|      `REGION`       |              | Target region for server selection. Options: `africa_the_middle_east_and_india`, `asia_pacific`, `europe`, `the_americas`. Note: Conflicts with `COUNTRY_CODE` and `CATEGORY`. |
|     `CATEGORY`      |              | Target type for server selection. Options: `standard`, `p2p`, `double_vpn`, `obfuscated_servers`, `onion_over_vpn` ([more info][categories]).                                  |
|     `RECONNECT`     |  `infinity`  | Interval between automatic reconnections to refresh the WireGuard connection (e.g., `300`=`300s`, `10m`, `12h`, `1d`).                                                         |

### Advanced configuration

It is recommended to keep the default values unless you know what you are doing.

#### Container-specific parameters

|   Parameter    | Default | Description                                                                                                                                                    |
|:--------------:|:-------:|----------------------------------------------------------------------------------------------------------------------------------------------------------------|
|  `INTERFACE`   | `eth0`  | The network interface used to establish the WireGuard connection.                                                                                              |
| `WG_INTERFACE` |  `wg0`  | The name of the WireGuard interface to be created.                                                                                                             |
|  `NET_LOCAL`   |         | A comma-separated list of IPv4 addresses with CIDR masks that should remain accessible while connected to the VPN (e.g., `192.168.1.0/24`, `10.0.0.0/8`).      |
|  `ALLOW_LIST`  |         | A comma-separated list of domains that should be accessible through direct connection instead of the VPN tunnel (e.g., `an.example.com, another.example.com`). |

#### WireGuard parameters

For detailed information about each parameter, refer to [wg][wg] and [wg-quick][wg-quick] documentations.

|                  Parameter                   |            Default             | Description                                                                                                                                                                                                                                                                                                                                     |
|:--------------------------------------------:|:------------------------------:|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|                `LISTEN_PORT`                 |            `51820`             | A 16-bit port for listening.                                                                                                                                                                                                                                                                                                                    |
|                  `ADDRESS`                   |         `10.5.0.2/32`          | A comma-separated list of IP (v4 or v6) addresses (optionally with CIDR masks) to be assigned to the interface.                                                                                                                                                                                                                                 |
|                    `DNS`                     | `103.86.96.100, 103.86.99.100` | A comma-separated list of IP (v4 or v6) addresses to be set as the interface's DNS servers, or non-IP hostnames to be set as the interface's DNS search domains. The default value corresponds to NordVPN's DNS servers.                                                                                                                        |
|                    `MTU`                     |                                | If not specified, the MTU is automatically determined from the endpoint addresses or the system default route, which is usually a sane choice. However, to manually specify an MTU to override this automatic discovery, this value may be specified explicitly.                                                                                |
|                   `TABLE`                    |             `auto`             | Controls the routing table to which routes are added. There are two special values: `off` disables the creation of routes altogether, and `auto` adds routes to the default table and enables special handling of default routes.                                                                                                               |
| `PRE_UP`, `POST_UP`, `PRE_DOWN`, `POST_DOWN` |                                | Script snippets which will be executed before/after setting up/tearing down the interface, most commonly used to configure custom DNS options or firewall rules.                                                                                                                                                                                |
|                 `PUBLIC_KEY`                 |                                | A base64 public key calculated by `wg pubkey` from a private key, and usually transmitted out of band to the author of the configuration file. This parameter is automatically set by the connection script using one of NordVPN server, unless it is provided along with `ENDPOINT`.                                                           |
|                  `ENDPOINT`                  |                                | An endpoint IP or hostname, followed by a colon, and then a port number. This endpoint will be updated automatically to the most recent source IP address and port of correctly authenticated packets from the peer. This parameter is set by the connection script using one of NordVPN server, unless it is provided along with `PUBLIC_KEY`. |
|                `ALLOWED_IPS`                 |    `0.0.0.0/1, 128.0.0.0/1`    | A comma-separated list of IP (v4 or v6) addresses with CIDR masks from which incoming traffic for this peer is allowed and to which outgoing traffic for this peer is directed. The default value is an alternative to the catch-all `0.0.0.0/0`, which is incompatible with some systems.                                                      |
|            `PERSISTENT_KEEPALIVE`            |              `25`              | A seconds interval, between 1 and 65535 inclusive, of how often to send an authenticated empty packet to the peer for the purpose of keeping a stateful firewall or NAT mapping valid persistently.                                                                                                                                             |

[linuxserver]: https://github.com/linuxserver/docker-wireguard

[bubuntux]: https://github.com/bubuntux/nordlynx

[wg-install]: https://www.wireguard.com/install/

[runfalk]: https://github.com/runfalk/synology-wireguard

[token]: https://my.nordaccount.com/fr/dashboard/nordvpn/access-tokens/

[wg]: https://manpages.ubuntu.com/manpages/noble/man8/wg.8.html#configuration%20file%20format

[wg-quick]: https://manpages.ubuntu.com/manpages/noble/man8/wg-quick.8.html#configuration

[CC]: https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2#Officially_assigned_code_elements

[TZ]: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List

[categories]: https://support.nordvpn.com/hc/en-us/articles/19479130821521-Different-NordVPN-server-categories-explained
