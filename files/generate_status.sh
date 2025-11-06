#!/bin/bash
DB_HOST=${DB_HOST:-db}
DB_PORT=${DB_PORT:-5432}
ENV=${ENVIRONMENT:-unknown}

until pg_isready -h "$DB_HOST" -p "$DB_PORT" > /dev/null 2>&1; do
  echo "Waiting for DB at $DB_HOST:$DB_PORT..."
  sleep 2
done

DB_IP=$(getent hosts "$DB_HOST" | awk '{print $1}')

cat > /usr/share/nginx/html/index.html <<HTML
<!DOCTYPE html>
<html><head><title>$ENV Status</title></head><body>
<h1>Environment: $ENV</h1>
<p>Connected to: <strong>$DB_HOST ($DB_IP)</strong></p>
<p>Database: <strong>app_$ENV</strong></p>
<p>Status: <span style="color:green">Connected</span></p>
<hr><small>Generated: $(date)</small>
</body></html>
HTML
echo "Status page generated for $ENV"
