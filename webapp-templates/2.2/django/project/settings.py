import os
from local_settings import *

gettext = lambda s: s

# Absolute path to the directory that holds media.
# Example: "/home/media/media.lawrence.com/"
STATIC_ROOT = STATIC_FILES_ROOT + STATIC_APP_NAME + '/'
MEDIA_ROOT = STATIC_FILES_ROOT + MEDIA_APP_NAME + '/'

# URL that handles the media served from MEDIA_ROOT. Make sure to use a
# trailing slash if there is a path component (optional in other cases).
# Examples: "http://media.lawrence.com", "http://example.com/media/"
STATIC_URL = '/static/'
MEDIA_URL = '/media/'

# URL prefix for admin media -- CSS, JavaScript and images. Make sure to use a
# trailing slash.
# Examples: "http://foo.com/media/", "/media/".
ADMIN_MEDIA_PREFIX = '/static/admin/'

ROOT_URLCONF = ".".join([BASEDIR.split(os.sep)[-1], "urls"])

TEMPLATE_DIRS = (
    # Put strings here, like "/home/html/django_templates" or "C:/www/django/templates".
    # Always use forward slashes, even on Windows.
    # Don't forget to use absolute paths, not relative paths.
    #PROJECT_ROOT + APP_NAME + '/templates'
    BASEDIR + '/templates',
)

# Django settings for project.
SEND_BROKEN_LINK_EMAILS = True
IGNORABLE_404_STARTS = ('/static/cms/wymeditor/lang/',)

# Local time zone for this installation. Choices can be found here:
# http://en.wikipedia.org/wiki/List_of_tz_zones_by_name
# although not all choices may be available on all operating systems.
# If running in a Windows environment this must be set to the same as your
# system time zone.
TIME_ZONE = 'Europe/Berlin'

# Language code for this installation. All choices can be found here:
# http://www.i18nguy.com/unicode/language-identifiers.html
LANGUAGE_CODE = 'de-DE'

LANGUAGES = (
    ('de', gettext('German')),
)

SITE_ID = 1

# If you set this to False, Django will make some optimizations so as not
# to load the internationalization machinery.
USE_I18N = True

# List of callables that know how to import templates from various sources.
TEMPLATE_LOADERS = (
    'django.template.loaders.filesystem.load_template_source',
    'django.template.loaders.app_directories.load_template_source',
    'django.template.loaders.eggs.load_template_source',
)

TEMPLATE_CONTEXT_PROCESSORS = (
    'django.core.context_processors.auth',
    'django.core.context_processors.request',
    'django.core.context_processors.media',
    'django.core.context_processors.static',
    'cms.context_processors.media',
    'django.core.context_processors.i18n',
    'sekizai.context_processors.sekizai',
)

MIDDLEWARE_CLASSES = (
    #'django.middleware.cache.UpdateCacheMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    #'cms.middleware.multilingual.MultilingualURLMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.middleware.common.CommonMiddleware',
    'cms.middleware.page.CurrentPageMiddleware',
    'cms.middleware.user.CurrentUserMiddleware',
    #'cms.middleware.media.PlaceholderMediaMiddleware',
    #'django.middleware.cache.FetchFromCacheMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'cms.middleware.toolbar.ToolbarMiddleware',
)

THUMBNAIL_PROCESSORS = (
    'easy_thumbnails.processors.colorspace',
    'easy_thumbnails.processors.autocrop',
    #'easy_thumbnails.processors.scale_and_crop',
    'filer.thumbnail_processors.scale_and_crop_with_subject_location',
    'easy_thumbnails.processors.filters',
)

STATICFILES_FINDERS = (
    'django.contrib.staticfiles.finders.FileSystemFinder',
    'django.contrib.staticfiles.finders.AppDirectoriesFinder',
    'compressor.finders.CompressorFinder',
)

CMS_TEMPLATES = (
    ('base.html', gettext('index')),
)
CMS_SEO_FIELDS = True
COMPRESS_PRECOMPILERS = (
    ('text/x-sass', 'sass {infile} {outfile}'),
)
COMPRESS_CSS_FILTERS = ['compressor.filters.csstidy.CSSTidyFilter',]

INSTALLED_APPS = (
    # Django related apps
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.sites',
    'django.contrib.admin',
    'django.contrib.staticfiles',
    # django-cms related apps
    'cms',
    'cms.plugins.text',
    'cms.plugins.picture',
    'cms.plugins.link',
    'cms.plugins.file',
    'cms.plugins.snippet',
    'cms.plugins.googlemap',
    'cms.plugins.inherit',
    'mptt',
    'sekizai',
    'publisher',
    'menus',
    # useful 3rd party apps
    'compressor',
    'easy_thumbnails',
    'filer',
    'south',
    # your own apps
)


if DEBUG:
    import traceback
    import logging

    # Define a class that logs unhandled errors
    class LogUncatchedErrors:
        def process_exception(self, request, exception):
            logging.error("Unhandled Exception on request for %s\n%s" %
                                 (request.build_absolute_uri(),
                                  traceback.format_exc()))
    # And add it to the middleware classes
    MIDDLEWARE_CLASSES += ('settings.LogUncatchedErrors',)

    # set shown level of logging output to debug
    logging.basicConfig(level=logging.DEBUG)
