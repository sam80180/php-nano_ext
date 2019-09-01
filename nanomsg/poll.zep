//<?php
%{
// se pone en "ext/" (https://docs.zephir-lang.com/0.12/en/config#extra-sources)
#include "nanomsg/src/nn.h"

static int s_is_callable(zval *zcall, int warn) {
    zend_string *sCallable = NULL;
    int rc = (zcall && !zend_is_callable(zcall, 0, &sCallable) ? 0 : 1);
    if (!rc && warn) { php_error_docref(NULL, E_WARNING, "Function ‘%s’ is not a valid callback.", ZSTR_VAL(sCallable)); } // fin if
    zend_string_release(sCallable);
    return rc;
} // fin s_is_callable()
}%

namespace NanoMsg;

use NanoMsg\Exception as NanoException;

final class Poll {
    private $elementos;
    private $sucio;
    
    /**
      * Construir un conjunto de sondeo.
      *
      * @return \NanoMsg\Poll
      */
    public function __construct() {
        let this->$elementos = [];
        let this->$sucio = false;
    } // fin __construct()
    
    /**
      * Añadir un elemento al conjunto de sondeo.
      *
      * @param \NanoMsg\Socket|resource $zObjecto Un socket o recursode de flujo.
      * @param int $intEventos Defina la actidad para la que es sondeado el socket Véanse las constantes \NanoMsg\Nano::NN_POLLIN y \NanoMsg\Nano::NN_POLLOUT.
      *
      * @throws \NanoMsg\Exception en caso de error
      *
      * @return string El ID del elemento añadido, el cual puede ser empleado más adelante para eliminar el elemento.
      */
    public function add(var $zObjecto, int $intEventos) {
        var $tmp_fd = SocketExt::fd($zObjecto);
        if (is_null($tmp_fd)) { throw new NanoException("Error retrieving file descriptor."); } // fin if
        int $fd = (int)$tmp_fd;
        string $llave = (string)uniqid("");
        let this->$elementos[$llave] = ["fd": $fd, "events": $intEventos, "o": $zObjecto];
        let this->$sucio = true;
        return $llave;
    } // fin add()
    
    /**
      * Eliminar un elemento del conjunto de sondeo.
      *
      * @param string|\NanoMsg\Socket|resource $elemento1 El ID del socket, recursode de flujo, o socket.
      *
      * @return bool Devuelve TRUE si el objeto se eliminó y FALSE si el objeto con el ID dado no existe en el conjunto de sondeo.
      */
    public function remove(var $elemento1) {
        if (is_string($elemento1)) {
            if (!isset(this->$elementos[$elemento1])) { return false; } // fin if
            unset(this->$elementos[$elemento1]);
            let this->$sucio = true;
            return true;
        } else {
            var $elemento0, $llave;
            array $llaves = [];
            for ($llave, $elemento0 in this->$elementos) {
                if ($elemento0!==$elemento1) { continue; } // fin if
                let $llaves[] = $llave;
            } // fin for
            int $numLlaves = (int)count($llaves);
            if ($numLlaves<=0) { return false; } // fin if
            for (_, $llave in $llaves) {
                unset(this->$elementos[$llave]);
            } // fin for
            let this->$sucio = true;
            return true;
        } // fin if
    } // fin remove()
    
    /**
      * Limpiar el conjunto de sondeo.
      *
      * @return void
      */
    public function clear() {
        let this->$elementos = [];
        let this->$sucio = true;
    } // fin clear()
    
    /**
      * Contar los elementos del conjunto de sondeo.
      *
      * @return int
      */
    public function count() {
        return (int)count(this->$elementos);
    } // fin count()
    
