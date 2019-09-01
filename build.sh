#!/bin/bash

script=`readlink -f $0`
cwd=`dirname ${script}`
cd ${cwd}/ext
git clone https://github.com/mkoppanen/php-nano
git clone https://github.com/nanomsg/nanomsg
cd ${cwd}
rm -f compile-errors.log compile.log; zephir fullclean; zephir build
