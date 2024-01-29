import os
from django.core.exceptions import ImproperlyConfigured
import ast


def get_env_variable(var_name):
    msg = "Set the %s environment variable"
    try:
        return os.environ[var_name]
    except KeyError:
        error_msg = msg % var_name
        raise ImproperlyConfigured(error_msg)


def get_optional_env_variable(var_name):
    try:
        return os.environ[var_name]
    except KeyError:
        return None


# options are either "PROD" or "DEV"
# (installing with Dev mode set gets you extra dependencies)
MODE = get_env_variable("DJANGO_MODE")

DEBUG = ast.literal_eval(get_env_variable("DJANGO_DEBUG"))

DATABASES = {
    "default": {
        "ENGINE": "django.contrib.gis.db.backends.postgis",
        "NAME": get_env_variable("PGDBNAME"),
        "USER": get_env_variable("PGUSERNAME"),
        "PASSWORD": get_env_variable("PGPASSWORD"),
        "HOST": get_env_variable("PGHOST"),
        "PORT": get_env_variable("PGPORT"),
        "POSTGIS_TEMPLATE": "template_postgis",
    }
}

ARCHES_NAMESPACE_FOR_DATA_EXPORT = get_env_variable("ARCHES_NAMESPACE")

"""
Since we're using Docker, we can use Redis (even on a Windows OS). So, we
will comment out the RabbitMQ connection in favor of a Redis connection.

CELERY_BROKER_URL = "amqp://{}:{}@arches_rabbitmq:5672".format(
    get_env_variable("RABBITMQ_USER"), get_env_variable("RABBITMQ_PASS")
)
"""

CELERY_BROKER_URL = "redis://@arches_redis:6379/0"

# NOTE: If you want to disable celery and workers, leave a blank string fo
# the CELERY_BROKER_URL as follows:
#
# CELERY_BROKER_URL = ""

# CANTALOUPE_HTTP_ENDPOINT = "http://{}:{}".format(get_env_variable("CANTALOUPE_HOST"), get_env_variable("CANTALOUPE_PORT"))
ELASTICSEARCH_HTTP_PORT = get_env_variable("ESPORT")
ELASTICSEARCH_HOSTS = [{"scheme": "http", "host": get_env_variable("ESHOST"), "port": int(ELASTICSEARCH_HTTP_PORT)}]

USER_ELASTICSEARCH_PREFIX = get_optional_env_variable("ELASTICSEARCH_PREFIX")
if USER_ELASTICSEARCH_PREFIX:
    ELASTICSEARCH_PREFIX = USER_ELASTICSEARCH_PREFIX

ALLOWED_HOSTS = get_env_variable("DOMAIN_NAMES").split() + ['*']

# Use the first allowed host as a trusted CSRF origin
CSRF_TRUSTED_ORIGINS = [f"https://{ALLOWED_HOSTS[0]}", f"https://www.{ALLOWED_HOSTS[0]}"]


USER_SECRET_KEY = get_optional_env_variable("DJANGO_SECRET_KEY")
if USER_SECRET_KEY:
    # Make this unique, and don't share it with anybody.
    SECRET_KEY = USER_SECRET_KEY

STATIC_ROOT = "/static_root"

LANGUAGE_CODE = 'en'
# Added for v7 internationalization demo
LANGUAGES = [
    ('en', ('English')),
    ('ar', ('Arabic')),
    ('he', ('Hebrew')),
]
# This will be true for this deployment
SHOW_LANGUAGE_SWITCH = len(LANGUAGES) > 1