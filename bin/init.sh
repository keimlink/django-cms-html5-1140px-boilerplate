#!/usr/bin/env bash

## Settings
SCM=git # SCM of the final project. Tested for 'git' and 'hg'
PYTHONVERSION=$(/usr/bin/env python --version 2>&1 | \
    sed 's/^Python\ \([0-9]\.[0-9]\).*$/\1/')
PIP_REQUIREMENTS='config/requirements-devel.txt'
APP_TEMPLATE="webapp-templates"
APP_DESTINATION="webapps"

# Nothing has to be changed below this line.

## Set up
VIRTUAL_ENV=""  # clean variable, will be set on 'workon virtualenvname'

## Functions
function set_django_secret_key () {
# set DJANGO_SECRET_KEY to a random string of 50 char
MATRIX="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!@#$%^&*()_+=?></\-"
    KEY_LENGTH="50"
    while [ "${n:=1}" -le "$KEY_LENGTH" ]; do
        DJANGO_SECRET_KEY="$DJANGO_SECRET_KEY${MATRIX:$(($RANDOM%${#MATRIX})):1}"
        n=$(($n+1))
        #let n+=1
    done
}

function ask_for_virtualenvwrapper () {
    echo "Leave empty to use the found one: "
    read VENVWRAPPERSH_INPUT
    if [ "x$VENVWRAPPERSH_INPUT" != "x" ]
    then
        venvwrappersh=$VENVWRAPPERSH_INPUT
    fi
}

function set_virtualenvwrapper () {
    echo -ne "\nLooking for virtualenvwrapper.sh?\n"
    VENVWRAPPERSH=$(which virtualenvwrapper.sh)
    [ $? -ne 0 ] && VENVWRAPPERSH="not found"

    echo "Found it on: $VENVWRAPPERSH"

    if [ ! -f $VENVWRAPPERSH ]
      then
        echo "ERROR: File $VENVWRAPPERSH does not exist..."
        exit 1
    fi
}

function ask_for_virualenv_name () {
    echo "Enter a virtualenv name (required):"
    read VIRTUALENVNAME
    if [ "x$VIRTUALENVNAME" == "x" ]
      then
        echo -ne "\nThe name of the virtualenv cannot be empty!\nExiting.\n"
        exit 1
    fi
    while IFS='\n' read VE; do
        if [ "$VE" = "$VIRTUALENVNAME" ]; then
            echo -ne "\nVirtualenv: ->$VE<- already exists! Will be using it.\n"
            VIRTUALENV_EXISTS=true
            return
        fi
    done < <(lsvirtualenv)
}

function create_static_folders () {
    echo "Creating static folders..."
    for FOLDER in static static/img static/css static/js; do
        [ -d "$APP_DESTINATION"/"$FOLDER" ] || mkdir "$APP_DESTINATION"/"$FOLDER"
    done
    touch "$APP_DESTINATION"/static/css/styles.sass
}

function copy_html5-boilerplate () {
    echo "Copying the parts of html5-boilerplate that we need..."
    cp ./lib/html5-boilerplate/404.html "$APP_DESTINATION"/django/project/templates/404.html
    cp ./lib/html5-boilerplate/apple-touch-icon* "$APP_DESTINATION"/static/img/
    cp ./lib/html5-boilerplate/favicon.ico "$APP_DESTINATION"/static/img/favicon.ico
    cp ./lib/html5-boilerplate/robots.txt "$APP_DESTINATION"/static/robots.txt
    cp -r ./lib/html5-boilerplate/js "$APP_DESTINATION"/static/
    cp -r ./lib/html5-boilerplate/css "$APP_DESTINATION"/static/
}

function copy_1140px () {
    echo "Copying the parts of 1140px css grid that we need..."
    for FILE in 1140.css ie.css; do
        [ -f "$APP_DESTINATION"/static/css/"$FILE" ] || \
            cp lib/1140px/"$FILE" "$APP_DESTINATION"/static/css/
    done
}

