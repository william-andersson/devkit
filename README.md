# DevKit

### Install
From directory **devkit-2.0** run **`sudo ./install.sh`**<br>
> [!IMPORTANT]
> DevKit is only installable via the pre-built package (devkit-2.0)<br>
> This is done so DevKit can build itself.

### Settings
> Set REPO_PATH in: ```/usr/local/etc/devkit.conf```<br>
> to setup a local repository.

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
