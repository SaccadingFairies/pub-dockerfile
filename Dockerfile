FROM osrf/ros:kinetic-desktop-full
SHELL ["/bin/bash", "-l", "-c"]
# automatically sources the default ros on docker run
RUN echo "source /opt/ros/kinetic/setup.bash" >> ~/.bashrc
# Package for installing Baxter
RUN sudo apt-get update
RUN sudo apt-get install --allow-unauthenticated -y build-essential wget git xterm x11-xserver-utils \
# Astra packages
ros-$ROS_DISTRO-rgbd-launch ros-$ROS_DISTRO-libuvc ros-$ROS_DISTRO-libuvc-camera ros-$ROS_DISTRO-libuvc-ros \
# Move It
ros-kinetic-moveit \
#Fiducials
ros-kinetic-fiducials \
#Debugging
vim nano iproute2 net-tools inetutils-ping tree software-properties-common

RUN sudo add-apt-repository ppa:deadsnakes/ppa
RUN sudo apt-get update
RUN sudo apt-get install -y python3.6 python3.6-dev
RUN curl https://bootstrap.pypa.io/get-pip.py | sudo -H python3.6
RUN pip3.6 install -U rosdep rosinstall_generator wstool rosinstall roboticstoolbox-python

#Installing baxter_sdk
RUN mkdir -p /home/baxter/catkin_ws/src
WORKDIR /home/baxter/catkin_ws/src
#Baxter firware needs release 1.1.1
RUN git clone -b release-1.1.1 https://github.com/AIResearchLab/baxter
WORKDIR /home/baxter/catkin_ws/src/baxter
# removing baxter entry in rosinstall file to avoid duplicate baxter_sdk folders
RUN sed -i '1,4d' baxter_sdk.rosinstall
RUN wstool init . baxter_sdk.rosinstall 
RUN wstool update
# replacing the default hostname with the hostname of the UC Baxter and changingthe distro to kinetic
RUN sed -i -e '22 s/baxter_hostname.local/011502P0001.local/g' -e '26 s/192.168.XXX.XXX/172.17.0.2/g'  -e '30 s/"indigo"/"kinetic"/g' baxter.sh
RUN mv *.sh ../..
# change font size for xterm to 18
RUN echo  "xterm*font:     *-fixed-*-*-*-18-*" > ~/.Xresources
WORKDIR /home/baxter/catkin_ws/src
#installing ROS Astra package
RUN git clone https://github.com/orbbec/ros_astra_camera
RUN git clone https://github.com/orbbec/ros_astra_launch
RUN git clone https://github.com/ros-planning/moveit_robots.git
RUN sed -i -e '16 s/value="0.1"/value="0.0"/g' /home/baxter/catkin_ws/src/moveit_robots/baxter/baxter_moveit_config/launch/trajectory_execution.launch
RUN git clone -b kinetic-devel https://github.com/UbiquityRobotics/fiducials
RUN git clone -b kinetic-devel https://github.com/ros-perception/vision_msgs
WORKDIR /home/baxter/catkin_ws
COPY ir_astra_ost.yaml /home/baxter/catkin_ws
COPY rgb_astra_ost.yaml /home/baxter/catkin_ws
COPY export.sh /home/baxter/catkin_ws
RUN cat export.sh >> ~/.profile
RUN echo 'source /opt/ros/kinetic/setup.bash' >> ~/.bashrc
COPY entrypoint.sh /home/baxter/catkin_ws
RUN chmod +x entrypoint.sh

# it is neccesary to run 
RUN /bin/bash -c '. /opt/ros/kinetic/setup.bash; catkin_make'
ENTRYPOINT /home/baxter/catkin_ws/entrypoint.sh
CMD ["-f","/dev/null"]
