<?php
	header('Content-Type: text/html; charset=utf-8');
	$input    = json_decode( file_get_contents( 'php://input' ) , true ); //Читаем в массив, не в объект
	$file     = $input[ 'file' ];
	$content  = "";
	if( $file == "hosts" )   $content = file_get_contents( exec( "sh /opt/etc/zapret_ctl hosts_file 2>&1" ) );
	if( $file == "exclude" ) $content = file_get_contents( exec( "sh /opt/etc/zapret_ctl exclude_file 2>&1" ) );
	echo $content;
?>