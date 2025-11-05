#!/bin/bash
set -e

# Set PYTHONPATH
export PYTHONPATH=/app

echo "Waiting for database to be ready..."
python << EOF
import sys
import time
import os

max_retries = 30
retry_count = 0

while retry_count < max_retries:
    try:
        db_url = os.getenv('DATABASE_URL', '')
        if 'postgresql' in db_url or 'postgres' in db_url:
            import psycopg2
            import urllib.parse
            parsed = urllib.parse.urlparse(db_url)
            conn = psycopg2.connect(
                host=parsed.hostname,
                port=parsed.port or 5432,
                user=parsed.username,
                password=parsed.password,
                database=parsed.path[1:] if parsed.path else 'postgres',
                connect_timeout=5
            )
            conn.close()
            print('Database is ready!')
            break
        else:
            print('SQLite database - no connection check needed')
            break
    except Exception as e:
        retry_count += 1
        if retry_count >= max_retries:
            print(f'Database connection failed after {max_retries} retries: {e}')
            sys.exit(1)
        print(f'Waiting for database... ({retry_count}/{max_retries})')
        time.sleep(2)
EOF

echo "Initializing database..."
cd /app
python scripts/init_database.py

echo "Starting backend API..."
exec "$@"

