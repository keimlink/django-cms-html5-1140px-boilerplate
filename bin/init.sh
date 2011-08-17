#!/usr/bin/env bash

## Settings
SCM=git # SCM of the final project. Tested for 'git' and 'hg'
PYTHONVERSION=$(/usr/bin/env python --version 2>&1 | \
    sed 's/^Python\ \([0-9]\.[0-9]\).*$/\1/')
APP_DESTINATION="webapps"
PROJECT="testing"  # default name of the Django project
CLEANUP_AFTER=false

# Nothing has to be changed below this line.

## Set up
VIRTUAL_ENV=""  # clean variable, will be set on 'workon virtualenvname'
PLATTFORM=$(uname -s)

if [ ${PLATTFORM} = "Linux" ]; then
    SED="sed -i "
elif [ ${PLATTFORM} = "Darwin" ]; then
    SED="sed -i ''"
else
    echo -ne "\nSorry, your Operating System is not currently supported. Exit.\n\n"
    exit 1
fi

## Functions

function configure_2.1 () {
    PIP_REQUIREMENTS='config/requirements-2.1.txt'
    APP_TEMPLATE="webapp-templates/2.1"
}

function configure_2.2 () {
    PIP_REQUIREMENTS='config/requirements-2.2.txt'
    APP_TEMPLATE="webapp-templates/2.2"
}

function set_django_secret_key () {
# set DJANGO_SECRET_KEY to a random string of 50 char
MATRIX="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!@#$%^&*()_+=?><-"
    KEY_LENGTH="50"
    while [ "${n:=1}" -le "$KEY_LENGTH" ]; do
        DJANGO_SECRET_KEY="$DJANGO_SECRET_KEY${MATRIX:$(($RANDOM%${#MATRIX})):1}"
        n=$(($n+1))
        #let n+=1
    done
}

function help () {
cat << EOF
    Install Django-CMS, Modenizer and cssgrid into virtualenv.

    $0 [OPTIONS]

    -h  This help
    -v  Version of Django-CMS (2.1 or 2.2). Default is 2.1
    -e  Name of the virtualenv (If not given will be asked for on cmd line)
    -p  Project name (Can be different from the virtualenv if installed in the same virtualenv
        as other projects.
    -C  clean up installer files and just leave project and virtualenv files

    Example:
    $0 -v 2.2 -p testing -e venv
    will install Django-CMS 2.2 into the virtualenv venv and create a Django project named testing.

EOF
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

function check_if_virtualenv_exists () {
    while IFS='\n' read VE; do
        if [ "$VE" = "$VIRTUALENVNAME" ]; then
            echo -ne "\nVirtualenv: ->$VE<- already exists! Will be using it.\n"
            VIRTUALENV_EXISTS=true
            return
        fi
    done < <(lsvirtualenv)
}

function ask_for_virualenv_name () {
    echo "Enter a virtualenv name (required):"
    read VIRTUALENVNAME
    if [ "x$VIRTUALENVNAME" == "x" ]
      then
        echo -ne "\nThe name of the virtualenv cannot be empty!\nExiting.\n"
        exit 1
    fi
}

function create_static_folders () {
    echo "Creating static folders..."
    for FOLDER in static static/img static/css static/js; do
        [ -d "$APP_DESTINATION"/${CMS_VERSION}/"$FOLDER" ] || mkdir -p "$APP_DESTINATION"/${CMS_VERSION}/"$FOLDER"
    done
    touch "$APP_DESTINATION"/${CMS_VERSION}/static/css/styles.sass
}

function copy_html5-boilerplate () {
    echo "Copying the parts of html5-boilerplate that we need..."
    cp ./lib/html5-boilerplate/404.html "$APP_DESTINATION"/django/"$PROJECT"/templates/404.html
    cp ./lib/html5-boilerplate/apple-touch-icon* "$APP_DESTINATION"/${CMS_VERSION}/static/img/
    cp ./lib/html5-boilerplate/favicon.ico "$APP_DESTINATION"/${CMS_VERSION}/static/img/favicon.ico
    cp ./lib/html5-boilerplate/robots.txt "$APP_DESTINATION"/${CMS_VERSION}/static/robots.txt
    cp -r ./lib/html5-boilerplate/js "$APP_DESTINATION"/${CMS_VERSION}/static/
    cp -r ./lib/html5-boilerplate/css "$APP_DESTINATION"/${CMS_VERSION}/static/
}

function copy_1140px () {
    echo "Copying the parts of 1140px css grid that we need..."
    for FILE in 1140.css ie.css; do
        [ -f "$APP_DESTINATION"/static/css/"$FILE" ] || \
            cp lib/1140px/"$FILE" "$APP_DESTINATION"/${CMS_VERSION}/static/css/
    done
}

function split_up_html5_boilerplate_css () {
    echo "Splitting up html5-boilerplate css..."
    SPLIT=$(grep -n "/* Primary styles" "$APP_DESTINATION"/${CMS_VERSION}/static/css/style.css | awk -F":" '{ print $1 }')
    #SPLITHEAD=`expr $SPLIT - 1`
    SPLITHEAD=$(($SPLIT-1))
    SPLITTAIL=$(($SPLIT+3))
    head -n $SPLITHEAD "$APP_DESTINATION"/${CMS_VERSION}/static/css/style.css > "$APP_DESTINATION"/${CMS_VERSION}/static/css/boilerplate.css
    tail -n +$SPLITTAIL "$APP_DESTINATION"/${CMS_VERSION}/static/css/style.css > "$APP_DESTINATION"/${CMS_VERSION}/static/css/boilerplate_media.css
}

function cleanup_installer_test () {
    echo "Removing all the installer parts ..."

    return
}

function cleanup_installer () {
    rm -rf .git
    rm .gitignore
    rm .gitmodules
    rm README.rst
    rm "$APP_DESTINATION"/${CMS_VERSION}/static/css/style.css
    rm -rf "$APP_TEMPLATE"

    echo "Remove lib folder..."
    cp ./lib/.gitignore .
    rm -rf ./lib/
}

function symlink_modules_media () {
    echo "Creating symlinks..."
    mkdir -p "$APP_DESTINATION"/${CMS_VERSION}/media
    cd "$APP_DESTINATION"/${CMS_VERSION}/media
    [ x"$VIRTUAL_ENV" = "x" ] && { echo -ne "\nSomething strange happend. No virtualenv active. Exit.\n"; exit 1; }
    if [ ! -L cms ]; then
        # Need to find real place of module. Installing from repo will just create an egg link
        CMS_PATH=$(python -c "import os, cms; print os.path.dirname(os.path.abspath(cms.__file__))")
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
    cd $RUN_PATH
    STATIC_PATH="$(pwd)/${APP_DESTINATION}/${CMS_VERSION}/"
    cd "$APP_DESTINATION"/django/"$PROJECT"/
    mv local_settings.py.sample local_settings.py
    $SED -i '' "s#static_files_root#${STATIC_PATH}#" local_settings.py
    $SED -i '' "s#projecturls#${PROJECT}\.urls#" local_settings.py
    $SED -i ''  "s/projectsecretkey/${DJANGO_SECRET_KEY}/" local_settings.py
    #echo "ROOT_URLCONF = '$PROJECT.urls'" >> local_settings.py
    cd ../../..
}

function init_scm () {
    echo "Initiate a new scm repository in $APP_DESTINATION/django/$PROJECT/"
    cd "$APP_DESTINATION"/django/"$PROJECT"/
    $SCM init
    $SCM add .
    $SCM commit -m "Initial Commit"
}

function init_django_project () {
    python manage.py syncdb --noinput --migrate
    echo  $RUN_PATH/$APP_TEMPLATE/django/fixture/initial_auth_data.json
    python manage.py loaddata  $RUN_PATH/$APP_TEMPLATE/django/fixtures/initial_auth_data.json
    echo -ne "\nLoading admin:admin auth data. Do not forget to change e. g. via the /admin interface!\n\n"
    python manage.py collectstatic --noinput
}

# main()

if [ "x$1" == "x" ]; then
    help
    exit 1
fi
RUN_PATH=$(pwd)

while getopts "p:e:v:ahC" OPTIONS; do
  case ${OPTIONS} in
    h)  help
        exit 0
        ;;
    e)
        VIRTUALENVNAME=$OPTARG
        ;;
    v)
        CMS_VERSION="$OPTARG"
        ;;
    p)
        PROJECT="$OPTARG"
        ;;
    C)
        CLEANUP_AFTER=true
        ;;
    \?)
        echo "Invalid option: -$OPTARG" >&2
        exit 1
        ;;
  esac
