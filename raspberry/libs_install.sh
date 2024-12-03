#!/bin/sh
dpkg --add-architecture arm64
apt-get -y update
apt-get -y install libopenblas-dev:arm64 liblapack-dev:arm64 libarpack2-dev:arm64 libsuperlu-dev:arm64

wget 'http://ports.ubuntu.com/pool/universe/a/armadillo/libarmadillo10_10.8.2+dfsg-1_arm64.deb' &&
sudo dpkg --install libarmadillo10_10.8.2+dfsg-1_arm64.deb &&
rm libarmadillo10_10.8.2+dfsg-1_arm64.deb