    /**
      * Sondear los elementos.
      *
      * @param callable flujo_callback Un función de callback o string.
      * @param int tiempo_espera Tiempo de espera de la operación.
      * @param callable espera_callback Un función de callback o string.
      * @param callable error_callback Un función de callback o string.
      *
      * @return int|NULL
      */
    public function poll(var flujo_callback, int tiempo_espera=-1, var espera_callback=null, var error_callback=null) {
        int rc = -1, j, tmp_fd, tmp_events, num_elementos;
        %{
        zend_long timeout = -1;
        zval *zcall_flujo, *zcall_espera, *zcall_error;
        int argc = ZEND_NUM_ARGS() TSRMLS_CC;
        if (zend_parse_parameters(argc, "z!|lz!z!", &zcall_flujo, &timeout, &zcall_espera, &zcall_error)==FAILURE) { return NULL; } // fin if
        if (!s_is_callable(zcall_flujo, 1)) { return NULL; } // fin if
        zend_bool bCallableError = 0, bCallableEspera = 0;
        if (argc>=3) {
            if (!s_is_callable(zcall_espera, 1)) { return NULL; } // fin if
            bCallableEspera = 1;
        } // fin if
        if (argc>=4) {
            if (!s_is_callable(zcall_error, 1)) { return NULL; } // fin if
            bCallableError = 1;
        } // fin if
        TSRMLS_FETCH();
        }%
        var tmp_zo;
        while (true) {
            let num_elementos = (int)this->count();
            if (!num_elementos) { throw new NanoException(sprintf("No sockets assigned to the %s.", get_called_class())); } // fin if
            %{
            struct nn_pollfd pollfds[num_elementos];
            zval zo[num_elementos];
            }%
            var $elemento;
            for (_, $elemento in this->$elementos) {
                let tmp_fd = (int)$elemento["fd"];
                let tmp_events = (int)$elemento["events"];
                let tmp_zo = $elemento["o"];
                %{
                pollfds[j].fd = tmp_fd;
                pollfds[j].events = tmp_events;
                zo[j] = tmp_zo;
                }%
                let j = j+1;
            } // fin for
            let this->$sucio = false;
            while (true) {
                if (this->$sucio) { break; } // fin if
                %{
                rc = nn_poll(pollfds, num_elementos, (tiempo_espera<0 ? -1 : tiempo_espera));
                zval retval;
                }%
                if (rc===-1) { // ha fallado
                    %{
                    if (bCallableError) {
                        zval num;
                        ZVAL_LONG(&num, errno TSRMLS_CC);
                        zval params[] = {num};
                        if (call_user_function_ex(EG(function_table), NULL, zcall_error, &retval, 1, params, 0, NULL TSRMLS_CC)!=SUCCESS) {
                            php_error_docref(NULL, E_WARNING, "Call '%s' failed\n", (Z_ISUNDEF(zcall_error) || Z_TYPE_P(zcall_error)!=IS_STRING ? "{closure}" : Z_STRVAL_P(zcall_error)));
                            return rc;
                        } // fin if
                        if (!Z_ISUNDEF(retval) && Z_TYPE(retval)==IS_TRUE) {
                            continue;
                        } // fin if
                    } // fin if
                    }%
                    throw new ExceptionExt(sprintf("Error polling: %s", ExceptionExt::strerror()));
                } elseif (rc===0) { // se acabó el tiempo de espera
                    %{
                    if (!bCallableEspera) { return rc; } // fin if
                    if (call_user_function_ex(EG(function_table), NULL, zcall_espera, &retval, 0, NULL, 0, NULL TSRMLS_CC)!=SUCCESS) {
                        php_error_docref(NULL, E_WARNING, "Call '%s' failed\n", (Z_ISUNDEF(zcall_espera) || Z_TYPE_P(zcall_espera)!=IS_STRING ? "{closure}" : Z_STRVAL_P(zcall_espera)));
                        return rc;
                    } // fin if
                    if (Z_ISUNDEF(retval) || Z_TYPE(retval)!=IS_TRUE) { // no hay valores devueltos, o el valor devuelto no es TRUE
                        return rc;//RETURN_ZVAL(&retval, 0, 1);
                    } // fin if
                    }%
                    continue;
                } else {
                    %{
                    for (int i=0; i<num_elementos; i++) {
                        if ((pollfds[i].revents & NN_POLLIN) || (pollfds[i].revents & NN_POLLOUT)) {
                            zval revents;
                            ZVAL_LONG(&revents, pollfds[i].revents);
                            zval params[] = {zo[i], revents};
                            if (call_user_function_ex(EG(function_table), NULL, zcall_flujo, &retval, 2, params, 0, NULL TSRMLS_CC)!=SUCCESS) {
                                php_error_docref(NULL, E_WARNING, "Call '%s' failed\n", (Z_ISUNDEF(zcall_flujo) || Z_TYPE_P(zcall_flujo)!=IS_STRING ? "{closure}" : Z_STRVAL_P(zcall_flujo)));
                            } // fin if
                        } // fin if
                    } // fin for
                    }%
                } // fin if
            } // fin while
        } // fin while
        return rc;
    } // fin poll()
} // fin class
