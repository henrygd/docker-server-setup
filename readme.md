## Simple setup script for Debian / Ubuntu servers

Run as root on a fresh installation

```bash
curl -s https://raw.githubusercontent.com/jacksonm36/docker-server-setup/main/setup.sh > setup.sh && chmod +x ./setup.sh && ./setup.sh
```

### Hardens and configures system

- Creates non-root user with sudo and docker privileges.

- Updates packages and optionally enables unattended-upgrades.

- Changes SSH port and disables password login through SSH.

- Configures firewall to block ingress except on ports 80, 443, and your chosen SSH port.

- Fail2ban working out of the box to block malicious bot traffic to public web applications.

- Ensures the server is set to your preferred time zone.

- Adds aliases like `dcu` / `dcd` / `dcr` for docker compose up / down / restart.

### Installs docker, docker compose, and selected services

Besides Nginx Proxy Manager, all services are tunneled through SSH and not publicly accessible. The following are installed by default:

- **[Portainer](https://github.com/portainer/portainer)** and **[ctop](https://github.com/bcicen/ctop)** for easy container management with GUI and terminal.

- **[Nginx Proxy Manager](https://github.com/NginxProxyManager/nginx-proxy-manager)** for publicly exposing your services with automatic SSL.

- **[MariaDB database](https://hub.docker.com/r/linuxserver/mariadb)** used by Nginx Proxy Manager and any other apps you want.

- **[phpMyAdmin](https://hub.docker.com/r/linuxserver/phpmyadmin)** for graphical administration of the MariaDB database.

- **[File Browser](https://github.com/filebrowser/filebrowser)** for graphical file management.

- **[Fail2ban](https://github.com/crazy-max/docker-fail2ban)** configured to read Nginx Proxy Manager logs and block malicious IPs in iptables.

- **[Watchtower](https://github.com/containrrr/watchtower)** to automatically update running containers to the latest image version.

These are defined and can be disabled in `~/server/docker-compose.yml`.

## Notes

Debian / Ubuntu derivatives like Raspbian should work but haven't been tested.

There is a docker network with the same name as your username. If you create new containers in that that network, you can use the container name as a hostname in Nginx Proxy Manager.

If you need to open a port for Wireguard or another service, [allow the port in iptables](https://www.digitalocean.com/community/tutorials/iptables-essentials-common-firewall-rules-and-commands) and run `sudo netfilter-persistent save` to save rules.

Make sure you have a good backup solution in place. I recommend **[Kopia](https://github.com/kopia/kopia)**.

To export the MariaDB database to disk for backup, you can use the command below (you may want to change the output directory).

```bash
docker exec mariadb sh -c 'mysqldump --all-databases -uroot -p"$MYSQL_ROOT_PASSWORD"' > ~/mariadb.sql
```

If you want to monitor uptime, check out **[Uptime Kuma](https://github.com/louislam/uptime-kuma)**, but you should run this from a different machine.

### Working with Fail2ban

You can view logs for Fail2ban in Dozzle or by using the `docker logs` command.

The jail is reloaded every six hours with a systemd timer to pick up log files from new proxy hosts.

Additional rules may be added to the container in `~/server/fail2ban`. Use the FORWARD chain (not INPUT or DOCKER-USER) and make sure the filter regex is using the NPM log format - `[Client <HOST>]`.

**View status of jail and currently banned IPs.**

```bash
docker exec fail2ban sh -c "fail2ban-client status npm-docker"
```

**Unban an IP in Fail2ban jail.** Replace `0.0.0.0` with the IP you want unbanned.

```bash
docker exec fail2ban sh -c "fail2ban-client set npm-docker unbanip 0.0.0.0"
```

**Whitelist an IP to avoid bans.** Edit the jail config using `nano` or `vi` - then find the line starting with `ignoreip`. [Add further IPs separated by spaces](https://fail2ban.org/wiki/index.php/Whitelist). Reload the jail for the changes to take effect immediately.

```bash
sudo vi ~/server/fail2ban/data/jail.d/jail.local
```

**Manually reload the jail.** Optional if you want protection for a newly created site right away. Jail automatically reloads every six hours.

```bash
docker exec fail2ban sh -c "fail2ban-client reload npm-docker"
```

### Logs

Nginx Proxy Manager logs are located in `~/server/npm/data/logs/`. You need the ID of the proxy host you want to view, which you can find by clicking the three dots in NPM. These logs are limited to web requests and are rotated weekly.

Example command to view live log: `tail -f ~/server/npm/data/logs/proxy-host-1_access.log`

Example command search log for IP: `grep "0.0.0.0" ~/server/npm/data/logs/proxy-host-1_access.log`

### Using with Cloudflare

If you proxy traffic through Cloudflare and want to use Fail2ban, additional configuration is required to avoid banning Cloudflare IPs. Please reference the guides below.

Fail2ban configuration is located in `~/server/fail2ban`.

- https://www.youtube.com/watch?v=Ha8NIAOsNvo (and [companion article](https://dbt3ch.com/books/fail2ban/page/how-to-install-and-configure-Fail2ban-to-work-with-nginx-proxy-manager) by DB Tech)

- https://blog.lrvt.de/fail2ban-with-nginx-proxy-manager/
