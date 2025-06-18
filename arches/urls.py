from django.conf import settings
from django.conf.urls.static import static
from django.conf.urls.i18n import i18n_patterns
from django.urls import include, path

# COPIED FROM ./arches_her/docker/aher_project/docker/urls.py

urlpatterns = [
    path('', include('arches.urls')),
   path("", include("arches_her.urls")),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

settings.SHOW_LANGUAGE_SWITCH = False