<?php
	header('Content-Type: application/json; charset=utf-8');
	$commands = array( "start" , "stop" , "restart" );
	$input    = json_decode( file_get_contents( 'php://input' ) , true ); //Читаем в массив, не в объект
	$output   = "";
	$code     = "";
	$command  = $input[ 'command' ];
	if( in_array( $command , $commands ) ) exec( "sh /opt/etc/zapret_ctl $command 2>&1" , $output , $code );
	$running  = exec( "sh /opt/etc/zapret_ctl is_running 2>&1" );
	$response = [ "output" => $output , "code" => $code , "isRunning" => $running ];
	echo json_encode( $response );
?>