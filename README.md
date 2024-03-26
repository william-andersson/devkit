# DevKit

### Install
Run **`sudo ./install.sh`**<br>

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

> [!NOTE]
> ### Version 2
> * Places both snapshots and builds in the same directory.
> * New package and install structure.
> * Renamed and added variables in build.cfg
> * Code clean up
> * Bug fixes
