#!/usr/bin/env ash

set -e
set -x

echo "Collecting static files..."
python manage.py collectstatic --noinput -v 3

echo "Migrating database..."
python manage.py migrate

echo "Done!"