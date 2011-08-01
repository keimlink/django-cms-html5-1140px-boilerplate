#!/usr/bin/env bash

## Settings
SCM=hg # SCM of the final project. Tested for 'git' and 'hg'
PYTHONVERSION=$(/usr/bin/env python --version 2>&1 | \
    sed 's/^Python\ \([0-9]\.[0-9]\).*$/\1/')


# main()
echo "Setting up a new django-cms development environment."
echo "Answer some questions before running the installation."

echo -ne "\nWhat is the path to your virtualenvwrapper.sh?\n"
venvwrappersh=$(which virtualenvwrapper.sh)
[ $? -ne 0 ] && venvwrappersh="not found"

echo "Found it on: $venvwrappersh"
echo "Leave empty to use the found one: "
read venvwrappersh_input
if [ "x$venvwrappersh_input" != "x" ]
  then
    venvwrappersh=$venvwrappersh_input
fi
if [ ! -f $venvwrappersh ]
  then
    echo "ERROR: File $venvwrappersh does not exist..."
    exit 1
fi

echo "Enter a virtualenv name (required):"
read virtualenvname
if [ "x$virtualenvname" == "x" ]
  then
    echo -ne "\nThe name of the virtualenv cannot be empty!\nExiting.\n"
    exit 1
fi

source $venvwrappersh
echo "Installing all needed modules into a virtualenv"
mkvirtualenv -p python$PYTHONVERSION $virtualenvname
workon $virtualenvname
pip install -r bin/requirements.txt

echo "Updating git submodules..."
git submodule update --init --recursive

echo "Creating static folders..."
for folder in "./webapps/static ./webapps/static/img ./webapps/static/css ./webapps/static/js"; do
    mkdir $folder
done
touch ./webapps/static/css/styles.sass

echo "Copying the parts of html5-boilerplate that we need..."
cp ./lib/html5-boilerplate/404.html ./webapps/django/project/templates/404.html
cp ./lib/html5-boilerplate/apple-touch-icon* ./webapps/static/img/
cp ./lib/html5-boilerplate/favicon.ico ./webapps/static/img/favicon.ico
cp ./lib/html5-boilerplate/robots.txt ./webapps/static/robots.txt
cp -r ./lib/html5-boilerplate/js ./webapps/static/
cp -r ./lib/html5-boilerplate/css ./webapps/static/

echo "Copying the parts of 1140px css grid that we need..."
cp ./lib/1140px/1140.css ./webapps/static/css/1140.css
cp ./lib/1140px/ie.css ./webapps/static/css/ie.css

echo "Splitting up html5-boilerplate css..."
SPLIT=`grep -n "/* Primary Styles" ./webapps/static/css/style.css | awk -F":" '{ print $1 }'`
SPLITHEAD=`expr $SPLIT - 1`
SPLITTAIL=`expr $SPLIT + 3`
head --lines=$SPLITHEAD ./webapps/static/css/style.css > ./webapps/static/css/boilerplate.css
tail -n +$SPLITTAIL ./webapps/static/css/style.css > ./webapps/static/css/boilerplate_media.css

echo "Removing the parts we dont want..."
rm -rf .git
rm .gitignore
rm .gitmodules
rm README.rst
rm ./webapps/static/css/style.css

echo "Creating symlinks..."
mkdir -p ./webapps/media
cd ./webapps/media
echo "What is the name of your virtualenv: "
ln -s $VIRTUAL_ENV/lib/python$PYTHONVERSION/site-packages/cms/media/cms
ln -s $VIRTUAL_ENV/lib/python$PYTHONVERSION/site-packages/filer/media/filer
cd ../..

echo "Creating local_settings.py ..."
cd ./webapps/django/project/
cp local_settings.py.sample local_settings.py
cd ../../..
sed -i s@projectroot@$(pwd)/@g webapps/django/project/local_settings.py

echo "Remove lib folder..."
cp ./lib/.gitignore .
rm -rf ./lib/

echo "Initiate a new git project..."
$SCM init
$SCM add .
$SCM commit -m "Initial Commit"

# FIXME a8 next line not required
# workon $virtualenvname
cd webapps/django/project
./manage.py syncdb --migrate
./manage.py collectstatic
./manage.py runserver

echo "Don't forget to change your secret key in your local_settings.py"
