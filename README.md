ros4nao
=======

Helpers to compile and distribute ROS for Aldebaran's Nao

> **Attention**:
> If you wish to install ROS on your Nao, follow the instruction on
> <http://www.ros.org/wiki/nao/Installation>. This repo only contains tools
> to help *creating* ROS distributions for Nao.

Contents overview
-----------------

- `robotpkg.conf`: `robotpkg` configuration file, tuned for Nao. It expects
  `robotpkg` has been bootstrapped with `PREFIX=/opt/ros/groovy`.

- `bootstrap.sh`: shell script to be run on a Nao. It installs `emerge` and
  `robotpkgin` on the robot, which allows to use these package managers to
  install software on the robot.

### Binary distributions

`binary_distribution/` contains two scripts to respectively generate and
install a full ROS binary distribution for Nao. Note that *this is not the
recommended way* to distribute ROS for Nao. We recommend instead to use the
package managers, as provided by the `bootstrap.sh` script.

- `prepare_ros.sh`: shell script to be run on the Nao virtual machine. It
  copies the system dependencies required by ROS and create an archive ready
  for distribution.

- `install_ros.sh`: shell script to be run on a Nao, that download and unpack
  the ROS distribution.

