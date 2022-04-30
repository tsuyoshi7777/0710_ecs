from django.urls import path
from .views import views
from .views.scraping import db_scraping

urlpatterns = [
    path("", views.SampleTemplateView.as_view(), name="sample"),
    path("db_list/", views.db_list, name="db_list"),
    path('db_scraping/', db_scraping.db_scraping, name='db_scraping'),
]
