# WordPress with MySQL Example

This example demonstrates a complete WordPress installation with MySQL database using Docker Compose.

## What's Included

- WordPress 6.x (latest)
- MySQL 8.0
- phpMyAdmin (optional, for database management)
- Persistent volumes for data
- Custom network
- Environment variables

## Quick Start

```bash
# Start the application
docker-compose up -d

# View logs
docker-compose logs -f

# Access WordPress
# Open browser to: http://localhost:8080

# Access phpMyAdmin (optional)
# Open browser to: http://localhost:8081
# Server: db
# Username: wordpress
# Password: wordpress_password

# Stop the application
docker-compose down

# Stop and remove volumes (clean slate)
docker-compose down -v
```

## Architecture

```
┌─────────────────┐
│   WordPress     │  Port 8080
│   (PHP/Apache)  │
└────────┬────────┘
         │
         │ Connects to
         │
┌────────┴────────┐
│     MySQL       │  Port 3306 (internal)
│   Database      │
└─────────────────┘

Optional:
┌─────────────────┐
│   phpMyAdmin    │  Port 8081
└─────────────────┘
```

## Configuration

### Environment Variables

Edit `docker-compose.yml` to change:

- `WORDPRESS_DB_NAME`: Database name (default: wordpress)
- `WORDPRESS_DB_USER`: Database user (default: wordpress)
- `WORDPRESS_DB_PASSWORD`: Database password (default: wordpress_password)
- `MYSQL_ROOT_PASSWORD`: MySQL root password (default: root_password)

### Ports

- **8080**: WordPress web interface
- **8081**: phpMyAdmin (optional)
- **3306**: MySQL (internal only)

## Volumes

Data is persisted in Docker volumes:

- `wordpress_data`: WordPress files (themes, plugins, uploads)
- `db_data`: MySQL database

### Backup Volumes

```bash
# Backup WordPress data
docker run --rm -v wordpress_data:/data -v $(pwd):/backup alpine tar czf /backup/wordpress-backup.tar.gz /data

# Backup MySQL data
docker run --rm -v db_data:/data -v $(pwd):/backup alpine tar czf /backup/db-backup.tar.gz /data
```

### Restore Volumes

```bash
# Restore WordPress data
docker run --rm -v wordpress_data:/data -v $(pwd):/backup alpine sh -c "cd /data && tar xzf /backup/wordpress-backup.tar.gz --strip 1"

# Restore MySQL data
docker run --rm -v db_data:/data -v $(pwd):/backup alpine sh -c "cd /data && tar xzf /backup/db-backup.tar.gz --strip 1"
```

## Customization

### Install Themes and Plugins

1. Access WordPress at http://localhost:8080
2. Complete initial setup
3. Login to admin panel
4. Go to Appearance → Themes or Plugins → Add New

### Use Custom Theme

```yaml
# Add to wordpress service in docker-compose.yml
volumes:
  - ./my-theme:/var/www/html/wp-content/themes/my-theme
```

### Configure PHP Settings

Create `php.ini`:

```ini
upload_max_filesize = 64M
post_max_size = 64M
memory_limit = 256M
max_execution_time = 300
```

Then add to wordpress service:

```yaml
volumes:
  - ./php.ini:/usr/local/etc/php/conf.d/custom.ini
```

## Production Considerations

For production use, you should:

1. **Change all passwords** - Use strong, unique passwords
2. **Use secrets** - Store passwords in Docker secrets
3. **Add SSL/TLS** - Use a reverse proxy (Nginx/Traefik) with Let's Encrypt
4. **Regular backups** - Automate volume backups
5. **Update regularly** - Keep WordPress and MySQL up to date
6. **Resource limits** - Add memory and CPU limits
7. **Health checks** - Add healthcheck directives
8. **Monitoring** - Add monitoring and alerting

## Troubleshooting

### WordPress shows database connection error

```bash
# Check if MySQL is ready
docker-compose logs db

# Wait 30 seconds for MySQL to initialize on first start
# Then restart WordPress
docker-compose restart wordpress
```

### Cannot upload files larger than 2MB

Update `php.ini` as shown in Customization section.

### Reset WordPress completely

```bash
# Stop and remove everything including volumes
docker-compose down -v

# Start fresh
docker-compose up -d
```

### View MySQL logs

```bash
docker-compose logs db
```

### Access MySQL command line

```bash
docker-compose exec db mysql -u root -p
# Enter root password when prompted
```

## Security Best Practices

1. **Change default passwords** immediately
2. **Don't expose MySQL port** to host (keep it internal)
3. **Regular updates**: Keep WordPress and plugins updated
4. **Use strong passwords**: At least 16 characters
5. **Limit login attempts**: Install security plugin
6. **Regular backups**: Automate daily backups
7. **Use HTTPS**: Add reverse proxy with SSL

## Useful Commands

```bash
# View all running containers
docker-compose ps

# View logs for specific service
docker-compose logs wordpress
docker-compose logs db

# Restart specific service
docker-compose restart wordpress

# Execute command in WordPress container
docker-compose exec wordpress bash

# Execute command in MySQL container
docker-compose exec db bash

# Update images to latest
docker-compose pull
docker-compose up -d

# Check resource usage
docker stats
```

## References

- [WordPress Docker Official Image](https://hub.docker.com/_/wordpress)
- [MySQL Docker Official Image](https://hub.docker.com/_/mysql)
- [phpMyAdmin Docker Image](https://hub.docker.com/_/phpmyadmin)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

---

**Book Reference:** Docker Field Manual, Chapter 5: Docker Compose
