FROM ubuntu:24.04

RUN apt-get update -y && apt-get install -y sudo
RUN sudo apt-get install -y ruby ruby-dev
RUN sudo apt-get install -y tcpdump tshark
RUN sudo apt-get install -y shellcheck teeworlds-server teeworlds teeworlds-data
RUN sudo apt install -y build-essential glslang-tools libavcodec-extra libavdevice-dev libavfilter-dev libavformat-dev libavutil-dev libcurl4-openssl-dev libfreetype6-dev libglew-dev libnotify-dev libogg-dev libopus-dev libopusfile-dev libpng-dev libsdl2-dev libsqlite3-dev libssl-dev libvulkan-dev libwavpack-dev libx264-dev
RUN sudo apt-get install -y wget

RUN wget https://github.com/ChillerDragon/teeworlds/releases/download/v0.7.5-headless/teeworlds-0.7.5-linux_x86_64.tar.gz
RUN tar -xvzf teeworlds-0.7.5-linux_x86_64.tar.gz
RUN sudo mkdir -p /usr/local/bin/
RUN sudo mv teeworlds-0.7.5-linux_x86_64/teeworlds /usr/local/bin/teeworlds-headless
RUN rm -rf teeworlds-0.7.5-linux_x86_64*

RUN wget https://github.com/ChillerDragon/ddnet/releases/download/v16.5-headless/DDNet-headless.zip
RUN unzip DDNet-headless.zip
RUN sudo mv DDNet-headless /usr/local/bin
RUN rm DDNet-headless.zip

RUN wget https://github.com/ChillerDragon/ddnet/releases/download/v17.4.2-headless-0.7/DDNet7-headless-ubuntu24.zip
RUN unzip DDNet7-headless-ubuntu24.zip
RUN chmod +x DDNet7-headless
RUN sudo mv DDNet7-headless /usr/local/bin
RUN rm DDNet7-headless-ubuntu24.zip

RUN echo 'TODO: remove this ugly hack!'
RUN mkdir -p ~/.teeworlds/downloadedmaps
RUN cd ~/.teeworlds/downloadedmaps && wget https://heinrich5991.de/teeworlds/maps/maps/dm1_64548818.map

RUN gem install bundler
RUN gem install rubocop:1.31.2

USER 1000

WORKDIR /teeworlds_network
COPY . .

RUN bundle install --jobs 4 --retry 3


RUN echo '[CLIENT] Test sending chat messages'
RUN ./integration_test/run.sh client/chat.rb
RUN echo '[CLIENT] Test reconnect'
RUN ./integration_test/run.sh client/reconnect.rb
RUN echo '[CLIENT] Test rcon'
RUN ./integration_test/run.sh client/rcon.rb
RUN echo '[SERVER] Test connect'
RUN ./integration_test/run.sh server/connect.rb
RUN echo '[SERVER] Test chat'
RUN ./integration_test/run.sh server/chat.rb

