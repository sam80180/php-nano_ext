//<?php
%{
// se pone en "ext/" (https://docs.zephir-lang.com/0.12/en/config#extra-sources)
#include "nanomsg/nn.h"
}%

namespace NanoMsg;

final class ExceptionExt extends \NanoMsg\Exception {
    /**
      * Constructor de la excepción.
      *
      * @param string $mensaje Mensaje de la excepción a lanzar.
      * @param int $codigo El código de la excepción.
      * @param \Throwable $anterior La excepción previa utilizada por la serie de excepciones.
      *
      * @return \NanoMsg\ExceptionExt
      */
    public function __construct(string $mensaje="", int $codigo=0, var $anterior=null) {
        int tmp_errno;
        %{
        tmp_errno = errno;
        }%
        if (!$codigo) { let $codigo = tmp_errno; } // fin if
        parent::__construct($mensaje, $codigo, $anterior);
    } // fin __construct()
    
    /**
      * Convertir el numero de error en texto.
      *
      * @return string|NULL
      */
    public static function strerror() {
        var str = null;
        %{
        //printf("errno= %ld\n", errno);
        ZVAL_STRING(&str, nn_strerror(errno));
        }%
        return str;
    } // fin strerror()
} // fin class
