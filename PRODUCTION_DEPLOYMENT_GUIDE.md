# Production Deployment Guide

## Overview
This guide provides comprehensive instructions for deploying the College Attendance Marker application to production with optimal performance for Android clients.

---

## Pre-Deployment Checklist

### Backend Configuration

- [ ] Set `SECRET_KEY` environment variable (use a strong random key)
  ```bash
  export SECRET_KEY=$(python -c "import secrets; print(secrets.token_urlsafe(32))")
  ```

- [ ] Configure `ALLOWED_ORIGINS` for CORS
  ```bash
  export ALLOWED_ORIGINS="https://yourdomain.com,https://app.yourdomain.com"
  ```

- [ ] Set `ENVIRONMENT` to production
  ```bash
  export ENVIRONMENT="production"
  ```

- [ ] Configure `TRUSTED_HOSTS` if using TrustedHostMiddleware
  ```bash
  export TRUSTED_HOSTS="yourdomain.com,api.yourdomain.com"
  ```

- [ ] Configure database URL (if not using SQLite)
  ```bash
  export DATABASE_URL="postgresql://user:password@localhost/dbname"
  ```

### Frontend Configuration

- [ ] Update network security config (`frontend/android/app/src/main/res/xml/network_security_config.xml`)
  - Remove or narrow CIDR range to production subnet only
  - Replace localhost IPs with actual server IP addresses
  - Or configure HTTPS and remove cleartext traffic permissions

- [ ] Enable screenshot protection (`frontend/android/app/src/main/kotlin/.../MainActivity.kt`)
  - Remove `window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)` calls
  - Remove `scheduleReclear()` calls
  - Or apply FLAG_SECURE conditionally based on screen content

- [ ] Update API endpoint in Flutter app
  - Replace development IP with production domain
  - Ensure HTTPS is used

---

## Performance Optimizations Applied

### Database Layer

1. **Connection Pooling** (database.py)
   - SQLite: StaticPool for thread safety
   - PostgreSQL/MySQL: Pool size 20, max overflow 40
   - Connection pre-ping enabled
   - Connection recycling after 1 hour

2. **SQLite WAL Mode** (database.py)
   - Write-Ahead Logging for better concurrency
   - Synchronous=NORMAL for performance
   - 10MB cache size
   - Memory-mapped I/O enabled

3. **Strategic Indexes** (models.py)
   - User: role, roll_no, name, section+year composite
   - LeaveRequest: student_id+status, status+created_at, date_range
   - AttendanceRecord: student_id+date (unique), date+status, marked_by
   - All indexes optimized for common query patterns

### Application Layer

1. **Request Timing Middleware** (main.py)
   - Tracks processing time for each request
   - Logs slow requests (>1 second)
   - Adds X-Process-Time header to responses

2. **Pagination** (routes/users.py, routes/attendance_routes/retrieval.py)
   - Default limit: 100 records
   - Maximum limit: 500 records
   - Prevents loading entire datasets

3. **Eager Loading** (all route files)
   - Uses selectinload() for relationships
   - Prevents N+1 query problems
   - Reduces database round trips

4. **Batch Operations** (routes/attendance_routes/holidays.py, marking.py)
   - Single commit after all updates
   - Bulk insert/update instead of per-record operations
   - Massive performance improvement for bulk operations

5. **File Upload Validation** (main.py)
   - 5MB size limit
   - Allowed extensions: jpg, jpeg, png, gif, webp
   - Prevents resource exhaustion

6. **Response Compression** (main.py)
   - GZip compression level 6
   - Minimum size 500 bytes
   - Reduces bandwidth for mobile clients

### Monitoring & Logging

1. **Structured Logging** (logging_config.py)
   - Console output for development
   - Rotating file logs (10MB max, 5 backups)
   - Separate error log file
   - Includes function names and line numbers

2. **Health Check Endpoint** (`GET /health`)
   - Checks database connectivity
   - Returns service status
   - Useful for load balancers and monitoring

3. **Error Tracking** (main.py)
   - Unhandled exceptions logged with stack traces
   - No sensitive data exposed to clients
   - Detailed logs for debugging

---

## Android Performance Tips

### Network Optimization

1. **Use HTTPS with HTTP/2**
   - Multiplexing reduces latency
   - Header compression saves bandwidth

2. **Implement Request Caching**
   - Cache user profile, attendance records
   - Use ETags for conditional requests

3. **Batch Requests**
   - Combine multiple API calls when possible
   - Use pagination parameters wisely

### App-Level Optimization

1. **Lazy Loading**
   - Load attendance records on demand
   - Implement infinite scroll

2. **Local Database**
   - Cache frequently accessed data
   - Sync with server in background

3. **Image Optimization**
   - Compress profile pictures before upload
   - Use appropriate image formats (WebP recommended)

---

## Deployment Steps

### 1. Backend Deployment

```bash
# Clone repository
git clone <repository-url>
cd college_attendance_marker

# Create virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies
cd backend
pip install -r requirements.txt

# Set environment variables
export SECRET_KEY="your-secret-key-here"
export ALLOWED_ORIGINS="https://yourdomain.com"
export ENVIRONMENT="production"

# Initialize database
python reset_and_seed_db.py  # Only for initial setup

# Run server with production settings
uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4
```

