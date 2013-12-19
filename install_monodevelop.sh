#!/bin/bash
SCRIPTPATH=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)
source $SCRIPTPATH/mono-env.sh

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

__MONODEVELOP_CLEAN=$1

function die(){
 echo $1
 exit 1
}

update(){
    local repo=$1
    local branch=$3

    if [ -z "$branch" ]; then
        branch="master"
    fi
    
    if [ ! -d .git ]; then
        return 0
    fi
    git fetch origin

    if [ "$(git rev-list --count $branch..origin/$branch)" == "0" ]; then
        return 0
    fi

    echo -ne "\e]2;Updating $repo\a"
    
    git stash -u
    git checkout $branch
    git reset --hard origin/$branch
    git submodule update
}

install(){
    echo "Installing $1 $3"
    local repo=$1
    local branch=$3

    if [ -z "$branch" ]; then
        branch="master"
    fi

    if [[ ! -d $repo ]]; then
        echo -ne "\e]2;Cloning $repo\a"
        git clone --recursive git://github.com/mono/$repo.git -b $branch || die "failed to clone $repo"
        cd $repo || die "failed to enter $repo"
    else
        cd $repo || die "failed to enter $repo"
        update $@
    fi

    local installed="installed.txt"

    if [ "$__MONODEVELOP_CLEAN" == "clean" ]; then
        echo -ne "\e]2;Cleaning $repo\a"
        if [ -d .git ]; then
            git clean -dfx
        else
            make clean
            rm $installed
        fi
    fi

    local INSTALLED_SH1=$(cat $installed)
    local CURRENT_SH1=$(git rev-parse HEAD)

    if [ ! -f $installed ] || ([ -d .git ] && [ "$INSTALLED_SH1" != "$CURRENT_SH1" ]); then

        local baseConf
        if [[ -a "autogen.sh" ]]; then
            baseConf="autogen.sh"
        else
            baseConf="configure"
        fi

        local configure
        if [[ $# -eq 1 ]]; then
            configure=$baseConf
        else
            configure=$2
        fi
    
        echo -ne "\e]2;Configuring $repo\a"
        ./$configure --prefix=$MONO_PREFIX
        local configured=$?
        if [[ ! $configured ]]; then
            cp config.log ../$repo.config.log
            die "failed to configure $repo"
        fi

        echo -ne "\e]2;Making $repo\a"
        make || die "failed to make $repo"
        echo -ne "\e]2;Installing $repo\a"
        make install || die "failed to install $repo"
        if [ -d .git ]; then
            git rev-parse HEAD > $installed
        else
            echo $(date) > $installed
        fi
    fi

    cd - || die "failed to exit $repo"
}

# Installing common dependencies

apt-get install --yes git
apt-get install --yes automake libtool

# Installing libgdiplus
apt-get install --yes libglib2.0-dev libpng-dev libgif-dev libjpeg-dev libtiff-dev libfontconfig1-dev libcairo2-dev libexif-dev
install libgdiplus
# -----

# Installing mono
apt-get install --yes g++ mono-gmcs
install mono
# -----

# Installing gtk-sharp 3
apt-get install --yes libpango1.0-dev libatk1.0-dev libgtk-3-dev
install gtk-sharp
# -----

# Installing gtk-sharp-2.12
apt-get install --yes libgtk2.0-dev libglade2-dev
git clone --recursive gtk-sharp -b gtk-sharp-2-12-branch gtk-sharp-2-12
install gtk-sharp-2-12 bootstrap-2.12 gtk-sharp-2-12-branch
# -----

# Installing gnome-sharp
apt-get install --yes libart-2.0 libgnomevfs2-dev libgnomecanvas2-dev libgnomeui-dev
install gnome-sharp bootstrap-2.24
# -----

# Installing gnome-desktop-sharp
#Missing: libnautilus-burn-dev libpanelapplet-2.0
apt-get install --yes libgnome-desktop-dev librsvg2-dev libgnomeprint2.2-dev libgnomeprintui2.2-dev libgtkhtml3.14-dev libgtksourceview2.0-dev libvte-dev libwnck-dev
install gnome-desktop-sharp
# -----

# Installing mono-tools - ./browser.cs(63,19): error CS0117: `Monodoc.RootTree' does not contain a definition for `UncompiledHelpSources'
#Missing features: gecko-sharp-2.0, webkit-sharp-1.0
#install mono-tools
# -----

# Installing mono-addins - /bin/bash: line 2: xbuild: command not found
#Missing features: unit tests, documentation
#install mono-addins
# -----

# Installing debugger
install debugger
# -----

# Installing monodoc? repository non-existent
#install monodoc?
# -----

# Installing monodevelop
#Missing features: unit tests
install monodevelop
# -----

# Installing webkit-sharp (Optional)
apt-get install --yes libwebkit-dev
install webkit-sharp

# Installing uia2atk
#apt-get install --yes intltool
#git clone --recursive git://github.com/mono/uia2atk.git || die "failed to clone uia2atk"
#install uia2atk/UIAutomation
#install uia2atk/UIAutomationWinforms

echo "[Desktop Entry]
Encoding=UTF-8
Version=1.0
Type=Application
Terminal=false
Exec=$SCRIPTPATH/run_monodevelop.sh
Name=MonoDevelop
Icon=$SCRIPTPATH/monodevelop/main/theme-icons/Mac/png/128x128/monodevelop.png" > monodevelop.desktop
chmod +x monodevelop.desktop

echo -ne "\e]2;Build completed\a"

# Result: MonoDevelop 4.0, without glade-sharp.dll
