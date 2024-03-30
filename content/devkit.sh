#!/bin/bash
#
# Application: DevKit
# Comment:     Shell-script development manager
# Copyright:   William Andersson 2024
# Website:     https://github.com/william-andersson
# License:     GPL
#
VERSION=2.5
source /usr/local/etc/devkit.conf

func_help(){
cat <<EOF
DevKit $VERSION (Shell-script project manager)
Usage: $0 <OPTION>

Options:
--new <NAME>                 Setup new project from template.
--snap                       Make a snapshot of current source version.
--build                      Create distributable package from source.
--install <PACKAGE>          Install package from current directory.
--update                     Update DevKit to latest version.
--version                    Print installed version.
--help                       Print this help text.

If REPO_PATH is set in /usr/local/etc/devkit.conf
--repo-list                  List packages in local repository.
--repo-install <PACKAGE>     Install package from local repository.

EOF
}

func_new(){
	if [ -z "$1" ];then
		func_help
		exit 1
	else
		NAME=$1
	fi
	mkdir -v $PWD/$NAME
	touch $PWD/$NAME/NOTES
	touch $PWD/$NAME/README
	touch $PWD/$NAME/CHANGELOG
	
cat > $PWD/$NAME/$NAME.sh <<endmsg
#!/bin/bash
#
# Application: $NAME
# Comment:
# Copyright:   $COPYRIGHT
# Website:     $URL
# License:     $LICENSE
#
VERSION=#(SET BY: build.cfg)
endmsg
	
cat > $PWD/$NAME/build.cfg <<endmsg
#
# DevKit build file
# STATIC_FILES = file names and installed paths (always install)
# ACTIVE_FILES = file names and installed paths (install if not exist) 
# DEPENDENCIES = list of dependencies
#
APP_NAME=$NAME
APP_VERSION=1.0
STATIC_FILES=("$NAME.sh;/usr/local/bin/$NAME")
ACTIVE_FILES=("")
DEPENDENCIES=("")
endmsg
exit 0
}

func_update_devkit(){
	if [[ $EUID -ne 0 ]]; then
		echo "Must be root!"
		exit 1
	fi
	CURRENT=$(wget -qO- https://raw.githubusercontent.com/william-andersson/devkit/main/update/VERSION)
	CURRENT_MAJOR=$(echo $CURRENT | awk -F '.' '{print $1}')
	CURRENT_MINOR=$(echo $CURRENT | awk -F '.' '{print $2}')
	VERSION_MAJOR=$(echo $VERSION | awk -F '.' '{print $1}')
	VERSION_MINOR=$(echo $VERSION | awk -F '.' '{print $2}')
	
	if [ $CURRENT_MAJOR -gt $VERSION_MAJOR ] || [ $CURRENT_MINOR -gt $VERSION_MINOR ];then
        wget https://github.com/william-andersson/devkit/raw/main/update/current.pkg
	    func_install current.pkg
	    rm -v current.pkg
	    echo "Updated version: $(devkit --version)."
	    exit 0
	else
	    echo "DevKit is up to date."
	    exit 0
	fi
}

func_update_version(){
	echo "Current version: $APP_VERSION"
	read -p "New version: " NEW_VER
	sed -i '0,/APP_VERSION='$APP_VERSION'/s//APP_VERSION='$NEW_VER'/' $PWD/build.cfg
	func_build
}

func_snap(){
	#
	# Check for missing files and folders.
	#
	if [ ! -f "$PWD/build.cfg" ];then
		echo "Error, missing file $PWD/build.cfg"
		exit 1
	else
		source $PWD/build.cfg
	fi
	if [ ! -d "$PWD/builds/$APP_NAME-$APP_VERSION" ];then
		mkdir -pv $PWD/builds/$APP_NAME-$APP_VERSION
	fi
	if [ ! -d "$PWD/builds/$APP_NAME-$APP_VERSION/snapshots" ];then
		mkdir -pv $PWD/builds/$APP_NAME-$APP_VERSION/snapshots
		echo "1" > $PWD/builds/$APP_NAME-$APP_VERSION/snapshots/index
	fi
	#
	# Make archive
	#
	INDEX=$(cat $PWD/builds/$APP_NAME-$APP_VERSION/snapshots/index)
	echo "Creating snapshot [$INDEX] of current version ($APP_VERSION)."
	tar --exclude='builds' -cvf $PWD/builds/$APP_NAME-$APP_VERSION/snapshots/snapshot-$INDEX-$(date +%d%m%y_%H%M).tar *
	echo "$((INDEX+1))" > $PWD/builds/$APP_NAME-$APP_VERSION/snapshots/index
	echo "Done."
	exit 0
}

func_build(){
	#
	# Start build by checking for missing files and folders.
	#
	if [ ! -f "$PWD/build.cfg" ];then
		echo "Error, missing file $PWD/build.cfg"
		exit 1
	else
		source $PWD/build.cfg
	fi
	if [ ! -d "$PWD/builds/$APP_NAME-$APP_VERSION" ];then
		mkdir -pv $PWD/builds/$APP_NAME-$APP_VERSION
	fi
	if [ -f "$PWD/builds/$APP_NAME-$APP_VERSION/$APP_NAME-$APP_VERSION.pkg" ];then
		echo -e "\033[91mWarning, a package with version $APP_VERSION already exists!\033[0m"
		echo -e "Update version, Overwrite or Abort?"
		select INPUT in "Update" "Overwrite" "Abort"; do
    		case $INPUT in
        		Update ) func_update_version; break;;
        		Overwrite ) rm -rv $PWD/builds/$APP_NAME-$APP_VERSION/$APP_NAME-$APP_VERSION.pkg;
        					rm -rv $PWD/builds/$APP_NAME-$APP_VERSION/$APP_NAME-$APP_VERSION-src.tar;
        					break;;
        		Abort ) echo -e "\nAborted."; exit;;
    		esac
		done
	fi
	#
	# Create directory and add files.
	#
	echo "Building package of current version ($APP_VERSION)."
	mkdir -v $PWD/builds/$APP_NAME-$APP_VERSION/content
