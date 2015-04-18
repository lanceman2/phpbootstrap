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

    /* This should print a stack trace */
    fwrite($stderr, '  PHP compile ERROR('.$errno.')'.
        ':'.$errstr. "\n  file:".$errfile.
        ':'.$errline."\n  PHP BACKTRACE:\n");
    fwrite($stderr, var_export(debug_backtrace(), true));
    exit(1); // will stop make
}

set_error_handler('pb_errorHandler', E_ALL|E_STRICT|E_NOTICE);

function pb_fail($msg = 'error')
{
    trigger_error($msg, E_USER_ERROR);
    // We should not get here.
    exit(1);
}

if($pb_debug)
{
    // debug spew
    function pb_spew($str)
    {
        global $stderr;
        fwrite($stderr, $str);
    }
}
else
{
    // no debug spew
    function pb_spew($str)
    {
        global $stderr;
        fwrite($stderr, $str);
    }
}

/* This does a readfile(file) using PHP include path and adds the file
 * to the files that the output file depends on for make dependency. */
function pb_insertFile($file)
{
    global $pb_loaded_src_files;

    // Read a file and write it to the output buffer.
    if(readfile($file, true /*use include path*/) === false)
        pb_fail();
    // Add the file to the depend file list.
    $pb_loaded_src_files[] = $file;
}


//fwrite($stderr, "  PHP sourced: ". __FILE__."\n");


?>
