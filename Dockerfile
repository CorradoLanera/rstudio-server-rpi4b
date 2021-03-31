# This Dockerfile builds an image for running RStudio Server for ARM64v8 RaspberryPi 4B
# This is a (bad) adaptation from:
# - https://github.com/jrowen/ARM-rstudio-server/blob/master/build_rstudio.sh
# - https://github.com/rstudio/rstudio/blob/master/docker/jenkins/Dockerfile.debian9-x86_64
# - https://github.com/rocker-org/rocker-versioned2/blob/master/scripts/install_rstudio.sh
FROM arm64v8/debian:stretch
ENV OPERATING_SYSTEM=debian9

# Set RStudio version
ENV VERS=v1.4.1106

# update apt repository to cloudfront's mirror
RUN set -x \
    && sed -i "s/deb.debian.org/cloudfront.debian.net/" /etc/apt/sources.list \
    && sed -i "s/security.debian.org/cloudfront.debian.net/" /etc/apt/sources.list

# update system
RUN set -x \
    && apt-get update -y \
    && apt-get install --no-install-recommends -y \
    apt-utils \
    && apt-get -y upgrade

# Install required packages.
# NOTE: this bring also the first part of (excluding ./install-common):
#   - https://github.com/rstudio/rstudio/blob/master/dependencies/linux/install-dependencies-stretch
ENV TZ=Europe/Rome
RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone \
    && apt-get update \
    && apt-get install --no-install-recommends -y \
    ant \
    bzip2 \
    clang \
    clang-4.0 \
    cmake \
    curl \
    debsigs \
    dpkg-sig \
    expect \
    fakeroot \
    gcc \
    git \
    gnupg1 \
    libacl1-dev \
    libattr1-dev \
    libboost-all-dev \
    libcap-dev \
    libcurl4-openssl-dev \
    libffi-dev \
    libglib2.0-dev \
    libpam0g-dev \
    libpango-1.0-0 \
    libpq-dev \
    libsqlite-dev \
    libsqlite3-dev \
    libssl-dev \
    libuser1-dev \
    libxml2-dev \
    libxml-commons-external-java \
    locales \
    lsb-core \
    lsof \
    make \
    mesa-common-dev \
    openjdk-8-jdk  \
    pandoc \
    patchelf \
    procps \
    python \
    p7zip-full \
    r-base \
    r-base-dev \
    rrdtool \
    sudo \
    tzdata \
    uuid-dev \
    valgrind \
    wget \
    zlib1g

RUN  update-alternatives --install /usr/bin/clang clang /usr/bin/clang-4.0 100 \
    && update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-4.0 100

ENV PATH=/usr/lib/llvm-4.0/bin:$PATH

# Download RStudio source
RUN mkdir -p /Downloads
RUN mkdir -p /build/rstudio-${VERS}
WORKDIR Download
RUN wget -O ${VERS} https://github.com/rstudio/rstudio/tarball/${VERS} \
    && tar xvf ${VERS} -C /build/rstudio-${VERS} --strip-components 1 \
    && rm ${VERS}

# run equivalent of ./install-common plus other dependencies
# run install-boost twice - boost exits 1 even though it has installed good enough for our uses.
# https://github.com/rstudio/rstudio/blob/master/vagrant/provision-primary-user.sh#L12-L15
WORKDIR /build/rstudio-${VERS}/dependencies/common/
RUN ./install-boost || ./install-boost \
   && ./install-cef \
#   && ./install-crashpad ${OPERATING_SYSTEM} \ # Return error when build RStudio: /opt/rstudio-tools/crashpad/crashpad/out/Default/obj/client/libclient.a: error adding symbols: File in wrong format \\ collect2: error: ld returned 1 exit status
   && ./install-dictionaries \
   && ./install-mathjax \
   && ./install-packages \
   && ./install-pandoc \
   && ./install-sentry-cli \
   && ./install-soci

RUN wget https://nodejs.org/dist/v10.19.0/node-v10.19.0-linux-arm64.tar.xz \
    && tar -xf node-v10.19.0-linux-arm64.tar.xz \
    && cd node-v10.19.0-linux-arm64/ \
    && sudo cp -R * /usr/local/ \
    && mkdir -p /build/rstudio-${VERS}/dependencies/common/node/10.19.0/ \
    && sudo cp -R * /build/rstudio-${VERS}/dependencies/common/node/10.19.0/ \
    && npm install -g yarn

# copy panmirror project setup
WORKDIR /build/rstudio-${VERS}/
RUN mkdir -p /opt/rstudio-tools/panmirror \
   && cp src/gwt/panmirror/src/editor/yarn.lock /opt/rstudio-tools/panmirror/ \
   && cp src/gwt/panmirror/src/editor/package.json /opt/rstudio-tools/panmirror/

ENV INSTALL_PATH="/usr/local/bin:${PATH}"
RUN PATH=${INSTALL_PATH} yarn config set ignore-engines true \
    && PATH=${INSTALL_PATH} yarn install

# Add pandoc folder to override build check
RUN mkdir -p /build/rstudio-$VERS/dependencies/common/pandoc

# Configure cmake and build RStudio
WORKDIR /build/rstudio-${VERS}
RUN mkdir build \
    && cmake -DRSTUDIO_TARGET=Server -DCMAKE_BUILD_TYPE=Release \
    && make install

# Additional install steps
RUN useradd -r rstudio-server \ 
    && cp /usr/local/lib/rstudio-server/extras/init.d/debian/rstudio-server /etc/init.d/rstudio-server \
    && chmod +x /etc/init.d/rstudio-server \
    && ln -f -s /usr/local/lib/rstudio-server/bin/rstudio-server /usr/sbin/rstudio-server \
    && chmod 777 -R /usr/local/lib/R/site-library/

# Setup local
RUN DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales \
    && export LANG=en_US.UTF-8 \
    && export LANGUAGE=en_US.UTF-8 \
    && echo 'export LANG=en_US.UTF-8' >> ~/.bashrc \
    && echo 'export LANGUAGE=en_US.UTF-8' >> ~/.bashrc

# Clean the system of packages used for building
RUN apt-get autoremove -y \
    cabal-install \
    ghc \
    openjdk-7-jdk \
    pandoc \
    libboost-all-dev \
    && rm -rf /build \
    && rm -rf /Downloads \
    && apt-get autoremove -y

EXPOSE 8787
CMD ["rstudio-server", "start"]
