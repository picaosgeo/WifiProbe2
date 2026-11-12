#! /bin/bash

source /opt/wifiprobe/bin/config

rm -rf $BIN_DIR/capture/*
rm -rf  $BIN_DIR/data/*
rm -rf $BIN_DIR/log/*
rm -rf $BIN_DIR/status/*
rm -rf $BIN_DIR/tmp/*

rm -rf $BIN_DIR/capture/.*
rm -rf $BIN_DIR/data/.*
rm -rf $BIN_DIR/log/.*
rm -rf $BIN_DIR/status/.*
rm -rf $BIN_DIR/tmp/.*

rm -rf $BIN_DIR/bin/.*
rm -rf $BIN_DIR/doc/.*