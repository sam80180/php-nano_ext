<?php
use NanoMsg\Nano as Nano;
use NanoMsg\Socket as NanoSocket;

define("NN_ENDPOINT_FRONTEND", "ipc:///tmp/nanomsg");

$cliente = new NanoSocket(Nano::AF_SP, Nano::NN_REQ);
$cliente->connect(NN_ENDPOINT_FRONTEND);
$cliente->send("aaaaaaaaa");
