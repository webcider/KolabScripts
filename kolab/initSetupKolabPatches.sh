#!/bin/bash

SCRIPTSPATH=`dirname ${BASH_SOURCE[0]}`
source $SCRIPTSPATH/lib.sh

DetermineOS
InstallWgetAndPatch
DeterminePythonPath

#####################################################################################
# apply a couple of patches, see related kolab bugzilla number in filename, eg. https://issues.kolab.org/show_bug.cgi?id=2018
#####################################################################################

echo "applying patch for Roundcube Kolab plugin for storage in MariaDB"
patch -p1 -i `pwd`/patches/roundcubeStorageMariadbBug4883.patch -d /usr/share/roundcubemail || exit -1

# TODO: see if we still need these patches
#echo "applying patch for waiting after restart of dirsrv (necessary on Debian)"
#patch -p1 -i `pwd`/patches/setupKolabSleepDirSrv.patch -d $pythonDistPackages || exit -1

# change behaviour of kolab sync so that it also syncs mailhost etc, as does kolabd daemon.
# this disables the multi-thread creation of mailboxes
# see https://github.com/TBits/KolabScripts/issues/73
sed -i "s#auth.synchronize\(.*\)#auth.synchronize()#g" $pythonDistPackages/pykolab/cli/cmd_sync.py

if [[ $OS == Debian* ]]
then
      # workaround for bug 2050, https://issues.kolab.org/show_bug.cgi?id=2050
      echo "export ZEND_DONT_UNLOAD_MODULES=1" >> /etc/apache2/envvars

      # TODO on Debian, we need to install the rewrite for the csrf token
      newConfigLines="\tRewriteEngine On\n \
\tRewriteRule ^/roundcubemail/[a-f0-9]{16}/(.*) /roundcubemail/\$1 [PT,L]\n \
\tRewriteRule ^/webmail/[a-f0-9]{16}/(.*) /webmail/\$1 [PT,L]\n \
\tRedirectMatch ^/$ /roundcubemail/\n"

#      sed -i -e "s~</VirtualHost>~$newConfigLines</VirtualHost>~" /etc/apache2/sites-enabled/000-default
fi

systemctl start guam || exit -1
