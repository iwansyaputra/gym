# Deployment Guide

Panduan untuk deploy API ke production server.

## 🌐 Deployment Options

### Option 1: Heroku (Recommended for beginners)

#### Prerequisites
- Akun Heroku (gratis)
- Heroku CLI installed

#### Steps

1. **Install Heroku CLI**
   ```bash
   # Download dari https://devcenter.heroku.com/articles/heroku-cli
   ```

2. **Login ke Heroku**
   ```bash
   heroku login
   ```

3. **Create Heroku App**
   ```bash
   cd api
   heroku create membership-gym-api
   ```

4. **Add MySQL Database (ClearDB)**
   ```bash
   heroku addons:create cleardb:ignite
   ```

5. **Get Database URL**
   ```bash
   heroku config:get CLEARDB_DATABASE_URL
   # Copy URL dan parse ke format:
   # mysql://username:password@host/database
   ```

6. **Set Environment Variables**
   ```bash
   heroku config:set NODE_ENV=production
   heroku config:set JWT_SECRET=your_super_secret_key
   heroku config:set DB_HOST=your_db_host
   heroku config:set DB_USER=your_db_user
   heroku config:set DB_PASSWORD=your_db_password
   heroku config:set DB_NAME=your_db_name
   heroku config:set EMAIL_USER=your_email@gmail.com
   heroku config:set EMAIL_PASSWORD=your_app_password
   ```

7. **Deploy**
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git push heroku main
   ```

8. **Import Database Schema**
   - Connect ke ClearDB menggunakan MySQL client
   - Import `database/schema.sql`

9. **Test**
   ```bash
   heroku open
   # Atau
   curl https://membership-gym-api.herokuapp.com/health
   ```

---

### Option 2: DigitalOcean Droplet

#### Prerequisites
- Akun DigitalOcean
- Basic Linux knowledge

#### Steps

1. **Create Droplet**
   - Choose Ubuntu 22.04 LTS
   - Select plan (minimum $6/month)
   - Add SSH key

2. **SSH to Server**
   ```bash
   ssh root@your_server_ip
   ```

3. **Install Node.js**
   ```bash
   curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
   sudo apt-get install -y nodejs
   ```

4. **Install MySQL**
   ```bash
   sudo apt update
   sudo apt install mysql-server
   sudo mysql_secure_installation
   ```

5. **Setup MySQL Database**
   ```bash
   sudo mysql
   CREATE DATABASE membership_gym;
   CREATE USER 'gymuser'@'localhost' IDENTIFIED BY 'strong_password';
   GRANT ALL PRIVILEGES ON membership_gym.* TO 'gymuser'@'localhost';
   FLUSH PRIVILEGES;
   EXIT;
   
   # Import schema
   mysql -u gymuser -p membership_gym < database/schema.sql
   ```

6. **Clone Project**
   ```bash
   cd /var/www
   git clone your_repository_url
   cd membership_gym/api
   npm install
   ```

7. **Setup Environment**
   ```bash
   cp .env.example .env
   nano .env
   # Edit dengan konfigurasi production
   ```

8. **Install PM2 (Process Manager)**
   ```bash
   sudo npm install -g pm2
   pm2 start server.js --name membership-gym-api
   pm2 startup
   pm2 save
   ```

9. **Setup Nginx (Reverse Proxy)**
   ```bash
   sudo apt install nginx
   sudo nano /etc/nginx/sites-available/membership-gym-api
   ```

   Add configuration:
   ```nginx
   server {
       listen 80;
       server_name your_domain.com;

       location / {
           proxy_pass http://localhost:3000;
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection 'upgrade';
           proxy_set_header Host $host;
           proxy_cache_bypass $http_upgrade;
       }
   }
   ```

   ```bash
   sudo ln -s /etc/nginx/sites-available/membership-gym-api /etc/nginx/sites-enabled/
   sudo nginx -t
   sudo systemctl restart nginx
   ```

10. **Setup SSL (Optional but Recommended)**
    ```bash
    sudo apt install certbot python3-certbot-nginx
    sudo certbot --nginx -d your_domain.com
    ```

---

### Option 3: AWS EC2

Similar to DigitalOcean, but:
1. Create EC2 instance (t2.micro for free tier)
2. Configure Security Groups (allow ports 22, 80, 443, 3000)
3. Follow DigitalOcean steps for setup

---

### Option 4: Railway.app (Easiest)

1. **Go to Railway.app**
   - Sign up with GitHub

2. **New Project**
   - Connect GitHub repository
   - Railway auto-detects Node.js

3. **Add MySQL Database**
   - Click "New" → "Database" → "MySQL"

4. **Set Environment Variables**
   - Go to Variables tab
   - Add all env vars from `.env.example`

5. **Deploy**
   - Railway auto-deploys on git push

---

## 🔒 Production Checklist

### Security
- [ ] Change JWT_SECRET to strong random string
- [ ] Use strong database password
- [ ] Enable HTTPS/SSL
- [ ] Set NODE_ENV=production
- [ ] Disable CORS for specific domains only
- [ ] Add rate limiting
- [ ] Enable helmet.js for security headers

### Performance
- [ ] Enable gzip compression
- [ ] Add caching where appropriate
- [ ] Optimize database queries
- [ ] Add database indexes
- [ ] Monitor server resources

### Monitoring
- [ ] Setup error logging (Sentry, LogRocket)
- [ ] Setup uptime monitoring (UptimeRobot)
- [ ] Setup performance monitoring (New Relic, DataDog)
- [ ] Setup database backups

### Documentation
- [ ] Update API documentation with production URL
- [ ] Document deployment process
- [ ] Create runbook for common issues

---

## 🔧 Production Environment Variables

```env
NODE_ENV=production
PORT=3000

