<?php /**pb_auto_prepend.ph**/

/* This file is sourced before all others at pb_php_compile time */

$stderr = fopen('php://stderr', 'w');
$pb_debug = @debug@; /* true or false */
$pb_loaded_src_files = array();



/* On error, we stop the make process at compile time.
 * Installing the handler will catch all trigger_error()
 * calls and other errors. */
function pb_errorHandler($errno, $errstr, $errfile, $errline)
{
    global $stderr;

    fwrite($stderr, 'PHP compile ERROR('.$errno.')'.
        ':'.$errstr. ' file:'.$errfile.
        ':'.$errline."\n");
    exit(1); // will stop make
}
set_error_handler('pb_errorHandler',
        E_ALL|E_STRICT|E_NOTICE);

//fwrite($stderr, "  PHP sourced: ". __FILE__."\n");


?>
