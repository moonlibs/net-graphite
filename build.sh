#!/bin/sh
rpmbuild -ba --define="SRC_DIR $PWD" rpm/net-graphite.spec
