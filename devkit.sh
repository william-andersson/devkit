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

func_help(){
cat <<EOF
DevKit $VERSION (Shell-script project manager).
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
	mkdir $PWD/$NAME
	touch $PWD/$NAME/README
	touch $PWD/$NAME/CHANGELOG
cat > $PWD/$NAME/main.sh <<endmsg
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
APP_NAME=$NAME
APP_VERSION=1.0
INSTALLED_PATH=("main.sh;/bin/$NAME" "README;/")
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
	if [ ! -d "$PWD/builds/src" ];then
		echo "Creating directory [$PWD/builds/src] ..."
		mkdir -p $PWD/builds/src
	fi
	if [ -f "$PWD/builds/src/$APP_NAME-$APP_VERSION-src.tar" ];then
		echo -e "\033[31mWarning, a source package with version $APP_VERSION already exists!\033[0m"
		read -p "Overwrite [y/n]? " QUEST
		if [ $QUEST != "y" ];then
			echo -e "\nAborted."
			exit 1
		fi
	fi
	#
	# Make archive
	#
	echo "Creating source package of current version ($APP_VERSION)."
	tar --exclude='builds' -cpvf $PWD/builds/src/$APP_NAME-$APP_VERSION-src.tar *
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
		TIMESTAMP=$(date +%d-%m-%Y)
	fi
	if [ ! -d "$PWD/builds/pkg" ];then
		echo "Creating directory [$PWD/builds/pkg] ..."
		mkdir -p $PWD/builds/pkg
	fi
	if [ -d "$PWD/builds/pkg/$APP_NAME-$APP_VERSION" ] || [ -f "$PWD/builds/pkg/$APP_NAME-$APP_VERSION.pkg" ];then
		echo -e "\033[31mWarning, a package with version $APP_VERSION already exists!\033[0m"
		read -p "Overwrite [y/n]? " QUEST
		if [ $QUEST != "y" ];then
			echo -e "\nAborted."
			exit 1
		fi
	fi
	#
	# Create directory and add files.
	# Write package header PKG_INFO
	#
	echo "Building package of current version ($APP_VERSION)."
	mkdir $PWD/builds/pkg/$APP_NAME-$APP_VERSION
	echo "Package name: $APP_NAME-$APP_VERSION.tar" > $PWD/builds/pkg/$APP_NAME-$APP_VERSION/PKG_INFO
	echo "Build date: $TIMESTAMP" >> $PWD/builds/pkg/$APP_NAME-$APP_VERSION/PKG_INFO
	echo "Dependencies: $DEPENDENCIES" >> $PWD/builds/pkg/$APP_NAME-$APP_VERSION/PKG_INFO
	for path in ${INSTALLED_PATH[@]};do
		IFS=';' read -ra values <<< "$path"
		if [ "${values[0]}" == "main.sh" ] || [ "${values[0]}" == "devkit.sh" ];then
			#
			# If main.sh change VERSION to APP_VERSION
			#
			install -v -D -C -m 775 ${values[0]} $PWD/builds/pkg/$APP_NAME-$APP_VERSION${values[1]}
			sed -i '0,/#(SET BY: build.cfg)/s//'$APP_VERSION'/' $PWD/builds/pkg/$APP_NAME-$APP_VERSION${values[1]}
		elif [[ "${values[0]}" == *".sh"* ]];then
			install -v -D -C -m 775 ${values[0]} $PWD/builds/pkg/$APP_NAME-$APP_VERSION${values[1]}
		else
			install -v -D -C -m 664 ${values[0]} $PWD/builds/pkg/$APP_NAME-$APP_VERSION${values[1]}
		fi
	done
	#
	# Change directory and make archive,
	# removing directory when done.
	#
	if [ "$APP_NAME" != "devkit" ];then
		#
		# Don't package devkit
		#
		echo "Changing directory $PWD/builds/pkg"
		cd $PWD/builds/pkg
		tar -cpvf $APP_NAME-$APP_VERSION.pkg $APP_NAME-$APP_VERSION
		echo "Removing temporary directory $PWD/builds/pkg/$APP_NAME-$APP_VERSION"
		rm -r $APP_NAME-$APP_VERSION
		if [ "$REPO_PATH" != "" ];then
			if [ ! -d "$REPO_PATH" ];then
				echo "Creating directory [$REPO_PATH] ..."
				mkdir -p $REPO_PATH
			fi
			echo "Copying package to repo ..."
			cp -v $APP_NAME-$APP_VERSION.pkg $REPO_PATH/$APP_NAME-$APP_VERSION.pkg
		fi
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
	tar -xf $FILE
	for file in "$PWD/$NAME"/*;do
		if [ -d "$file" ];then
			cp -rPv $file $INSTALL_PREFIX/
		fi
	done
	echo "Removing temporary directory $NAME"
	rm -r $NAME
}

func_repo_list(){
	if [ "$REPO_PATH" == "" ];then
		echo "No local repo set!"
		exit 1
	else
		#
		# Should add loop to read pkg headers
		# to view PACKAGE -> INFO
		#
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
	tar -xf $FILE
	for file in "$NAME"/*;do
		if [ -d "$file" ];then
			cp -rPv $file $INSTALL_PREFIX/
		fi
	done
	echo "Removing temporary directory $NAME"
	rm -r $REPO_PATH/$NAME
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
