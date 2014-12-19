#!/bin/sh

if [ "`lsb_release -i`" != "Distributor ID:	OpenNao" ]
then
	echo "This script must be run on Nao or an OpenNao VM"
	exit 1
fi

OPENNAO_VERSION=`lsb_release -r | cut -f2`

# TODO: Set the correct mirror URIs once the script has been ported and tested to the new OpenNao versions
case "$OPENNAO_VERSION" in
1.*)
	OPENNAO_PORTAGE_BIN_MIRROR=http://chili-research.epfl.ch/OpenNao/1.14
	OPENNAO_SYSTEM_PACKAGES=opennao-1.14.5-pkg_db.tar.gz
	ROBOTPKG_OPENNAO_BIN_MIRROR=http://robotpkg.openrobots.org/packages/bsd/OpenNao-1.14.5.1-i386
	;;
2.*)
	OPENNAO_PORTAGE_BIN_MIRROR=http://chili-research.epfl.ch/OpenNao/2.1.0.19
	OPENNAO_SYSTEM_PACKAGES=opennao-pkg_db.tar.gz
	ROBOTPKG_OPENNAO_BIN_MIRROR=http://robotpkg.openrobots.org/packages/bsd/OpenNao-2.1.0.19-i386
	;;
*)
	echo "This script has not been adapted to OpenNao version $OPENNAO_VERSION." >&2
	echo "Please adapt the ..._MIRROR variables manually." >&2
	;;
esac

if [ -z "$OPENROBOTS" ]
then
   echo "Preparing your environment in ~/.bash_profile..."
    
cat >> ~/.bash_profile <<"EOF"
export OPENROBOTS=/opt/openrobots
export PATH=$PATH:$OPENROBOTS/sbin:$OPENROBOTS/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$OPENROBOTS/lib
export PYTHONPATH=$PYTHONPATH:$OPENROBOTS/lib/python2.7/site-packages
export MANPATH=$MANPATH:$OPENROBOTS/man

# if ROS is installed, source setup.bash
[ -f "$OPENROBOTS/etc/ros/setup.bash" ] && source $OPENROBOTS/etc/ros/setup.bash

# use this alias to install sysdeps to /opt/local
# convenient to re-distribute the whole system
alias emergelocal='emerge -G --root=/opt/local'

# make sure aliases are preserved 
# through sudo (cf http://serverfault.com/a/178956)
# note the trailing space
alias sudo='sudo '
EOF

else
    echo "It seems your environment is already set-up. Using it."
fi

source ~/.bash_profile

# Add openrobots binary path to sudo PATH variable
SUDOPATH="`sudo printenv PATH`:$OPENROBOTS/sbin:$OPENROBOTS/bin"
sudo flock /etc/sudoers.tmp -c bash <<EOF
echo -e "Defaults\tsecure_path=\"$SUDOPATH\"" > /etc/sudoers.tmp
cat /etc/sudoers >> /etc/sudoers.tmp
visudo -q -c -f /etc/sudoers.tmp && cat /etc/sudoers.tmp > /etc/sudoers
rm /etc/sudoers.tmp
EOF

# On Nao, the SD card is mounted on /var/persistent
# install our stuff there.
if [ -d /var/persistent ]
then
	echo "Creating a symlink from SD card to /opt..."
	sudo mkdir -p /var/persistent/opt
	sudo ln -Ts /var/persistent/opt /opt
fi

# check if emerge is already there
if hash emerge 2>/dev/null
then
	echo "'emerge' already available. Good."
else
	echo "'emerge' not available. Installing 'emerge'..."

	wget -q $OPENNAO_PORTAGE_BIN_MIRROR/packages/sys-apps/portage-2.1.10.41-r178.tbz2
	sudo tar -xjf portage-2.1.10.41-r178.tbz2 -C /

	# fake a valid portage environment
	echo 'CHOST="i686-pc-linux-gnu"' | sudo tee -a /etc/make.conf
	# force writing of accepted keywords
	echo 'CONFIG_PROTECT="-*"' | sudo tee -a /etc/make.conf
	# download binary packages instead of compiling from source by default
	# and unmask packages automatically
	echo 'EMERGE_DEFAULT_OPTS="${EMERGE_DEFAULT_OPTS} --getbinpkgonly --autounmask-write"' | sudo tee -a /etc/make.conf
	sudo mkdir -p /usr/portage/profiles
	sudo ln -s /usr/portage/profiles /etc/make.profile
	sudo mkdir -p /etc/env.d/gcc
	sudo touch /etc/env.d/gcc/i686-pc-linux-gnu-4.5.3

	# filling up the /var/db/pkg database with all packages already available
	# on Nao (ie, the one available on the OpenNao VM)
	wget -q $OPENNAO_PORTAGE_BIN_MIRROR/$OPENNAO_SYSTEM_PACKAGES
	sudo tar -xzf $OPENNAO_SYSTEM_PACKAGES -C /
	rm $OPENNAO_SYSTEM_PACKAGES
fi

# configure remote server for binary packages
echo "Setting the URL of the remote server for binary packages in /etc/portage/make.conf:"
echo "PORTAGE_BINHOST=$OPENNAO_PORTAGE_BIN_MIRROR/packages" | sudo tee -a /etc/portage/make.conf


# Install robotpkg + package manager
echo "Installing robotpkg..."
wget -q $ROBOTPKG_OPENNAO_BIN_MIRROR/bootstrap.tar.gz
sudo tar -xf bootstrap.tar.gz -C /
rm bootstrap.tar.gz
sudo robotpkg_add $ROBOTPKG_OPENNAO_BIN_MIRROR/All/pkgin-0.6.4r1.tgz
sudo robotpkgin update

echo "Your system is now configured to use binary packages for both "
echo "emerge and robotpkg."
echo "Run 'sudo emerge <pkg>' to install an OpenNao package."
echo "Run 'sudo robotpkgin install <pkg>' to install a robotpkg package."

