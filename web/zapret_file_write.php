<?php
	header('Content-Type: text/html; charset=utf-8');
	$input    = json_decode( file_get_contents( 'php://input' ) , true ); //Читаем в массив, не в объект
	$file     = $input[ 'file' ];
	$content  = $input[ 'content' ];
	if( $file == "hosts" )   file_put_contents( exec( "sh /opt/etc/zapret_ctl hosts_file 2>&1" ) , $content );
	if( $file == "exclude" ) file_put_contents( exec( "sh /opt/etc/zapret_ctl exclude_file 2>&1" ) , $content );
?>