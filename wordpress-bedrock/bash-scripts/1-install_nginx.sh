#!/bin/bash -e
# 1-install_nginx.sh
# Author: Aaron Luna
# Website: alunablog.com
#
# This script downloads the source code for the latest version of NGINX
# (libraries required to build various NGINX modules are also downloaded)
# and builds NGINX according to the options specified in the ./configure
# command. Many of the possible configuration options are explained at
# the link below:
#
# https://www.nginx.com/resources/wiki/start/topics/tutorials/installoptions/
#
# This script includes examples of various ways NGINX can be customized
# such as: specifying the version of OpenSSL or GeoIP libraries to use, 
# adding modules NOT enabled by default and adding third-party modules
# such as the GeoIP2 and cache purge modules.
#
# This script produces a .deb package file which can be used to 
# uninstall this version of NGINX via apt-get remove nginx or 
# dpkg ––remove nginx. The .deb package can also be used to install 
# this version of nginx on another system with the same architecture. 
# For more info on the checkinstall program which creates the .deb 
# package, please see:
#
# https://wiki.debian.org/CheckInstall
#
# After NGINX is built, all of the source code is added to a .tar.gz
# archive file and stored in the $DEB_PKG_FOLDER_PATH along with the
# .deb package file.
##########################################################################
# Environment Variables 
#
# DO NOT EDIT THESE VALUES IN THIS FILE, THESE VARIABLES ARE DEFINED IN
# THE PACKER TEMPLATE AND SHARED ACROSS SHELL SCRIPTS. MAKE ANY CHANGES
# TO THESE VARIABLES IN THE PACKER TEMPLATE JSON FILE.

NGINX_PRE=nginx-
PCRE_PRE=pcre-
ZLIB_PRE=zlib-
OPENSSL_PRE=openssl-
EXT_TAR=.tar.gz

SRC_FOLDER_PATH=${WORKING_DIR}/${SRC_FOLDER}
DEB_PKG_FOLDER_PATH=${WORKING_DIR}/${DEB_PKG_FOLDER}
INSTALL_LOG_FOLDER_PATH=${WORKING_DIR}/${LOG_FOLDER}
INSTALL_LOG_FILE_PATH=${INSTALL_LOG_FOLDER_PATH}/${LOG_FILE}

NGINX_SRC_FOLDER_PATH=${SRC_FOLDER_PATH}/${NGINX_PRE}${NGINX_VER}
PCRE_SRC_FOLDER_PATH=${SRC_FOLDER_PATH}/${PCRE_PRE}${PCRE_VER}
ZLIB_SRC_FOLDER_PATH=${SRC_FOLDER_PATH}/${ZLIB_PRE}${ZLIB_VER}
OPENSSL_SRC_FOLDER_PATH=${SRC_FOLDER_PATH}/${OPENSSL_PRE}${OPENSSL_VER}

NGINX_SRC_TAR=${NGINX_PRE}${NGINX_VER}${EXT_TAR}
PCRE_SRC_TAR=${PCRE_PRE}${PCRE_VER}${EXT_TAR}
ZLIB_SRC_TAR=${ZLIB_PRE}${ZLIB_VER}${EXT_TAR}
OPENSSL_SRC_TAR=${OPENSSL_PRE}${OPENSSL_VER}${EXT_TAR}

ALL_SRC_FILES_TAR=${NGINX_PRE}${NGINX_VER}-${SRC_FOLDER}${EXT_TAR}
DEB_PKG_FILE=nginx_${NGINX_VER}-1_amd64.deb

##########################################################################
# BEGIN SCRIPT EXECUTION
#
# NOTE: If building NGINX on Amazon EC2 instance with ubuntu 16.04 or 17.10
#       use the following command which is commented out in line 167: 
#       "sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y"
#       (and comment out line 166)
#
#       if you call "sudo apt upgrade -y" without the noninteractive
#       setting a prompt asking for a decision re: grub version conflict
#       will cause the script to hang. If run as part of a packer template,
#       the user will be unable to interact with the prompt and must cancel
#       the script via Ctrl+C.
#
#       I tested this with ubuntu versions 14.04, 16.04 and 17.10 with 
#       VM instances from 3 different vendors (Amazon EC2, VMWare Fusion, 
#       VirtualBox) and the issue only occurrs with EC2 instances running
#       16.04 and 17.10. It is unknown if this issue exists with older
#       distributions or VM instances from other vendors.
#
##########################################################################

sudo mkdir -p $SRC_FOLDER_PATH
sudo mkdir -p $DEB_PKG_FOLDER_PATH
sudo mkdir -p $INSTALL_LOG_FOLDER_PATH
sudo touch $INSTALL_LOG_FILE_PATH

