# Training Management System - Docker Setup Guide
Cook Shire Council

## 📋 Overview

This setup includes:
- **MySQL 8.0** database with complete schema
- **Nginx** web server serving the training management application
- **phpMyAdmin** for database management (optional)
- **Docker Compose** orchestration

---

## 🚀 Quick Start

### Prerequisites
- Docker installed on your server
- Docker Compose installed
- At least 2GB RAM available
- Ports 80, 3306, 8081 available (or modify as needed)

### Step 1: Upload Files to Server

```bash
# Create project directory
mkdir -p /var/www/training-system
cd /var/www/training-system

# Upload these files:
# - docker-compose.yml
# - database-schema.sql
# - nginx.conf
# - .env.example
# - html/training_management_with_matrix.html (as html/index.html)
```

### Step 2: Prepare Environment

```bash
# Create .env file from template
cp .env.example .env

# Edit .env and set secure passwords
nano .env

# Create html directory
mkdir -p html

# Copy your HTML file
cp training_management_with_matrix.html html/index.html
```

### Step 3: Start the Stack

```bash
# Start all services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

### Step 4: Verify Database

```bash
# Connect to MySQL
docker exec -it training_db mysql -u training_app -p
# Enter password from .env file

# Check tables
USE training_db;
SHOW TABLES;

# Exit
exit
```

### Step 5: Access the Application

- **Training System**: http://YOUR_SERVER_IP:8080
- **phpMyAdmin**: http://YOUR_SERVER_IP:8081
- **Database**: YOUR_SERVER_IP:3306

---

## 📊 Database Schema

### Tables Created:
1. **departments** - Organizational departments
2. **roles** - Job roles
3. **competency_categories** - Categories for competencies
4. **competencies** - Training competencies/requirements
5. **role_competencies** - Links roles to required competencies
6. **training_courses** - Course library (internal/external)
7. **course_competencies** - Links courses to competencies
8. **people** - Staff members
9. **training_records** - Individual training completion records
10. **internal_verifications** - Internal verification records
11. **training_reminders** - Automated reminder system
12. **audit_log** - Change tracking
13. **users** - System access control

### Pre-loaded Sample Data:
- 12 departments
- 15 roles
- 5 competency categories
- 10 competencies
- 6 training courses
- 5 sample staff members
- Sample training records and verifications

---

## 🔧 Configuration

### Changing Ports

Edit `docker-compose.yml`:

```yaml
services:
  web:
    ports:
      - "80:80"  # Change first number for different host port
  
  db:
    ports:
      - "3307:3306"  # Change to avoid conflicts
  
  phpmyadmin:
    ports:
      - "8082:80"  # Change phpMyAdmin port
```

### Database Backups

```bash
# Manual backup
docker exec training_db mysqldump -u training_app -p training_db > backup_$(date +%Y%m%d).sql

# Restore from backup
docker exec -i training_db mysql -u training_app -p training_db < backup_20241210.sql
```

### Automated Backups (add to crontab)

```bash
# Edit crontab
crontab -e

# Add daily backup at 2 AM
0 2 * * * cd /var/www/training-system && docker exec training_db mysqldump -u training_app -p$(grep DB_PASSWORD .env | cut -d '=' -f2) training_db > backups/backup_$(date +\%Y\%m\%d_\%H\%M).sql
```

---

## 🔐 Security Recommendations

### 1. Change Default Passwords

```bash
# Edit .env file
nano .env

# Set strong passwords
DB_ROOT_PASSWORD=VeryStr0ng!Root@Pass
DB_PASSWORD=S3cur3App!Pass@2024
```

### 2. Restrict phpMyAdmin Access

Option A: Remove it entirely (comment out in docker-compose.yml)

Option B: Restrict to localhost only:

```yaml
phpmyadmin:
  ports:
    - "127.0.0.1:8081:80"  # Only accessible from server
