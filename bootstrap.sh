if [ "`lsb_release -i`" != "Distributor ID:	OpenNao" ]
then
	echo "This script must be run on Nao or an OpenNao VM"
	exit 1
fi
	
cat > ~/.bash_profile <<"EOF"
export OPENROBOTS=/opt/openrobots
export PATH=$PATH:$OPENROBOTS/sbin:$OPENROBOTS/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$OPENROBOTS/lib
export PYTHONPATH=$PYTHONPATH:$OPENROBOTS/lib/python2.7/site-packages
export MANPATH=$MANPATH:$OPENROBOTS/man

# if ROS is installed, source setup.bash
[ -f "$OPENROBOTS/etc/ros/setup.bash" ] && source $OPENROBOTS/etc/ros/setup.bash

alias emerge='emerge -G --autounmask-write'

# use this alias to install sysdeps to /opt/local
# convenient re-distribute the whole system
alias emergelocal='emerge -G --root=/opt/local'

# make sure PATH and aliases are preserved 
# through sudo (cf http://serverfault.com/a/178956)
alias sudo='sudo env PATH=$PATH '
EOF

source ~/.bash_profile

## if on Nao, give ourselves all sudo rights
if [ "`uname -p`" = "Intel(R) Atom(TM) CPU Z530 @ 1.60GHz" ]
then
	echo "It seems you are running this script on the robot."
	echo "For convenience, we need to grant all sudo rights"
	echo "to the 'nao' user. Please enter the root password "
	echo "(defaults to 'root')."
	su -c"echo 'nao     ALL=(ALL) ALL' >> /etc/sudoers"
fi

echo "Please enter now the 'nao' password."
sudo >/dev/null

# On Nao, the SD card is mounted on /var/persistent
# install our stuff there.
if [ -d /var/persistent ]
then
	sudo mkdir -p /var/persistent/opt
	sudo ln -Ts /var/persistent/opt /opt
fi

# check if emerge is already there
if hash emerge 2>/dev/null
then
	echo "'emerge' already available. Good."
else
	echo "'emerge' not available. Installing 'emerge'..."

	wget -q http://chili-research.epfl.ch/OpenNao/1.14/packages/sys-apps/portage-2.1.10.41-r178.tbz2
	sudo tar -xjf /home/nao/portage-2.1.10.41-r178.tbz2 -C /

	# fake a valid portage environment
	echo 'CHOST="i686-pc-linux-gnu"' | sudo tee -a /etc/make.conf
	# force writing of accepted keywords
	echo 'CONFIG_PROTECT="-*"' | sudo tee -a /etc/make.conf
	sudo mkdir -p /usr/portage/profiles
	sudo ln -s /usr/portage/profiles /etc/make.profile
	sudo mkdir -p /etc/env.d/gcc
	sudo touch /etc/env.d/gcc/i686-pc-linux-gnu-4.5.3

	# filling up the /var/db/pkg database with all packages already available
	# on Nao (ie, the one available on the OpenNao VM)
	wget -q http://chili-research.epfl.ch/OpenNao/1.14/opennao-1.14.5-pkg_db.tar.gz
	sudo tar -xzf /home/nao/opennao-1.14.5-pkg_db.tar.gz -C /
fi

# configure remote server for binary packages
echo "Setting the URL of the remote server for binary packages..."
echo 'PORTAGE_BINHOST=http://chili-research.epfl.ch/OpenNao/1.14/packages' | sudo tee -a /etc/portage/make.conf


# Install robotpkg + package manager
echo "Installing robotpkg..."
wget -q http://robotpkg.openrobots.org/packages/bsd/OpenNao-1.14.5.1-i386/bootstrap.tar.gz
sudo tar -xf bootstrap.tar.gz -C /
sudo robotpkg_add http://robotpkg.openrobots.org/packages/bsd/OpenNao-1.14.5.1-i386/All/pkgin-0.6.4.tgz
sudo robotpkgin update

echo "Your system is now configured to use binary packages for both "
echo "emerge and robotpkg."
echo "Run 'sudo emerge <pkg>' to install an OpenNao package."
echo "Run 'sudo robotpkgin install <pkg>' to install a robotpkg package."