### 2. Frontend Deployment

```bash
cd frontend

# Update configuration files
# - network_security_config.xml
# - API endpoint URLs
# - Enable FLAG_SECURE

# Build release APK
flutter build apk --release

# Or build App Bundle
flutter build appbundle --release
```

### 3. Reverse Proxy (Nginx Example)

```nginx
server {
    listen 80;
    server_name api.yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.yourdomain.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # File upload size limit
    client_max_body_size 10M;
}
```

### 4. Systemd Service (Optional)

Create `/etc/systemd/system/attendance-api.service`:

```ini
[Unit]
Description=College Attendance Marker API
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/path/to/college_attendance_marker/backend
Environment="SECRET_KEY=your-secret-key"
Environment="ALLOWED_ORIGINS=https://yourdomain.com"
Environment="ENVIRONMENT=production"
ExecStart=/path/to/.venv/bin/uvicorn main:app --host 127.0.0.1 --port 8000 --workers 4
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl enable attendance-api
sudo systemctl start attendance-api
sudo systemctl status attendance-api
```

---

## Monitoring

### Log Files

- Application logs: `backend/logs/app.log`
- Error logs: `backend/logs/error.log`
- Nginx access logs: `/var/log/nginx/access.log`
- Nginx error logs: `/var/log/nginx/error.log`

### Performance Metrics

Monitor these metrics:

1. **Response Time**
   - Average response time < 200ms
   - 95th percentile < 500ms
   - 99th percentile < 1000ms

2. **Database Performance**
   - Query execution time
   - Connection pool usage
   - Cache hit rate

3. **Error Rates**
   - 4xx errors (client errors)
   - 5xx errors (server errors)
   - Failed authentication attempts

4. **Resource Usage**
   - CPU utilization
   - Memory usage
   - Disk I/O
   - Network bandwidth

---

## Security Checklist

- [ ] HTTPS enabled with valid SSL certificate
- [ ] SECRET_KEY is strong and random
- [ ] CORS properly configured (no wildcards)
- [ ] Rate limiting enabled on authentication
- [ ] File upload limits enforced
- [ ] Screenshot protection enabled (FLAG_SECURE)
- [ ] SQL injection prevention (using ORM)
- [ ] Input validation on all endpoints
- [ ] Error messages don't expose sensitive data
- [ ] Regular security updates applied

---

## Troubleshooting

### High Response Times

1. Check slow request logs in `backend/logs/app.log`
2. Analyze database query performance
3. Verify indexes are being used
4. Check network latency between client and server
5. Monitor resource usage (CPU, memory, disk)

### Database Locked Errors (SQLite)

1. Verify WAL mode is enabled
2. Increase timeout in database.py
3. Consider migrating to PostgreSQL for high concurrency

### Memory Issues

1. Reduce pagination limits
2. Implement result streaming for large datasets
3. Add memory limits to uvicorn workers
4. Monitor and optimize query patterns

### Authentication Issues

1. Check SECRET_KEY is consistent
2. Verify token expiration settings
3. Review rate limiting logs
4. Check CORS configuration

---

## Backup Strategy

### Database Backups

SQLite:
```bash
# Daily backup
sqlite3 college_attendance.db ".backup 'backup-$(date +%Y%m%d).db'"

# Compress
gzip backup-$(date +%Y%m%d).db
```

PostgreSQL:
```bash
# Daily backup
pg_dump -U user dbname | gzip > backup-$(date +%Y%m%d).sql.gz
```

### File Backups

```bash
# Backup uploaded files
tar -czf uploads-backup-$(date +%Y%m%d).tar.gz backend/static/uploads/
```

### Automated Backups

Add to crontab:
```bash
# Daily at 2 AM
0 2 * * * /path/to/backup-script.sh
```

---

## Scaling Considerations

### Horizontal Scaling

1. Use PostgreSQL or MySQL instead of SQLite
2. Shared file storage (NFS, S3) for uploads
3. Load balancer (Nginx, HAProxy)
4. Session management (Redis, database)

### Vertical Scaling

1. Increase uvicorn workers (1 per CPU core recommended)
2. Increase database connection pool size
3. Add more RAM for caching
4. Use faster storage (SSD)

---

## Support & Maintenance

### Regular Tasks

- [ ] Weekly: Review error logs
- [ ] Weekly: Check disk space
- [ ] Monthly: Update dependencies
- [ ] Monthly: Review performance metrics
- [ ] Quarterly: Security audit
- [ ] Quarterly: Database optimization

### Updates

```bash
# Update Python packages
pip install --upgrade -r requirements.txt

# Update Flutter dependencies
flutter pub upgrade

# Apply database migrations
# (if using Alembic or similar)
```

---

## Additional Resources

- FastAPI Documentation: https://fastapi.tiangolo.com/
- SQLAlchemy Documentation: https://docs.sqlalchemy.org/
- Flutter Documentation: https://flutter.dev/docs
- Nginx Documentation: https://nginx.org/en/docs/

---

## Contact & Support

For issues or questions:
- Check logs first
- Review this deployment guide
- Consult application documentation
- Contact development team

---

**Last Updated**: 2025-10-19
**Version**: 1.0.0
