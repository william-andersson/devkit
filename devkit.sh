#!/bin/bash
#
# Application: DevKit
# Comment:     Shell-script development manager
# Copyright:   William Andersson 2024
# Website:     https://github.com/william-andersson
# License:     GPL
#
VERSION=#(SET BY: build.cfg)
source /usr/local/etc/devkit.conf
echo "DevKit $VERSION (Shell-script project manager)"

func_help(){
cat <<EOF
Usage: $0 <OPTION>

Options:
--new <NAME>                 New project.
                             Setup new project from template.
--snap                       Create snapshot.
                             Make a snapshot of current source version.
--build                      Create package.
                             Create distributable package from source.
--install <PACKAGE>          Install package.
                             Install package from current directory.

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
	echo "Creating snapshot of current version ($APP_VERSION)."
	INDEX=$(cat $PWD/builds/$APP_NAME-$APP_VERSION/snapshots/index)
	tar --exclude='builds' -cvf $PWD/builds/$APP_NAME-$APP_VERSION/snapshots/snapshot-$INDEX.tar *
	echo "$((INDEX+1))" > $PWD/builds/$APP_NAME-$APP_VERSION/snapshots/index
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
		echo -e "\033[31mWarning, a package with version $APP_VERSION already exists!\033[0m"
		read -p "Overwrite [y/n]? " QUEST
		if [ $QUEST != "y" ];then
			echo -e "\nAborted."
			exit 1
		else
			rm -rv $PWD/builds/$APP_NAME-$APP_VERSION/content
			rm -rv $PWD/builds/$APP_NAME-$APP_VERSION/INSTALL
			rm -rv $PWD/builds/$APP_NAME-$APP_VERSION/$APP_NAME-$APP_VERSION.pkg
		fi
	fi
	#
	# Create directory and add files.
	#
	echo "Building package of current version ($APP_VERSION)."
	mkdir -v $PWD/builds/$APP_NAME-$APP_VERSION/content
	for path in ${STATIC_FILES[@]};do
		IFS=';' read -ra values <<< "$path"
		if [ "${values[0]}" == "$APP_NAME.sh" ];then
			#
			# Prepare STATIC_FILES; Always install
			# If $NAME.sh change VERSION to APP_VERSION
			#
			echo "install -v -D -C devkit.in/content/${values[0]} ${values[1]}" >> $PWD/builds/$APP_NAME-$APP_VERSION/INSTALL
			cp -v ${values[0]} $PWD/builds/$APP_NAME-$APP_VERSION/content
			sed -i '0,/#(SET BY: build.cfg)/s//'$APP_VERSION'/' $PWD/builds/$APP_NAME-$APP_VERSION/content/$APP_NAME.sh
		else
			echo "install -v -D -C devkit.in/content/${values[0]} ${values[1]}" >> $PWD/builds/$APP_NAME-$APP_VERSION/INSTALL
			cp -v ${values[0]} $PWD/builds/$APP_NAME-$APP_VERSION/content
		fi
	done
	for path in ${ACTIVE_FILES[@]};do
		#
		# Prepare ACTIVE_FILES; Install if none exist
		#
		IFS=';' read -ra values <<< "$path"
		echo "cp -pnv devkit.in/content/${values[0]} ${values[1]}" >> $PWD/builds/$APP_NAME-$APP_VERSION/INSTALL
		cp -v ${values[0]} $PWD/builds/$APP_NAME-$APP_VERSION/content
	done
	#
	# Change directory and make archive,
	# removing directory when done.
	#
	echo "Copying current source version ($APP_VERSION)."
	tar --exclude='builds' -cvf $PWD/builds/$APP_NAME-$APP_VERSION/$APP_NAME-$APP_VERSION-src.tar *
	if [ "$APP_NAME" != "devkit" ];then
		#
		# Don't package devkit
		#
		cd $PWD/builds/$APP_NAME-$APP_VERSION
		tar -cvf $APP_NAME-$APP_VERSION.pkg content INSTALL
		if [ "$REPO_PATH" != "" ];then
			if [ ! -d "$REPO_PATH" ];then
				mkdir -pv $REPO_PATH
			fi
			cp -pv $APP_NAME-$APP_VERSION.pkg $REPO_PATH/$APP_NAME-$APP_VERSION.pkg
		fi
	else
		# Copy DevKit install file
		cp -v install.sh $PWD/builds/$APP_NAME-$APP_VERSION/
	fi
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
	source devkit.in/INSTALL
	rm -rv devkit.in
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
	source devkit.in/INSTALL
	rm -rv devkit.in
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
	--help)
		func_help
		;;
	*)
		func_help
		;;
esac
