#!/bin/bash -l

set -exo pipefail

CWDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOP_DIR=${CWDIR}/../../../


if [ "$OSVER" == "centos5" ]; then
    alias gcc=gcc44
fi

if [ "$OSVER" == "suse11" ]; then
    zypper addrepo http://download.opensuse.org/distribution/11.4/repo/oss/ oss
    zypper --no-gpg-checks -n install -f binutils
    zypper --no-gpg-checks -n install subversion
    zypper --no-gpg-checks -n install gcc gcc-c++ gcc-fortran
    zypper --no-gpg-checks -n install texlive
    zypper --no-gpg-checks -n install texlive-latex
    zypper --no-gpg-checks -n install libopenssl-devel openssl
    zypper --no-gpg-checks -n install wget
else
    yum install -y subversion
    yum install -y gcc gcc-c++ gcc-gfortran
    yum install -y 'texlive-*'
fi


# Zlib dependency
wget --no-check-certificate https://github.com/madler/zlib/archive/v1.2.8.tar.gz -O v1.2.8.tar.gz
tar zxvf v1.2.8.tar.gz
pushd zlib-1.2.8
./configure --prefix=/usr/local/lib64/zlib
make -j
make install
export LD_LIBRARY_PATH=/usr/local/lib64/zlib/lib:$LD_LIBRARY_PATH
export CFLAGS="$CFLAGS -I/usr/local/lib64/zlib/include"
popd


# BZip2 dependency
wget http://www.bzip.org/1.0.6/bzip2-1.0.6.tar.gz
tar zxvf bzip2-1.0.6.tar.gz
pushd bzip2-1.0.6
make -f Makefile-libbz2_so
make -j
make install PREFIX=/usr/local/lib64/bzip2
ln -s libbz2.so.1.0.6 libbz2.so.1
ln -s libbz2.so.1     libbz2.so
cp libbz2.so* /usr/local/lib64/bzip2/lib
export LD_LIBRARY_PATH=/usr/local/lib64/bzip2/lib:$LD_LIBRARY_PATH
export CFLAGS="$CFLAGS -I/usr/local/lib64/bzip2/include"
popd

# LZMA dependency
wget --no-check-certificate http://tukaani.org/xz/xz-5.2.2.tar.gz
tar zxvf xz-5.2.2.tar.gz
pushd xz-5.2.2
if [ "$OSVER" == "centos7" ]; then
    cp ${TOP_DIR}/plr_src/concourse/scripts/xz.patch ./src/liblzma/liblzma.map
fi
./configure --prefix=/usr/local/lib64/xz
make
make install
export LD_LIBRARY_PATH=/usr/local/lib64/xz/lib:$LD_LIBRARY_PATH
export CFLAGS="$CFLAGS -I/usr/local/lib64/xz/include"
popd

# PCRE dependency
wget ftp://ftp.pcre.org/pub/pcre/pcre-8.39.tar.gz
tar zxvf pcre-8.39.tar.gz
pushd pcre-8.39
./configure --enable-utf --enable-unicode-properties --enable-jit --disable-cpp --prefix=/usr/local/lib64/pcre
make -j
make install
export LD_LIBRARY_PATH=/usr/local/lib64/pcre/lib:$LD_LIBRARY_PATH
export CFLAGS="$CFLAGS -I/usr/local/lib64/pcre/include"
popd

# Texinfo for building documentation
wget http://ftp.gnu.org/gnu/texinfo/texinfo-6.1.tar.gz
tar zxvf texinfo-6.1.tar.gz
pushd texinfo-6.1
./configure --prefix=/usr/local/lib64/texinfo
make -j
make install
popd
export PATH=/usr/local/lib64/texinfo/bin/:$PATH

if [ "$OSVER" == "suse11" ]; then
    # Neon to make SVN work in SUSE
    wget http://www.webdav.org/neon/neon-0.30.0.tar.gz
    tar zxvf neon-0.30.0.tar.gz
    pushd neon-0.30.0
    ./configure --prefix=/usr/local/lib64/neon --enable-shared --with-ssl=openssl
    make -j
    make install
    popd
    export LD_LIBRARY_PATH=/usr/local/lib64/neon/lib:$LD_LIBRARY_PATH

    # Curl
    # export CFLAGS="$CFLAGS -I/usr/local/lib64/curl/include"
    wget http://curl.askapache.com/download/curl-7.54.1.tar.gz
    tar zxvf curl-7.54.1.tar.gz
    pushd curl-7.54.1
    ./configure --prefix=/usr/local/lib64/curl --disable-ldap --disable-ldaps
    make -j
    make install
    popd
    export LD_LIBRARY_PATH=/usr/local/lib64/curl/lib:$LD_LIBRARY_PATH
    export PATH=/usr/local/lib64/curl/bin/:$PATH