done

[ "x" == "x$CMS_VERSION" ] && CMS_VERSION="2.1"

case ${CMS_VERSION} in
    2.1)
        configure_2.1
        ;;
    2.2)
        configure_2.2
        ;;
    *)
        echo "Django CMS version ${CMS_VERSION} not supported. Exit."
        exit 1
        ;;
esac


echo "Setting up a django-cms environment."

set_virtualenvwrapper
source $VENVWRAPPERSH
# ask_for_virtualenvwrapper
if [ "x" == "x$VIRTUALENVNAME" ]; then
    echo "Answer some questions before running the installation."
    ask_for_virualenv_name
fi
check_if_virtualenv_exists

if [ ! $VIRTUALENV_EXISTS ]; then
    echo "Creating virtualenv: $VIRTUALENVNAME"
    mkvirtualenv -p python"$PYTHONVERSION" "$VIRTUALENVNAME"
fi

workon $VIRTUALENVNAME
cd $RUN_PATH   #make sure we are on the right dir. Could be that the path is set by workon

echo "Installing all needed modules into a virtualenv"
pip install -r $PIP_REQUIREMENTS
[ $? -ne 0 ] && { echo -ne "\nProblem while installing dependencies via pip!\nExit.\n"; exit 1; }

echo "Updating git submodules..."
git submodule update --init --recursive

echo "Creating Web app folder: $APP_DESTINATION"
[ -d "$APP_DESTINATION/django/" ] || mkdir -p $APP_DESTINATION/django
cp -r "$APP_TEMPLATE"/django/project "$APP_DESTINATION"/django/
mv "$APP_DESTINATION"/django/project "$APP_DESTINATION"/django/"$PROJECT"

create_static_folders
copy_html5-boilerplate
copy_1140px
split_up_html5_boilerplate_css
symlink_modules_media
set_local_settings
init_scm


[ $CLEANUP_AFTER ] && cleanup_installer_test

init_django_project
#cd "$APP_DESTINATION"/django/"$PROJECT"
exit 0
./manage.py runserver

echo "We are ready to go..."
