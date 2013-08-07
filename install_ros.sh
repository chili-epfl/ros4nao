#! /usr/bin/env bash

ROS_VERSION=groovy
ARCHIVE_NAME="${ROS_VERSION}-nao.tar.gz"
REPO="http://chili-research.epfl.ch/ros4nao/"

PREFIX=/opt/ros/${ROS_VERSION}

NAOQI_USER="nao"

echo "This script downloads and installs the binary distribution of ROS ${ROS_VERSION} for Nao."

if [ -f $ARCHIVE_NAME ]; then
        echo "${ARCHIVE_NAME} found in the current directory."

        read -p "Do you want to use it? (Y/n)" yn
        case $yn in
                [Nn]* ) echo "Delete/move it and launch this script again."; exit;;
        esac

else
        echo "Downloading ${ARCHIVE_NAME} from ${REPO}..."
        wget $REPO/$ARCHIVE_NAME
fi

if [ ! -w $PREFIX ]; then
        echo "Creation of installation prefix ${PREFIX} (this may require root password)"
        su -c "mkdir -p $PREFIX"
        su -c "chown ${NAOQI_USER}:${NAOQI_USER} ${PREFIX}"
fi

echo "Extracting the distribution..."
tar -C $PREFIX -xf $ARCHIVE_NAME --strip=1

echo "Setting up the environment (in ~/.bash_profile)..."

echo "" >> $HOME/.bash_profile
echo "# OpenRobots/ROS configuration" >> $HOME/.bash_profile
echo "export OPENROBOTS_PREFIX=${PREFIX}" >> $HOME/.bash_profile
echo "export ROS_MASTER_URI=http://localhost:11311" >> $HOME/.bash_profile

echo "export ROS_PACKAGE_PATH=\$OPENROBOTS_PREFIX/share" >> $HOME/.bash_profile

echo "export PYTHONPATH=\$PYTHONPATH:\$OPENROBOTS_PREFIX/lib/python2.7/site-packages:\$OPENROBOTS_PREFIX/usr/lib/python2.7/site-packages" >> $HOME/.bash_profile

echo "export PATH=\$PATH:\$OPENROBOTS_PREFIX/bin:\$OPENROBOTS_PREFIX/sbin:\$OPENROBOTS_PREFIX/usr/bin" >> $HOME/.bash_profile

echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\$OPENROBOTS_PREFIX/lib:\$OPENROBOTS_PREFIX/usr/lib" >> $HOME/.bash_profile

echo "source \$OPENROBOTS_PREFIX/etc/ros/setup.bash" >> $HOME/.bash_profile

source $HOME/.bash_profile

echo "Installation done! ROS should be ready to be used."
