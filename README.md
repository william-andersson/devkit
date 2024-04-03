# DevKit

### Install
Run **`sudo ./install.sh`**<br>

### Settings
> Set REPO_PATH in: ```/usr/local/etc/devkit.conf```<br>
> to setup a local repository.

### Usage
```
devkit <OPTION>
--new <NAME>                 Setup new project from template.
--snap                       Make a snapshot of current source version.
--build                      Create distributable package from source.
--install <PACKAGE>          Install package from current directory.
--version                    Print installed version.
--help                       Print this help text.

If REPO_PATH is set in /usr/local/etc/devkit.conf
--repo-list                  List packages in local repository.
--repo-install <PACKAGE>     Install package from local repository.
```

> [!NOTE]
> Update function removed
