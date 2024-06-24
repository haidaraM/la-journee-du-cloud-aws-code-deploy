FROM --platform=linux/amd64 python:3.12-alpine3.19

# SET ENV
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# set work directory
WORKDIR /app

# By copying over requirements first, we make sure that Docker will cache
# our installed requirements rather than reinstall them on every build
COPY requirements.txt .
RUN pip install -r requirements.txt

# copy project
COPY . .

# On ECS, we will use gunicorn instead of Django's built-in server (this will be overiden)
CMD ["/bin/sh", "-c", "python manage.py runserver 0.0.0.0:${APP_PORT}"]
