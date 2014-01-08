#! /usr/bin/env sh

ROS_VERSION=groovy
PREFIX=/opt/ros/$ROS_VERSION
PORTAGE_PACKAGES=$HOME/opennao-distro/packages

PACKAGES=$PORTAGE_PACKAGES/*/*.tbz2

INITIAL_PATH=${PWD}

ARCHIVE_NAME=$ROS_VERSION-nao.tar.gz

cd $PREFIX

shopt -s nullglob

echo "This script helps generating a binary release of ROS for Nao"
echo ""
echo "It is intended to be run on the Nao virtual image."
echo "First, install the packages you need with robotpkg, using 'emerge' to "
echo "install sysdeps."
echo ""
read -p "Have you install all the packages? (Y/n)" yn
case $yn in
[Nn]* ) exit;;

esac

echo "First, I'll merge all the sysdeps in your prefix ($PREFIX)..."

for f in $PACKAGES
do
        echo "Installing ${f} in your prefix..."
        tar -xjf $f
done


echo "Then, I archive your prefix..."
cd $PREFIX && cd ..
tar -czf $ARCHIVE_NAME ${PREFIX##*/}
mv $ARCHIVE_NAME $INITIAL_PATH
cd $INITIAL_PATH

echo "$ARCHIVE_NAME is ready to be published."
