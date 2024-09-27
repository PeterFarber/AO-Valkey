#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

BUILD_JSON=${1:-1}
BUILD_SEARCH=${2:-1}
BUILD_VALKEY=${3:-1}

CLONE_JSON=0
CLONE_SEARCH=0
CLONE_VALKEY=0

RS_SETUP=0

echo "Building Valkey: ${BUILD_VALKEY}"
echo "Building RedisJSON: ${BUILD_JSON}"
echo "Building RediSearch: ${BUILD_SEARCH}"

VALKEY_DIR="${SCRIPT_DIR}/valkey"
REDISJSON_DIR="${SCRIPT_DIR}/RedisJSON"
REDISEARCH_DIR="${SCRIPT_DIR}/RediSearch"
AOVALKEY_DIR="${SCRIPT_DIR}/AOValkey"

LIBS_DIR="${SCRIPT_DIR}/libs"
INJECT_DIR="${SCRIPT_DIR}/inject"
PROCESS_DIR="${SCRIPT_DIR}/aos/process"
TEST_DIR="${SCRIPT_DIR}/tests"


AO_IMAGE="ao32:latest"

EMXX_CFLAGS="-sMEMORY64=1 -sSUPPORT_LONGJMP=1 /lua-5.3.4/src/liblua.a -I/lua-5.3.4/src"
C_FLAGS="-DUSE_PROCESSOR_CLOCK"


# Clone valkey if it doesn't exist
if [ "$BUILD_VALKEY" -eq 1 ]; then
	if [ "$CLONE_VALKEY" -eq 1 ]; then
		sudo rm -rf ${VALKEY_DIR}
		if [ ! -d "$VALKEY_DIR" ]; then
			git clone https://github.com/valkey-io/valkey.git valkey
			cd ${VALKEY_DIR} && git checkout 8.0
		fi
		cd ${SCRIPT_DIR}
	fi
	cp -a ${INJECT_DIR}/. ${VALKEY_DIR}/

	docker run -v ${VALKEY_DIR}:/valkey --platform linux/amd64 ${AO_IMAGE} sh -c \
    "cd /valkey && apt-get install -y pkg-config libc6-dev && \
    emmake make distclean && emmake make MALLOC='libc' \
    CC='emcc ${EMXX_CFLAGS}' CFLAGS='${C_FLAGS}'"

	cp ${VALKEY_DIR}/src/valkey-server.a ${LIBS_DIR}/valkey-server.a
	cp ${VALKEY_DIR}/deps/fpconv/libfpconv.a ${LIBS_DIR}/libfpconv.a
	cp ${VALKEY_DIR}/deps/hdr_histogram/libhdrhistogram.a ${LIBS_DIR}/libhdrhistogram.a
	cp ${VALKEY_DIR}/deps/hiredis/libhiredis.a ${LIBS_DIR}/libhiredis.a

fi

# Clone REDISJSON
if [ "$BUILD_JSON" -eq 1 ]; then
	if [ "$CLONE_JSON" -eq 1 ]; then
		sudo rm -rf ${REDISJSON_DIR}
		if [ ! -d "$REDISJSON_DIR" ]; then
			git clone https://github.com/RedisJSON/RedisJSON.git RedisJSON
			cd ${REDISJSON_DIR} && git checkout tags/v2.8.4 -b v2.8.4
			git submodule update --init --recursive
		fi
	fi
	rm ${LIBS_DIR}/librejson.so

	# Build RedisJSON
	cd ${REDISJSON_DIR}
	cargo build --release

	# Copy the librejson.so to the libs directory
	cp ${REDISJSON_DIR}/target/release/librejson.so ${LIBS_DIR}/librejson.so

	cd ${SCRIPT_DIR}
fi

# Clone RediSearch
if [ "$BUILD_SEARCH" -eq 1 ]; then
	if [ "$CLONE_SEARCH" -eq 1 ]; then
		sudo rm -rf ${REDISEARCH_DIR}
		if [ ! -d "$REDISEARCH_DIR" ]; then
			git clone https://github.com/RediSearch/RediSearch.git RediSearch
			cd ${REDISEARCH_DIR}
			git submodule update --init --recursive
		fi
		# sudo chmod -R 777 ${REDISEARCH_DIR}
	fi
	rm ${LIBS_DIR}/redisearch.so
	# Build RediSearch
	cd ${REDISEARCH_DIR}
	if [ "$RS_SETUP" -eq 1 ]; then
		sudo make setup
	fi
	sudo make build

	# Copy the redisearch.so to the libs directory
	cp ${REDISEARCH_DIR}/bin/linux-x64-release/search-community/redisearch.so ${LIBS_DIR}/redisearch.so

	cd ${SCRIPT_DIR}
fi


# Build AOValkey
sudo rm -rf ${AOVALKEY_DIR}/build
docker run -v ${AOVALKEY_DIR}:/AOValkey -v ${VALKEY_DIR}:/valkey --platform linux/amd64 ${AO_IMAGE}  sh -c \
		"cd /AOValkey && mkdir build && cd build && emcmake cmake -DCMAKE_C_FLAGS='${EMXX_CFLAGS}  -I/valkey/src' -S .. -B . && cmake --build ."
cp ${AOVALKEY_DIR}/build/libaovalkey.a ${LIBS_DIR}/libaovalkey.a


# Build Module
cp -a ${LIBS_DIR}/. ${PROCESS_DIR}/libs/
cp ${SCRIPT_DIR}/config.yml ${PROCESS_DIR}/config.yml
cd ${PROCESS_DIR}
docker run -e DEBUG=1 --platform linux/amd64 -v ./:/src ${AO_IMAGE} ao-build-module
cp ${PROCESS_DIR}/process.wasm ${TEST_DIR}/process.wasm
cp ${PROCESS_DIR}/process.js ${TEST_DIR}/process.js