# Database
DB_HOST=your_production_db_host
DB_USER=your_db_user
DB_PASSWORD=strong_password_here
DB_NAME=membership_gym
DB_PORT=3306

# JWT
JWT_SECRET=very_long_random_string_change_this_in_production_min_32_chars
JWT_EXPIRES_IN=7d

# Email
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your-production-email@gmail.com
EMAIL_PASSWORD=your-app-password

# CORS (optional - restrict to your Flutter app domain)
ALLOWED_ORIGINS=https://your-flutter-app.com
```

---

## 📊 Monitoring & Maintenance

### Check Server Status
```bash
# PM2
pm2 status
pm2 logs membership-gym-api

# Nginx
sudo systemctl status nginx
sudo tail -f /var/log/nginx/error.log

# MySQL
sudo systemctl status mysql
```

### Database Backup
```bash
# Backup
mysqldump -u gymuser -p membership_gym > backup_$(date +%Y%m%d).sql

# Restore
mysql -u gymuser -p membership_gym < backup_20240115.sql
```

### Update Application
```bash
cd /var/www/membership_gym/api
git pull
npm install
pm2 restart membership-gym-api
```

---

## 🚨 Troubleshooting Production

### API not responding
```bash
pm2 restart membership-gym-api
pm2 logs membership-gym-api --lines 100
```

### Database connection issues
```bash
# Check MySQL status
sudo systemctl status mysql

# Check connection
mysql -u gymuser -p -h localhost membership_gym
```

### High memory usage
```bash
# Check processes
htop

# Restart PM2
pm2 restart all
```

---

## 📱 Update Flutter App

Setelah deploy, update base URL di Flutter app:

```dart
// Before (Development)
static const String baseUrl = 'http://10.0.2.2:3000/api';

// After (Production)
static const String baseUrl = 'https://your-domain.com/api';
```

---

## 💰 Cost Estimation

| Platform | Cost | Pros | Cons |
|----------|------|------|------|
| Heroku | Free - $7/month | Easy setup | Limited free tier |
| Railway | Free - $5/month | Very easy | Limited resources |
| DigitalOcean | $6-12/month | Full control | Requires setup |
| AWS EC2 | Free tier - $10/month | Scalable | Complex setup |

---

## 📞 Support

Untuk masalah deployment:
1. Check server logs
2. Verify environment variables
3. Test database connection
4. Check firewall/security groups

Good luck with deployment! 🚀
