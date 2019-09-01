//<?php
%{
// se pone en "ext/" (https://docs.zephir-lang.com/0.12/en/config#extra-sources)
#include "php-nano/php_nano_private.h"
}%

namespace NanoMsg;

use NanoMsg\Exception as NanoException;

final class NanoExt {
    private function __construct() {} // fin __construct()
    
    /**
      * Construir un nuevo dispositivo.
      *
      * @param \NanoMsg\Socket|resource $s1 Un socket o recursode de flujo.
      * @param \NanoMsg\Socket|resource $s2 Un socket o recursode de flujo.
      *
      * @throws \NanoMsg\Exception en caso de error
      *
      * @return int negativo en caso de error
      */
    public static function device(var $s1, var $s2) {
        var $tmp_fd1 = SocketExt::fd($s1), $tmp_fd2 = SocketExt::fd($s2);
        if (is_null($tmp_fd1) || is_null($tmp_fd2)) { throw new NanoException("Error retrieving file descriptor(s)."); } // fin if
        int fd1 = (int)$tmp_fd1, fd2 = (int)$tmp_fd2, rc = 0;
        %{
        rc = nn_device(fd1, fd2);
        }%
        if (rc<0) {
            throw new ExceptionExt(sprintf("Error starting device for socket fds #%d & #%d: %s", fd1, fd2, ExceptionExt::strerror()));
        } // fin if
        return rc;
    } // fin device()
    
    public static function term() {
        %{
        nn_term();
        }%
    } // fin term()
} // fin class