fi

export LIBRARY_PATH=$LD_LIBRARY_PATH

echo p | svn checkout https://svn.r-project.org/R/branches/R-3-3-branch/
pushd R-3-3-branch
./tools/rsync-recommended
./configure --prefix=/usr/lib64/R --with-x=no --with-readline=no --enable-R-shlib --disable-rpath
make -j
make install
popd

# Magic to make it work from any directory it is installed into
# given the fact R_HOME is set
sed -i 's/\/usr\/lib64\/R\/lib64\/R/${R_HOME}/g' /usr/lib64/R/bin/R
sed -i 's/\/usr\/lib64\/R\/lib64\/R/${R_HOME}/g' /usr/lib64/R/lib64/R/bin/R

mkdir /usr/lib64/R/lib64/R/extlib
cp /usr/local/lib64/zlib/lib/libz.so.1      /usr/lib64/R/lib64/R/extlib
cp /usr/local/lib64/xz/lib/liblzma.so.5     /usr/lib64/R/lib64/R/extlib
cp /usr/local/lib64/pcre/lib/libpcre.so.1   /usr/lib64/R/lib64/R/extlib

case $OSVER in
    centos5)
        cp /usr/local/lib64/bzip2/lib/libbz2.so.1.0 /usr/lib64/R/lib64/R/extlib
#        cp /usr/local/curl/lib/libcurl.so.4         /usr/lib64/R/lib64/R/extlib
        cp /usr/lib64/libgomp.so.1                  /usr/lib64/R/lib64/R/extlib
        cp /usr/lib64/libgfortran.so.1              /usr/lib64/R/lib64/R/extlib
#        cp /lib64/libssl.so.6                       /usr/lib64/R/lib64/R/extlib
#        cp /lib64/libcrypto.so.6                    /usr/lib64/R/lib64/R/extlib
    ;;
    centos6)
        cp /usr/local/lib64/bzip2/lib/libbz2.so.1.0 /usr/lib64/R/lib64/R/extlib
#        cp /usr/local/curl/lib/libcurl.so.4         /usr/lib64/R/lib64/R/extlib
        cp /usr/lib64/libgomp.so.1                  /usr/lib64/R/lib64/R/extlib
        cp /usr/lib64/libgfortran.so.3              /usr/lib64/R/lib64/R/extlib
#        cp /usr/lib64/libssl.so.10                  /usr/lib64/R/lib64/R/extlib
#        cp /usr/lib64/libcrypto.so.10               /usr/lib64/R/lib64/R/extlib
    ;;
    centos7)
        cp /usr/local/lib64/bzip2/lib/libbz2.so.1.0 /usr/lib64/R/lib64/R/extlib
#        cp /usr/local/curl/lib/libcurl.so.4         /usr/lib64/R/lib64/R/extlib
        cp /usr/lib64/libgomp.so.1                  /usr/lib64/R/lib64/R/extlib
        cp /usr/lib64/libgfortran.so.3              /usr/lib64/R/lib64/R/extlib
#        cp /usr/lib64/libssl.so.10                  /usr/lib64/R/lib64/R/extlib
#        cp /usr/lib64/libcrypto.so.10               /usr/lib64/R/lib64/R/extlib
        cp /usr/lib64/libquadmath.so.0              /usr/lib64/R/lib64/R/extlib
    ;;
    suse*)
        cp /usr/local/lib64/bzip2/lib/libbz2.so.1   /usr/lib64/R/lib64/R/extlib
 #       cp /usr/local/lib64/curl/lib/libcurl.so.4   /usr/lib64/R/lib64/R/extlib
        cp /usr/lib64/libgomp.so.1        /usr/lib64/R/lib64/R/extlib
        cp /usr/lib64/libgfortran.so.3    /usr/lib64/R/lib64/R/extlib
#        cp /lib64/libssl.so.1.0.0                   /usr/lib64/R/lib64/R/extlib
#        cp /lib64/libcrypto.so.1.0.0                /usr/lib64/R/lib64/R/extlib
    ;;
esac

pushd /usr/lib64
tar zcvf bin_r_$OSVER.tar.gz ./R
popd
cp /usr/lib64/bin_r_$OSVER.tar.gz $TOP_DIR/bin_r/