cat > $PWD/builds/$APP_NAME-$APP_VERSION/install.sh <<endmsg
#!/bin/bash
if [[ \$EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi
if ! [[ "\${BASH_SOURCE[0]}" == "\${0}" ]];then
    # If installed via DevKit
    # https://github.com/william-andersson/devkit
    PREFIX="devkit.in"
else
    PREFIX="\$PWD"
fi
endmsg
	for path in ${STATIC_FILES[@]};do
		IFS=';' read -ra values <<< "$path"
		if [ "${values[0]}" == "$APP_NAME.sh" ];then
			#
			# Prepare STATIC_FILES; Always install
			# If $NAME.sh change VERSION to APP_VERSION
			#
			echo "install -v -D -C \$PREFIX/content/${values[0]} ${values[1]}" >> $PWD/builds/$APP_NAME-$APP_VERSION/install.sh
			cp -v ${values[0]} $PWD/builds/$APP_NAME-$APP_VERSION/content
			sed -i '0,/#(SET BY: build.cfg)/s//'$APP_VERSION'/' $PWD/builds/$APP_NAME-$APP_VERSION/content/$APP_NAME.sh
		else
			echo "install -v -D -C \$PREFIX/content/${values[0]} ${values[1]}" >> $PWD/builds/$APP_NAME-$APP_VERSION/install.sh
			cp -v ${values[0]} $PWD/builds/$APP_NAME-$APP_VERSION/content
		fi
	done
	for path in ${ACTIVE_FILES[@]};do
		#
		# Prepare ACTIVE_FILES; Install if none exist
		#
		IFS=';' read -ra values <<< "$path"
		echo "cp -pnv \$PREFIX/content/${values[0]} ${values[1]}" >> $PWD/builds/$APP_NAME-$APP_VERSION/install.sh
		cp -v ${values[0]} $PWD/builds/$APP_NAME-$APP_VERSION/content
	done
	#
	# Change directory and make archive,
	# removing directory when done.
	#
	echo "Copying current source version ($APP_VERSION)."
	tar --exclude='builds' -cvf $PWD/builds/$APP_NAME-$APP_VERSION/$APP_NAME-$APP_VERSION-src.tar *
	cd $PWD/builds/$APP_NAME-$APP_VERSION
	tar -cvf $APP_NAME-$APP_VERSION.pkg content install.sh
	if [ "$REPO_PATH" != "" ];then
		if [ ! -d "$REPO_PATH" ];then
			mkdir -pv $REPO_PATH
		fi
		cp -pv $APP_NAME-$APP_VERSION.pkg $REPO_PATH/$APP_NAME-$APP_VERSION.pkg
	fi
	cd ../..
	rm -rv $PWD/builds/$APP_NAME-$APP_VERSION/content
	rm -rv $PWD/builds/$APP_NAME-$APP_VERSION/install.sh
	echo "Done."
	exit 0
}

func_install(){
	if [[ $EUID -ne 0 ]]; then
		echo "Must be root!"
		exit 1
	elif [ -z "$1" ];then
		func_help
		exit 1
	else
		FILE=$1
		if [ ! -f "$PWD/$FILE" ];then
			echo "No such file [$PWD/$FILE]!"
			exit 1
		fi
	fi
	NAME="${FILE%.*}"
	mkdir -v devkit.in
	tar -xf $FILE -C devkit.in
	source devkit.in/install.sh
	rm -rv devkit.in
	echo "Done."
}

func_repo_list(){
	if [ "$REPO_PATH" == "" ];then
		echo "No local repo set!"
		exit 1
	else
		ls $REPO_PATH
	fi
}

func_repo_install(){
	if [[ $EUID -ne 0 ]]; then
		echo "Must be root!"
		exit 1
	elif [ "$REPO_PATH" == "" ];then
		echo "No local repo set!"
		exit 1
	elif [ -z "$1" ];then
		echo "No package specified!"
		exit 1
	else
		FILE=$1
		if [ ! -f "$REPO_PATH/$FILE" ];then
			echo "No such file [$REPO_PATH/$FILE]!"
			exit 1
		fi
	fi
	NAME="${FILE%.*}"
	cd $REPO_PATH
	mkdir -v devkit.in
	tar -xf $FILE -C devkit.in
	source devkit.in/install.sh
	rm -rv devkit.in
	echo "Done."
}

case $1 in
	--new)
		func_new $2
		;;
	--snap)
		func_snap
		;;
	--build)
		func_build
		;;
	--install)
		func_install $2
		;;
	--repo-install)
		func_repo_install $2
		;;
	--repo-list)
		func_repo_list
		;;
	--update)
		func_update_devkit
		exit 0
		;;
	--version)
		echo "Version: $VERSION"
		exit 0
		;;
	--help)
		func_help
		;;
	*)
		func_help
		;;
esac