```

### 3. Enable SSL/HTTPS

Update your main Nginx configuration (on host, not in container):

```nginx
server {
    listen 443 ssl;
    server_name app.askr.com.au;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 4. Firewall Configuration

```bash
# Allow only necessary ports
ufw allow 22/tcp   # SSH
ufw allow 80/tcp   # HTTP
ufw allow 443/tcp  # HTTPS
ufw enable

# Database should NOT be exposed externally
# Remove port mapping in docker-compose.yml if not needed
```

---

## 📱 Connecting Frontend to Database (Future)

When ready to connect your HTML frontend to the database:

### Option 1: REST API (Recommended)

Create a simple Node.js or PHP API:

```bash
# Uncomment the api service in docker-compose.yml
# Add your API code to ./api directory
docker-compose up -d api
```

### Option 2: Direct PHP Integration

```bash
# Add PHP to your web container
# Update docker-compose.yml web service:

web:
  image: php:8.2-fpm-alpine
  # ... rest of config
```

---

## 🛠️ Useful Commands

### Docker Management

```bash
# Stop all services
docker-compose down

# Stop and remove all data
docker-compose down -v

# Restart a service
docker-compose restart web

# View logs for specific service
docker-compose logs -f db

# Execute command in container
docker-compose exec db mysql -u training_app -p

# Update containers
docker-compose pull
docker-compose up -d
```

### Database Queries

```bash
# Connect to database
docker exec -it training_db mysql -u training_app -p training_db

# Useful queries:
```

```sql
-- View all people and their roles
SELECT 
    CONCAT(p.first_name, ' ', p.last_name) as name,
    r.name as role,
    d.name as department
FROM people p
LEFT JOIN roles r ON p.role_id = r.id
LEFT JOIN departments d ON p.department_id = d.id;

-- Check training compliance
SELECT * FROM view_person_training_compliance;

-- Find expiring training
SELECT * FROM view_expiring_training;

-- Find expired training
SELECT * FROM view_expired_training;

-- Department summary
SELECT * FROM view_department_training_summary;
```

---

## 📈 Monitoring & Maintenance

### Check Container Health

```bash
# View container status
docker-compose ps

# Check resource usage
docker stats

# View disk usage
docker system df
```

### Log Rotation

```bash
# Configure Docker log rotation
# Create /etc/docker/daemon.json:

{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}

# Restart Docker
systemctl restart docker
```

---

## 🐛 Troubleshooting

### Database Won't Start

```bash
# Check logs
docker-compose logs db

# Common issues:
# 1. Port already in use
#    Solution: Change port in docker-compose.yml

# 2. Permission issues
#    Solution: sudo chown -R 999:999 ./db_data

# 3. Corrupted data
#    Solution: docker-compose down -v (WARNING: deletes data)
```

### Can't Connect to Database

```bash
# Check if container is running
docker-compose ps

# Check network
docker network ls
docker network inspect training-system_training_network

# Test connection
docker exec -it training_db mysql -u training_app -p -e "SELECT 1"
```

### Web Application Not Loading

```bash
# Check nginx logs
docker-compose logs web

# Verify files exist
docker exec training_web ls -la /usr/share/nginx/html/

# Test nginx config
docker exec training_web nginx -t
```

---

## 🔄 Updating the Application

### Update HTML Files

```bash
cd /var/www/training-system
cp new_version.html html/index.html
docker-compose restart web
```

### Update Database Schema

```bash
# Create migration SQL file
nano migration_v2.sql

# Apply migration
docker exec -i training_db mysql -u training_app -p training_db < migration_v2.sql
```

---

## 📊 Performance Tuning

### MySQL Configuration

Create `mysql.cnf`:

```ini
[mysqld]
max_connections = 100
innodb_buffer_pool_size = 512M
query_cache_size = 64M
```

Add to docker-compose.yml:

```yaml
db:
  volumes:
    - ./mysql.cnf:/etc/mysql/conf.d/custom.cnf:ro
```

### Nginx Caching

Already configured in nginx.conf, but can be enhanced with:

```nginx
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m max_size=1g inactive=60m;
```

---

## 🆘 Getting Help

### View All Logs

```bash
# All services
docker-compose logs

# Last 100 lines
docker-compose logs --tail=100

# Follow logs
docker-compose logs -f
```

### System Information

```bash
# Docker version
docker --version
docker-compose --version

# System resources
free -h
df -h
```

---

## ✅ Production Checklist

Before going live:

- [ ] Change all default passwords in .env
- [ ] Set up automated backups
- [ ] Configure SSL/HTTPS
- [ ] Restrict phpMyAdmin access or remove it
- [ ] Configure firewall rules
- [ ] Test disaster recovery (restore from backup)
- [ ] Set up monitoring/alerting
- [ ] Document custom changes
- [ ] Train staff on system usage
- [ ] Create user accounts with appropriate permissions

---

## 📞 Support

For issues:
1. Check logs: `docker-compose logs`
2. Verify configuration files
3. Check database connectivity
4. Review this guide's troubleshooting section

---

**Congratulations! Your Training Management System is ready to use!** 🎉
