#!/bin/bash

sudo apt update
sudo apt upgrade -y
sudo apt install gcc clang python3 python3-packaging python3-mako flex bison meson ninja
sudo apt build-dep mesa