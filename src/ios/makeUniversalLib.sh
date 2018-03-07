#!/bin/bash -ev

cd libs

libtool -static i386/libchilkatIos-i386.a x86_64/libchilkatIos-x86_64.a armv7s/libchilkatIos-armv7s.a armv7/libchilkatIos-armv7.a arm64/libchilkatIos-arm64.a armv6/libchilkatIos-armv6.a -o libchilkatIos.a

cd ..
