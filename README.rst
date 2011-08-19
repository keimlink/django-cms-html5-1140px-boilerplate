Stop peeling. Start cooking!
============================

At bitmazk we create accessible and responsive websites. After nearly 10 years
of web development it turned out that a simple nginx / apache / django /
django-cms stack works best for us and our customers.

To streamline the process of setting up new projects for new customers we
created this boilerplate. This script should automatically setup your
virtual environment, initiate your database and collect your static files
all in one command (``init.sh``). Stop peeling. Start cooking!

Ingredients
===========

  - automated setup of your virtualenv
  - html5_ ready
  - based on django-cms_
  - ready for mobile browsers thanks to the 1140px-CSS-framework_
  - using django-compressor_ for combining, compressing and minifying static
    files
  - SASS_ support
  - ready for deployment at Webfaction_

Preparation
===========

You will need quite some tools such as
virtualenv_, virtualenvwrapper_, csstidy_, sass_ and some more. Have a
look at our bitmazk-environment_ for a full list of tools and libraries needed.

*IMPORTANT:* Be very sure that you have virtualenvwrapper installed properly.
We added a check for virtualenvwrapper.sh but who knows, maybe you get around
that - and without virtualenvwrapper this script might pollute your global
python environment with unwanted modules.

Recipe
======

  - Clone this repository,
  - initiate the project

::

  git clone git://github.com/bitmazk/django-cms-html5-1140px-boilerplate.git yourproject
  cd yourproject
  ./bin/init.sh

That's it!

HTML5 Boilerplate and SASS
==========================
We are standing on the shoulders of giants and use the awesome
html5-boilerplate_ as a submodule.

Usually the main .css file that comes with the html5-boilerplate has a part
somewhere in the middle of the file where your very own styles should go.
In order to be able to define these styles with SASS ``initproject.sh`` slices
that main .css file into two pieces. Now you can define your own styles in a
.sass file and let django-compressor take care of combining and compressing
everything.

Unfortunately we have to inject quite some django specific code into the
``index.html`` that comes with the html5-boilerplate. Therefore this repo ships
with its own ``base.html`` and we don't ever touch the html5-boilerplate's
``index.html``. Maybe this can be automated in the future so that our
``base.html`` will be generated out of ``index.html`` but for now be warned:
Our ``base.html`` might not reflect latest and important changes to the
html5-boilerplate's ``index.html``. We will try to monitor changes there and add
them to our ``base.html`` manually but we are just humans. And we are damn busy.
So you better check it yourself as well.

If you find our ``base.html`` horribly outdated, please create an issue and we
will take care quickly.

Hosting at Webfaction
=====================

You might wonder about the folder structure of this project. We chose this
structure because it reflects the structure on our hosted webservers at our
awesome webhost Webfaction_.

We usually have two static apps for serving static and media files plus one
django app for serving the django application. A deployment script on the
server checks out the repository and copies everything to its destination via
rsync.

For a complete boilerplate script to hosting your django-cms project at
Webfaction, see our `webfaction-django-cms-boilerplate
<https://github.com/bitmazk/webfaction-django-cms-boilerplate>`_

License
=======

`The Unlicense <http://unlicense.org>`_

.. _django-cms: https://github.com/divio/django-cms
.. _django-compressor: https://github.com/mintchaos/django_compressor
.. _SASS: http://sass-lang.com/
.. _Webfaction: http://www.webfaction.com
.. _virtualenv: http://pypi.python.org/pypi/virtualenv/
.. _virtualenvwrapper: http://pypi.python.org/pypi/virtualenv/
.. _csstidy: http://csstidy.sourceforge.net/
.. _sass: http://sass-lang.com/
.. _bitmazk-environment: https://github.com/bitmazk/bitmazk-environment
.. _html5-boilerplate: https://github.com/paulirish/html5-boilerplate
.. _html5: https://github.com/paulirish/html5-boilerplate
.. _1140px-CSS-framework: http://cssgrid.net/