sudo chown ubuntu:ubuntu $SRC_FOLDER_PATH
sudo chown ubuntu:ubuntu $DEB_PKG_FOLDER_PATH
sudo chown ubuntu:ubuntu $INSTALL_LOG_FOLDER_PATH
sudo chown ubuntu:ubuntu $INSTALL_LOG_FILE_PATH

echo "$(date +"%d-%b-%Y-%H-%M-%S") | Updating ubuntu..." |& tee -a ${INSTALL_LOG_FILE_PATH}

# Add Maxmind PPA to apt sources
sudo add-apt-repository ppa:maxmind/ppa -y >> ${INSTALL_LOG_FILE_PATH} 2>&1

# Update OS
sudo apt update >> ${INSTALL_LOG_FILE_PATH} 2>&1 && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y >> ${INSTALL_LOG_FILE_PATH} 2>&1
sudo apt autoremove -y >> ${INSTALL_LOG_FILE_PATH} 2>&1

echo "$(date +"%d-%b-%Y-%H-%M-%S") | Installing prerequisites..." |& tee -a ${INSTALL_LOG_FILE_PATH}

# Install build tools (gcc, g++, etc)
sudo apt install build-essential -y >> ${INSTALL_LOG_FILE_PATH} 2>&1

# Install legacy GeoIP libraries
sudo apt install geoip-bin libgeoip1 libgeoip-dev -y >> ${INSTALL_LOG_FILE_PATH} 2>&1

# Install GeoIP2 libraries
sudo apt install libmaxminddb0 libmaxminddb-dev mmdb-bin -y >> ${INSTALL_LOG_FILE_PATH} 2>&1

# Install checkinstall to create .deb package file
sudo apt install checkinstall -y >> ${INSTALL_LOG_FILE_PATH} 2>&1

# Install Uncomplicated Firewall (UFW) since NGINX app profile 
# is created after install and directory is assumed to exist
sudo apt install ufw -y >> ${INSTALL_LOG_FILE_PATH} 2>&1

echo "$(date +"%d-%b-%Y-%H-%M-%S") | Downloading source files..." |& tee -a ${INSTALL_LOG_FILE_PATH}

# Download and extract the source code for the latest version of NGINX
cd $SRC_FOLDER_PATH
sudo wget http://nginx.org/download/$NGINX_SRC_TAR >> ${INSTALL_LOG_FILE_PATH} 2>&1 && \
  sudo tar xzf $NGINX_SRC_TAR >> ${INSTALL_LOG_FILE_PATH} 2>&1
  
# Download and extract the latest versions of PCRE, zlib and OpenSSL libraries
sudo wget https://ftp.pcre.org/pub/pcre/${PCRE_SRC_TAR} >> ${INSTALL_LOG_FILE_PATH} 2>&1 && \
  sudo tar xzf $PCRE_SRC_TAR >> ${INSTALL_LOG_FILE_PATH} 2>&1
sudo wget http://zlib.net/${ZLIB_SRC_TAR} >> ${INSTALL_LOG_FILE_PATH} 2>&1 && \
  sudo tar xzf $ZLIB_SRC_TAR >> ${INSTALL_LOG_FILE_PATH} 2>&1
sudo wget https://www.openssl.org/source/${OPENSSL_SRC_TAR} >> ${INSTALL_LOG_FILE_PATH} 2>&1 && \
  sudo tar xzf $OPENSSL_SRC_TAR >> ${INSTALL_LOG_FILE_PATH} 2>&1
  
# Download (third party) NGINX modules: cache purge and GeoIP2
# The GeoIP module included with NGINX only works with v1 MaxMind database files
# V2 database files are far superior, see here for more info:
# https://dev.maxmind.com/geoip/geoip2/whats-new-in-geoip2/
sudo git clone --recursive https://github.com/FRiCKLE/ngx_cache_purge.git >> ${INSTALL_LOG_FILE_PATH} 2>&1
sudo git clone --recursive https://github.com/leev/ngx_http_geoip2_module.git >> ${INSTALL_LOG_FILE_PATH} 2>&1

# Remove archive files
sudo rm -rf *.tar.gz >> ${INSTALL_LOG_FILE_PATH} 2>&1

echo "$(date +"%d-%b-%Y-%H-%M-%S") | Building NGINX from source..." |& tee -a ${INSTALL_LOG_FILE_PATH}

