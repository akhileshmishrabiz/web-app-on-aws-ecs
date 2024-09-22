#!/bin/bash

# Start Gunicorn to serve the Flask application
gunicorn -w 4 -b 0.0.0.0:8080 app:app &

# Start Celery worker with logging to a file
celery -A app.celery worker --loglevel=info --logfile=celery.log &

# Wait for all background processes to finish
wait