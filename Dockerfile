# docker build -t accetto/ubuntu-vnc-xfce .
# docker build --build-arg BASETAG=rolling -t accetto/ubuntu-vnc-xfce:rolling .

ARG BASETAG=latest

FROM ubuntu:${BASETAG}

ENV REFRESHED_AT 2018-05-10

LABEL vendor="accetto" \
    maintainer="https://github.com/accetto" \
    any.accetto.description="Headless Ubuntu VNC/noVNC container with Xfce desktop" \
    any.accetto.display-name="Headless Ubuntu/Xfce VNC/noVNC container" \
    any.accetto.expose-services="6901:http,5901:xvnc" \
    any.accetto.tags="ubuntu, xfce, vnc, novnc"

### Arguments can be provided during build
ARG HOME=/headless
ARG VNC_PW=headless
ARG VNC_BLACKLIST_THRESHOLD=20
ARG VNC_BLACKLIST_TIMEOUT=0

SHELL ["/bin/bash", "-c"]

### Environment config
ENV \
    DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:1 \
    HOME=$HOME \
    INST_SCRIPTS=$HOME/install \
    NO_VNC_HOME=$HOME/noVNCdim \
    NO_VNC_PORT="6901" \
    STARTUPDIR=/dockerstartup \
    VNC_BLACKLIST_THRESHOLD=$VNC_BLACKLIST_THRESHOLD \
    VNC_BLACKLIST_TIMEOUT=$VNC_BLACKLIST_TIMEOUT \
    VNC_COL_DEPTH=24 \
    VNC_PORT="5901" \
    VNC_PW=$VNC_PW \
    VNC_RESOLUTION="1360x768" \
    VNC_VIEW_ONLY=false 

WORKDIR $HOME

### Be sure to use the root user
USER 0

### Copy install scripts and Xfce stuff
COPY ./src/ubuntu/install/ $INST_SCRIPTS/
COPY ./src/xfce/ $HOME/

### Install common tools, VNC, Xfce, create common folders and remove some stuff
RUN find $INST_SCRIPTS -name '*.sh' -exec chmod a+x {} +
RUN $INST_SCRIPTS/tools.sh \
    && $INST_SCRIPTS/tigervnc.sh \
    && $INST_SCRIPTS/no_vnc.sh \
    && $INST_SCRIPTS/xfce_ui.sh \
    && apt-get purge -y pavucontrol pulseaudio \
    && apt-get autoremove -y

### Set locale variables
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'    

### Configure startup and clean up scripts
COPY ./src/ubuntu/startup $STARTUPDIR
RUN $INST_SCRIPTS/libnss_wrapper.sh \
    && rm -r $INST_SCRIPTS

### Exposed VNC/noVNC ports for remote access
### VNC port: 5901, use a VNC Viewer
### noVNC port: 6901, full client: http://IP:6901/vnc.html
### noVNC port: 6901, light client: http://IP:6901/vnc_lite.html
EXPOSE $VNC_PORT $NO_VNC_PORT

ENTRYPOINT ["/dockerstartup/vnc_startup.sh"]
CMD ["--wait"]