# Configure the build options for NGINX
cd $NGINX_SRC_FOLDER_PATH
sudo ./configure \
  --prefix=/usr/share/nginx \
  --sbin-path=/usr/sbin/nginx \
  --conf-path=/etc/nginx/nginx.conf \
  --error-log-path=/var/log/nginx/error.log \
  --http-log-path=/var/log/nginx/access.log \
  --pid-path=/run/nginx.pid \
  --user=www-data \
  --group=www-data \
  --build=Ubuntu \
  --http-client-body-temp-path=/var/lib/nginx/body \
  --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
  --http-proxy-temp-path=/var/lib/nginx/proxy \
  --http-scgi-temp-path=/var/lib/nginx/scgi \
  --http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
  --with-openssl=$OPENSSL_SRC_FOLDER_PATH \
  --with-openssl-opt=enable-ec_nistp_64_gcc_128 \
  --with-openssl-opt=no-nextprotoneg \
  --with-openssl-opt=no-weak-ssl-ciphers \
  --with-openssl-opt=no-ssl3 \
  --with-pcre=$PCRE_SRC_FOLDER_PATH \
  --with-pcre-jit \
  --with-zlib=$ZLIB_SRC_FOLDER_PATH \
  --with-compat \
  --with-file-aio \
  --with-threads \
  --with-http_addition_module \
  --with-http_auth_request_module \
  --with-http_dav_module \
  --with-http_flv_module \
  --with-http_geoip_module \
  --with-http_gunzip_module \
  --with-http_gzip_static_module \
  --with-http_mp4_module \
  --with-http_random_index_module \
  --with-http_realip_module \
  --with-http_slice_module \
  --with-http_ssl_module \
  --with-http_sub_module \
  --with-http_stub_status_module \
  --with-http_v2_module \
  --with-http_secure_link_module \
  --with-mail \
  --with-mail_ssl_module \
  --with-stream \
  --with-stream_realip_module \
  --with-stream_ssl_module \
  --with-stream_ssl_preread_module \
  --with-debug \
  --add-module=../ngx_http_geoip2_module \
  --add-module=../ngx_cache_purge \
  --with-cc-opt='-g -O2 -fstack-protector --param=ssp-buffer-size=4 -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2' \
  --with-ld-opt='-Wl,-z,relro -Wl,--as-needed' >> ${INSTALL_LOG_FILE_PATH} 2>&1
  
# Build nginx with the specified configuration
sudo make >> ${INSTALL_LOG_FILE_PATH} 2>&1

# Create a .deb package (instead of running `sudo make install`)
sudo checkinstall --install=no -y >> ${INSTALL_LOG_FILE_PATH} 2>&1 

echo -e "$(date +"%d-%b-%Y-%H-%M-%S") | Installing NGINX from .deb package..." |& tee -a ${INSTALL_LOG_FILE_PATH}

# Install the .deb package, this allows uninstall via apt-get
sudo dpkg -i ${DEB_PKG_FILE} >> ${INSTALL_LOG_FILE_PATH} 2>&1 

echo "$(date +"%d-%b-%Y-%H-%M-%S") | Creating archive of source files..." |& tee -a ${INSTALL_LOG_FILE_PATH}

# Move the .deb package to a new folder since we are going to create an
# archive from the directory containing the downloaded source code files,
# which is our current working directory
sudo mv ${DEB_PKG_FILE} ${DEB_PKG_FOLDER_PATH}/${DEB_PKG_FILE} >> ${INSTALL_LOG_FILE_PATH} 2>&1

# Create an archive containing all the source files needed to build NGINX and
# compress the files using the .tar.gz format
cd $SRC_FOLDER_PATH
sudo tar -zcf ../$ALL_SRC_FILES_TAR . >> ${INSTALL_LOG_FILE_PATH} 2>&1
echo -e "$(date +"%d-%b-%Y-%H-%M-%S") | Created $ALL_SRC_FILES_TAR" |& tee -a ${INSTALL_LOG_FILE_PATH}

cd ..
sudo mv $ALL_SRC_FILES_TAR $DEB_PKG_FOLDER_PATH >> ${INSTALL_LOG_FILE_PATH} 2>&1

# Make both .deb package and source files archive executable by all users
sudo chmod 755 ${DEB_PKG_FOLDER_PATH}/nginx*.* >> ${INSTALL_LOG_FILE_PATH} 2>&1

echo "$(date +"%d-%b-%Y-%H-%M-%S") | Removing source files..." |& tee -a ${INSTALL_LOG_FILE_PATH}
# Remove all source files
sudo rm -rf $SRC_FOLDER_PATH

echo -e "$(date +"%d-%b-%Y-%H-%M-%S") | Installation complete\n" |& tee -a ${INSTALL_LOG_FILE_PATH}