from django.urls import include, path
from django.conf import settings
from django.conf.urls.static import static
# from django.conf.urls.i18n import i18n_patterns

urlpatterns = [
   path("", include("arches.urls")),
   path("", include("arches_her.urls")),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

# The language URL patterns with i18n_patterns seem a little buggy,
# so they are disabled with the "if False..." below. Remove
# the False if you want to try to use this feature.
if False and settings.SHOW_LANGUAGE_SWITCH is True:
    urlpatterns = i18n_patterns(*urlpatterns)
