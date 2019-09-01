//<?php
%{
// se pone en "ext/" (https://docs.zephir-lang.com/0.12/en/config#extra-sources)
#include "php-nano/php_nano_private.h"
}%

namespace NanoMsg;

use NanoMsg\Exception as NanoException;

final class SocketExt {
    private function __construct() {} // fin __construct()
    
    /**
      * Obtener el numero del socket o recursode de flujo.
      *
      * @param \NanoMsg\Socket|resource zObjecto Un socket o recursode de flujo.
      *
      * @throws \NanoMsg\Exception en caso de error
      *
      * @return int|NULL
      */
    public static function fd(var zObjecto) {
        string $strNanoSocketClass = "\\NanoMsg\\Socket";
        int fd = 0;
        if (is_resource(zObjecto)) { // https://github.com/zeromq/php-zmq/blob/f2617063a4c007ca6073c0d09e9f36fd9b87ddaf/zmq_pollset.c#L239
            %{
            php_stream *stream;
            php_stream_from_zval_no_verify(stream, zObjecto);
            if (!stream) {
                return NULL;
            } // fin if
            if (php_stream_can_cast(stream, (PHP_STREAM_AS_FD|PHP_STREAM_CAST_INTERNAL|PHP_STREAM_AS_SOCKETD) & ~REPORT_ERRORS)==FAILURE) {
                return NULL;
            } // fin if
            if (php_stream_cast(stream, (PHP_STREAM_AS_FD|PHP_STREAM_CAST_INTERNAL|PHP_STREAM_AS_SOCKETD) & ~REPORT_ERRORS, (void*)&fd, 0)==FAILURE) {
                return NULL;
            } // fin if
            }%
        } elseif (is_a(zObjecto, $strNanoSocketClass)) {
            %{
            php_nano_socket_object *intern = Z_NANO_P(zObjecto);
            fd = intern->s;
            }%
        } else {
            throw new NanoException("The first argument must be an instance of ‘".$strNanoSocketClass."’ or a resource.");
        } // fin if
        return fd;
    } // fin fd()
} // fin class
