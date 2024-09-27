cmake_minimum_required(VERSION 3.20 FATAL_ERROR)

project(AOValkey C)

set(AOValkey_SRC_FILES
	aovalkey.c
)

add_library(aovalkey ${AOValkey_SRC_FILES})

# set_target_properties(aoredis PROPERTIES
# 	CXX_STANDARD 17
# 	CXX_STANDARD_REQUIRED ON
# 	CXX_EXTENSIONS OFF
# )