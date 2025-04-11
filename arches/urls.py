from django.conf import settings
from django.conf.urls.static import static
from django.conf.urls.i18n import i18n_patterns
from django.urls import include, path, re_path
from afrc.views.file_api import FileAPI
from afrc.views.settings_api import SettingsAPI
from afrc.views.search_api import SearchAPI
from afrc.views.map_api import (
    MapDataAPI,
    FeatureBufferAPI,
    GeoJSONBoundsAPI,
    ReferenceCollectionMVT,
    ReferenceCollectionSearchMVT,
    ResourceBoundsAPI,
    ResourceGeoJSONAPI,
)
from afrc.views.rascoll_search import RascollSearchView

uuid_regex = settings.UUID_REGEX

urlpatterns = [
    # project-level urls
    path("api-search", SearchAPI.as_view(), name="api-search"),
    path("api-settings", SettingsAPI.as_view(), name="api-settings"),
    path("api-map-data", MapDataAPI.as_view(), name="api-map-data"),
    path("api-file-data", FileAPI.as_view(), name="api-file-data"),
    path("api-feature-buffer", FeatureBufferAPI.as_view(), name="api-feature-buffer"),
    path("api-geojson-bounds", GeoJSONBoundsAPI.as_view(), name="api-geojson-bounds"),
    re_path(
        "api-resource-bounds/(?P<resource_id>%s)$" % (uuid_regex),
        ResourceBoundsAPI.as_view(),
        name="api-resource-bounds",
    ),
    re_path(
        "api-resource-geojson/(?P<resource_id>%s)$" % (uuid_regex),
        ResourceGeoJSONAPI.as_view(),
        name="api-resource-geojson",
    ),
    re_path(
        r"^api-reference-collection-mvt/(?P<zoom>[0-9]+|\{z\})/(?P<x>[0-9]+|\{x\})/(?P<y>[0-9]+|\{y\}).pbf$",
        ReferenceCollectionMVT.as_view(),
        name="api-reference-collection-mvt",
    ),
    re_path(
        r"^api-reference-collection-search-mvt/(?P<zoom>[0-9]+|\{z\})/(?P<x>[0-9]+|\{x\})/(?P<y>[0-9]+|\{y\}).pbf$",
        ReferenceCollectionSearchMVT.as_view(),
        name="api-reference-collection-search-mvt",
    ),
    re_path(r"^rascoll-search$", RascollSearchView.as_view(), name="rascoll-search"),
]

# Ensure Arches core urls are superseded by project-level urls
urlpatterns.append(path("", include("arches.urls")))

# Adds URL pattern to serve media files during development
urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

# Only handle i18n routing in active project. This will still handle the routes provided by Arches core and Arches applications,
# but handling i18n routes in multiple places causes application errors.
if settings.ROOT_URLCONF == __name__:
    if settings.SHOW_LANGUAGE_SWITCH is True:
        urlpatterns = i18n_patterns(*urlpatterns)

    urlpatterns.append(path("i18n/", include("django.conf.urls.i18n")))


handler400 = "arches.app.views.main.custom_400"
handler403 = "arches.app.views.main.custom_403"
handler404 = "arches.app.views.main.custom_404"
handler500 = "arches.app.views.main.custom_500"