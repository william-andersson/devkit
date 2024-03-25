# DevKit

### Install
From directory devkit-1.1 **`sudo ./install.sh`**

### Settings
Change settings in: ```/usr/local/etc/devkit.conf```
##### Default settings<br>
> INSTALL_PREFIX="/usr/local"<br>
> REPO_PATH=""

### Usage
```
devkit <OPTION>
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
```
