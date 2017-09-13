# Install dependencies script

if [ $ARCH == "ubuntu" ]; then
    # install dev toolkit
    sudo apt-get update
    wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key|sudo apt-key add -
    sudo apt-get install clang-4.0 lldb-4.0 cmake make \
                         libbz2-dev libssl-dev libgmp3-dev \
                         autotools-dev build-essential \
                         libbz2-dev libicu-dev python-dev \
                         autoconf libtool git
    OPENSSL_ROOT_DIR= /usr/local/opt/openssl
    OPENSSL_LIBRARIES= /usr/local/opt/openssl/lib

    # install boost
    cd ${TEMP_DIR}
    wget -c 'https://sourceforge.net/projects/boost/files/boost/1.64.0/boost_1_64_0.tar.bz2/download' -O boost_1.64.0.tar.bz2
    tar xvf boost_1.64.0.tar.bz2 /tmp
    cd boost_1_64_0/
    ./bootstrap.sh
    ./b2 install --prefix=/usr
    rm -rf ${TEMP_DIR}/boost_1_64_0/

    # install secp256k1-zkp (Cryptonomex branch)
    cd ${TEMP_DIR}
    git clone https://github.com/cryptonomex/secp256k1-zkp.git
    cd secp256k1-zkp
    ./autogen.sh
    ./configure
    make
    sudo make install
    rm -rf cd ${TEMP_DIR}/secp256k1-zkp

    # install binaryen
    cd ${TEMP_DIR}
    git clone https://github.com/WebAssembly/binaryen
    cd binaryen
    git checkout tags/1.37.14
    cmake . && make
    mkdir /opt/binaryen
    mv ${TEMP_DIR}/binaryen/bin /opt/binaryen
    ln -s /opt/binaryen/bin/* /usr/local
    rm -rf ${TEMP_DIR}/binaryen
    BINARYEN_BIN=/opt/binaryen/bin/

    # build llvm with wasm build target:
    cd ${TEMP_DIR}
    mkdir wasm-compiler
    cd wasm-compiler
    git clone --depth 1 --single-branch --branch release_40 https://github.com/llvm-mirror/llvm.git
    cd llvm/tools
    git clone --depth 1 --single-branch --branch release_40 https://github.com/llvm-mirror/clang.git
    cd ..
    mkdir build
    cd build
    cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=/opt/wasm -DLLVM_TARGETS_TO_BUILD= -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=WebAssembly -DCMAKE_BUILD_TYPE=Release ../
    make -j4 install
    rm -rf ${TEMP_DIR}/wasm-compiler
    WASM_LLVM_CONFIG=/opt/wasm/bin/llvm-config
fi

if [ $ARCH == "darwin" ]; then
    DEPS="git automake libtool boost openssl llvm@4 gmp wget"
    brew update
    brew install --force $DEPS
    brew unlink $DEPS && brew link --force $DEPS
    # LLVM_DIR=/usr/local/Cellar/llvm/4.0.1/lib/cmake/llvm

    # install secp256k1-zkp (Cryptonomex branch)
    cd ${TEMP_DIR}
    git clone https://github.com/cryptonomex/secp256k1-zkp.git
    cd secp256k1-zkp
    ./autogen.sh
    ./configure
    make
    sudo make install
    rm -rf cd ${TEMP_DIR}/secp256k1-zkp

    # Install binaryen v1.37.14:
    cd ${TEMP_DIR}
    git clone https://github.com/WebAssembly/binaryen
    cd binaryen
    git checkout tags/1.37.14
    cmake . && make
    mkdir /usr/local/binaryen
    mv ${TEMP_DIR}/binaryen/bin /usr/local/binaryen
    ln -s /usr/local/binaryen/bin/* /usr/local
    rm -rf ${TEMP_DIR}/binaryen
    BINARYEN_BIN=/usr/local/binaryen/bin/

    # Build LLVM and clang for WASM:
    cd ${TEMP_DIR}
    mkdir wasm-compiler
    cd wasm-compiler
    git clone --depth 1 --single-branch --branch release_40 https://github.com/llvm-mirror/llvm.git
    cd llvm/tools
    git clone --depth 1 --single-branch --branch release_40 https://github.com/llvm-mirror/clang.git
    cd ..
    mkdir build
    cd build
    cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=/usr/local/wasm -DLLVM_TARGETS_TO_BUILD= -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=WebAssembly -DCMAKE_BUILD_TYPE=Release ../
    make -j4 install
    rm -rf ${TEMP_DIR}/wasm-compiler
    WASM_LLVM_CONFIG=/usr/local/wasm/bin/llvm-config

fi