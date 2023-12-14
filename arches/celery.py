from __future__ import absolute_import, unicode_literals
import os
from celery import Celery

ARCHES_PROJECT = os.getenv('ARCHES_PROJECT')

os.environ.setdefault('DJANGO_SETTINGS_MODULE', f'{ARCHES_PROJECT}.settings')
app = Celery(ARCHES_PROJECT)
app.config_from_object('django.conf:settings', namespace='CELERY')
app.autodiscover_tasks()