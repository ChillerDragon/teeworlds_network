#!/bin/bash

set -e

sudo apt-get update -y
sudo apt-get install -y tcpdump tshark
sudo apt-get install -y shellcheck teeworlds-server teeworlds teeworlds-data
sudo apt install -y build-essential glslang-tools libavcodec-extra libavdevice-dev libavfilter-dev libavformat-dev libavutil-dev libcurl4-openssl-dev libfreetype6-dev libglew-dev libnotify-dev libogg-dev libopus-dev libopusfile-dev libpng-dev libsdl2-dev libsqlite3-dev libssl-dev libvulkan-dev libwavpack-dev libx264-dev
gem install bundler
gem install rubocop:1.31.2
bundle install --jobs 4 --retry 3

wget https://github.com/ChillerDragon/teeworlds/releases/download/v0.7.5-headless/teeworlds-0.7.5-linux_x86_64.tar.gz
tar -xvzf teeworlds-0.7.5-linux_x86_64.tar.gz
sudo mkdir -p /usr/local/bin/
sudo mv teeworlds-0.7.5-linux_x86_64/teeworlds /usr/local/bin/teeworlds-headless
rm -rf teeworlds-0.7.5-linux_x86_64*

wget https://github.com/ChillerDragon/ddnet/releases/download/v16.5-headless/DDNet-headless.zip
unzip DDNet-headless.zip
sudo mv DDNet-headless /usr/local/bin
rm DDNet-headless.zip

wget https://github.com/ChillerDragon/ddnet/releases/download/v17.4.2-headless-0.7/DDNet7-headless-linux.zip
unzip DDNet7-headless-linux.zip
chmod +x DDNet7-headless
sudo mv DDNet7-headless /usr/local/bin
rm DDNet7-headless-linux.zip

echo 'TODO: remove this ugly hack!'
mkdir -p ~/.teeworlds/downloadedmaps
cd ~/.teeworlds/downloadedmaps
wget https://heinrich5991.de/teeworlds/maps/maps/dm1_64548818.map