function split_up_html5_boilerplate_css () {
    echo "Splitting up html5-boilerplate css..."
    SPLIT=$(grep -n "/* Primary styles" "$APP_DESTINATION"/static/css/style.css | awk -F":" '{ print $1 }')
    #SPLITHEAD=`expr $SPLIT - 1`
    SPLITHEAD=$(($SPLIT-1))
    SPLITTAIL=$(($SPLIT+3))
    head -n $SPLITHEAD "$APP_DESTINATION"/static/css/style.css > "$APP_DESTINATION"/static/css/boilerplate.css
    tail -n +$SPLITTAIL "$APP_DESTINATION"/static/css/style.css > "$APP_DESTINATION"/static/css/boilerplate_media.css
}

function cleanup_installer () {
    echo "Removing all the installer parts ..."
    rm -rf .git
    rm .gitignore
    rm .gitmodules
    rm README.rst
    rm "$APP_DESTINATION"/static/css/style.css
    rm -rf "$APP_TEMPLATE"

    echo "Remove lib folder..."
    cp ./lib/.gitignore .
    rm -rf ./lib/
}

function symlink_modules_media () {
    echo "Creating symlinks..."
    mkdir -p "$APP_DESTINATION"/media
    cd "$APP_DESTINATION"/media
    [ x"$VIRTUAL_ENV" = "x" ] && { echo -ne "\nSomething strange happend. No virtualenv active. Exit.\n"; exit 1; }
    if [ ! -L cms ]; then
        # Need to find real place of module. Installing from repo will just create an egg link
        CMS_PATH=$(python -c "import os, cms; print os.path.dirname(os.path.abspath(cms.__file__))")
        echo $CMS_PATH
        # try to find the media link. Changed w/ 2.2 using django.contrib.staticfiles
        if [ -d "$CMS_PATH"/media/cms ]; then
            ln -s "$CMS_PATH"/media/cms .
        elif [ -d "$CMS_PATH"/static/cms ]; then
            # link it for backward compatibility
            ln -s "$CMS_PATH"/static/cms .
        else
            echo "django-cms media/static files not found. Probably, that's bad."
        fi
    else
        echo "Sym link to cms/media/cms alredy exists in $APP_DESTINATION/media. I do not overwrite it."
    fi
    if [ ! -L filer ]; then
        ln -s $(python -c "import os, filer; print os.path.dirname(os.path.abspath(filer.__file__))")/media/filer .
    else
        echo "Sym link to filer/media/filer alredy exists in $APP_DESTINATION/media. I do not overwrite it."
    fi
    cd ../..
}

function set_local_settings () {
    echo "Adjusting local_settings.py ..."
    set_django_secret_key
    cd "$APP_DESTINATION"/django/project/
    cp local_settings.py.sample local_settings.py
    sed -i '' "s#projectroot#$(pwd)/#" local_settings.py
    sed -i ''  "s/^SECRET_KEY\ =.*$/SECRET_KEY\ =\ \"${DJANGO_SECRET_KEY}\"/" local_settings.py
    cd ../../..
}

# main()
echo "Setting up a new django-cms development environment."
echo "Answer some questions before running the installation."

set_virtualenvwrapper
source $VENVWRAPPERSH
# ask_for_virtualenvwrapper
ask_for_virualenv_name

if [ ! $VIRTUALENV_EXISTS ]; then
    echo "Creating virtualenv: $VIRTUALENVNAME"
    mkvirtualenv -p python"$PYTHONVERSION" "$VIRTUALENVNAME"
fi

workon $VIRTUALENVNAME

echo "Installing all needed modules into a virtualenv"
#pip install -r $PIP_REQUIREMENTS
#[ $? -ne 0 ] && { echo -ne "\nProblem while installing dependencies via pip!\nExit.\n"; exit 1; }

echo "Updating git submodules..."
#git submodule update --init --recursive

echo "Creating Project folder: $APP_DESTINATION"
[ -d "$APP_DESTINATION" ] || mkdir $APP_DESTINATION
cp -r "$APP_TEMPLATE"/* "$APP_DESTINATION"/

create_static_folders
copy_html5-boilerplate
copy_1140px
split_up_html5_boilerplate_css
symlink_modules_media
set_local_settings

exit 0

#cleanup_installer

echo "Initiate a new scm repository..."
$SCM init
$SCM add .
$SCM commit -m "Initial Commit"

# FIXME a8 next line not required
# workon $virtualenvname
cd "$APP_DESTINATION"/django/project
./manage.py syncdb --migrate
./manage.py collectstatic --noinput -l
./manage.py runserver

echo "We are ready to go..."
