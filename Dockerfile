#######################################################################
# Author: Nikolaus Mayer (2018), mayern@cs.uni-freiburg.de
#######################################################################

FROM nvidia/cuda:10.0-cudnn7-devel-ubuntu18.04

## Container's mount points for the host's input/output folders
VOLUME "/input"
VOLUME "/output"

RUN apt update                             && \
    apt install -y --no-install-recommends    \
    python3                                   \
    python3-distutils                         \
    cmake                                     \
    git                                       \
    curl                                      \
    wget                                      \
    libeigen3-dev                             \
    sudo

## Switch to non-root user 
ARG uid
ARG gid
ENV uid=${uid}
ENV gid=${gid}
ENV USER=netdef
RUN groupadd -g $gid $USER                                              && \
    mkdir -p /home/$USER                                                && \
    echo "${USER}:x:${uid}:${gid}:${USER},,,:/home/${USER}:/bin/bash"      \
         >> /etc/passwd                                                 && \
    echo "${USER}:x:${uid}:"                                               \
         >> /etc/group                                                  && \
    echo "${USER} ALL=(ALL) NOPASSWD: ALL"                                 \
         > /etc/sudoers.d/${USER}                                       && \
    chmod 0440 /etc/sudoers.d/${USER}                                   && \
    chown ${uid}:${gid} -R /home/${USER}

USER ${USER}
ENV HOME=/home/${USER}

WORKDIR ${HOME}

RUN sudo curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py   && \
    sudo python3 get-pip.py                                        && \
    wget https://lmb.informatik.uni-freiburg.de/resources/binaries/tensorflow-binaries/tensorflow-1.11.0-cp36-cp36m-linux_x86_64.whl && \
    sudo -H pip3 install ${HOME}/tensorflow-1.11.0-cp36-cp36m-linux_x86_64.whl && \
    sudo -H pip3 install scikit-learn pillow scipy

RUN git clone https://github.com/lmb-freiburg/lmbspecialops && \
    cd lmbspecialops                                        && \
    git checkout eccv18                                     && \
    find . -type f -print0 | xargs -0 sed -i 's/data.starts_with(/str_util::StartsWith(data,/g' && \
    find . -type f -print0 | xargs -0 sed -i 's/^set_target_properties.*GLIBCXX_USE_CXX11_ABI.*/#/g' && \
    mkdir build                                             && \
    cd build                                                && \
    sudo ln -s /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/cuda/lib64/stubs/libcuda.so.1 && \
    export LD_LIBRARY_PATH=/usr/local/cuda/lib64/stubs/:$LD_LIBRARY_PATH && \
    cmake ..                                                && \
    make -j                                                 && \
    sudo rm /usr/local/cuda/lib64/stubs/libcuda.so.1

RUN git clone https://github.com/lmb-freiburg/netdef_slim   && \
    git clone https://github.com/lmb-freiburg/netdef_models && \
    cd netdef_models                                        && \
    cd DispNet3  && bash download_snapshots.sh && cd ..     && \
    cd FlowNet3  && bash download_snapshots.sh && cd ..     && \
    cd FlowNetH  && bash download_snapshots.sh && cd ..
    #cd SceneFlow && bash download_snapshots.sh && cd ..
