#!/bin/bash
source mono-env.sh

function die(){
 echo $1
 exit 1
}

install(){
	local repo=$1
	if [[ ! -d $repo ]]; then
		git clone --recursive git://github.com/mono/$repo.git || die "failed to clone $repo"
	fi
	cd $repo || die "failed to enter $repo"

	local installed="installed.txt"
	if [[ ! -a $installed ]]; then

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
	
		./$configure --prefix=$MONO_PREFIX
		local configured=$?
		if [[ ! $configured ]]; then
			cp config.log ../$repo.config.log
			die "failed to configure $repo"
		fi

		make || die "failed to make $repo"
		make install || die "failed to install $repo"
		echo $(date) > $installed
	fi

	cd - || die "failed to exit $repo"
}

# Installing common dependencies

apt-get install --yes git
apt-get install --yes automake libtool

# Installing libgdiplus
apt-get install --yes libglib2.0-dev libpng12-dev libgif-dev libjpeg-dev libtiff5-dev libfontconfig1-dev libcairo2-dev libexif-dev
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
git clone --recursive git://github.com/mono/gtk-sharp.git -b gtk-sharp-2-12-branch gtk-sharp-2-12
install gtk-sharp-2-12 bootstrap-2.12
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


# Result: MonoDevelop 4.0, without glade-sharp.dll
