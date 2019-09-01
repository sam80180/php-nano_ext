<?php
use NanoMsg\Nano as Nano;
use NanoMsg\Socket as NanoSocket;

define("NN_ENDPOINT_FRONTEND", "ipc:///tmp/nanomsg");
define("NN_ENDPOINT_BACKEND", "inproc:///tmp/nanomsg_backend");

// trabajadores
$tamaño_conjunto = 3;
$conjunto = new \Pool($tamaño_conjunto);
for ($i=0; $i<$tamaño_conjunto; $i++) {
    $conjunto->submit(new class($i) extends \Thread {
        private $id;
        
        public function __construct($id) { $this->id = $id; } // fin __construct()
        
        public function run() {
            $trabajador = new NanoSocket(Nano::AF_SP, Nano::NN_REP);
            $trabajador->connect(NN_ENDPOINT_BACKEND);
            while (TRUE) {
                $mensaje = $trabajador->recv();
                \print_r($mensaje);
            } // fin while
        } // fin run()
        
        public function start($opciones=NULL) { parent::start(PTHREADS_INHERIT_CONSTANTS); } // fin start()
    }); 
} // fin for

// servidor
$intPollTimeout = 5; // segundos
$frontend = new NanoSocket(Nano::AF_SP_RAW, Nano::NN_REP);
$eid_frontned = $frontend->bind(NN_ENDPOINT_FRONTEND);
$backend = new NanoSocket(Nano::AF_SP_RAW, Nano::NN_REQ);
$eid_backend = $backend->bind(NN_ENDPOINT_BACKEND);
$poll = new \NanoMsg\Poll();
$poll->add($frontend, Nano::NN_POLLIN);
$poll->add($backend, Nano::NN_POLLIN);
$poll->poll(function($nnsocket, $reventos) {
    if (($reventos & Nano::NN_POLLIN)) {
        echo "Recibido: ";
        \var_dump($nnsocket->recv());
    } else if (($reventos & Nano::NN_POLLOUT)) {
        
    } // fin if
}, $intPollTimeout*1000, function() {
    echo "¡Se acabó el tiempo de espera!\n";
    return TRUE;
}, function($errno) {
    echo "¡Error!\n";
    \var_dump(\func_get_args());
});

echo "\n¡Adiós!\n";
$frontend->shutdown($eid_frontned);
$backend->shutdown($eid_backend);
\NanoMsg\NanoExt::term();
$conjunto->shutdown();
exit(1);

/*
Referencias:
https://github.com/booksbyus/zguide/blob/master/examples/PHP/asyncsrv.php
*/
