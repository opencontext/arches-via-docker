from __future__ import absolute_import, unicode_literals
import os
from celery import Celery

import platform

if platform.system().lower() == "windows":
    os.environ.setdefault("FORKED_BY_MULTIPROCESSING", "1")

def get_env_variable(var_name):
    msg = "Set the %s environment variable"
    try:
        return os.environ[var_name]
    except KeyError:
        error_msg = msg % var_name
        raise ValueError(error_msg)

ARCHES_PROJECT = get_env_variable("ARCHES_PROJECT")

os.environ.setdefault('DJANGO_SETTINGS_MODULE', f'{ARCHES_PROJECT}.settings')
app = Celery(f'{ARCHES_PROJECT}')
app.config_from_object('django.conf:settings', namespace='CELERY')
app.autodiscover_tasks()