# Install_Configure

Example scripts to install and configure the Enterprise Console, Platform, Controller and Events Service

# Install the Enterprise Console

1) Edit response-4.5.0.varfile with install directory and passwords
2) Download platform-setup-x64-linux-4.5.0.11874.sh from https://download.appdynamics.com/download/#version=&apm=&os=linux&platform_admin_os=linux&events=&eum=&page=1<br/>
3 Install<br/>
    ./platform-setup-x64-linux-4.5.0.11874.sh -q -varfile response-4.5.0.varfile

For additional information see: https://docs.appdynamics.com/display/PRO45/Enterprise+Console


# Install the Platform, Controller and Events Service

1) Edit econsole-envvars-450a.sh with install directory, SSH Credentials, user/password, controller profile, controller name etc.
2) Install<br/>
    . econsole-envvars-450a.sh<br/>
    ./econsole-cmd.sh installPlatform<br/>
    ./econsole-cmds.sh installController<br/>
    ./econsole-cmds.sh installEventsService<br/>


For additional information see: https://docs.appdynamics.com/display/PRO45/Enterprise+Console
