<?php

/* This file is sourced before all others at pb_php_compile time */

$stderr = fopen('php://stderr', 'w');
$pb_debug = @debug@; /* true or false */
$pb_loaded_src_files = array();
$pb_infilename = $_ENV['PHP_INFILENAME'];
$pb_infile_suffix = preg_replace('/^\./', '', $pb_infilename);
$pb_outfilename = $_ENV['PHP_OUTFILENAME'];
$pb_outfile_suffix = preg_replace('/^\./', '', $pb_outfilename);

if($pb_infile_suffix === '.pphp')
{
    ?><?php /*server*/
        $pb_debug = @debug@;
        $pb_file_suffix = preg_replace('/^\./g', '', __FILE__);
    ?><?php
}

require_once('pb_utils.ph');


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
    fwrite($stderr, var_export(debug_backtrace(), true)."\n");
    exit(1); // will stop make
}

set_error_handler('pb_errorHandler', E_ALL|E_STRICT|E_NOTICE);

function pb_fail($msg = 'error')
{
    trigger_error($msg, E_USER_ERROR);
    // We should not get here.
    exit(1);
}

// debug spew
function pb_spew($str)
{
    global $stderr;
    if($pb_debug)
    {
        $bt = debug_backtrace();
        $str = $bt[0]['file'].':'."\n".
            $bt[0]['line'].':'.
            $bt[0]['function'].
            '('.var_export(bt[0]['args'], true).'):'.
            "\n".$str;
        fwrite($stderr, $str);
    }
}

/* This does a readfile(file) using PHP include path and adds the file
 * to the files that the output file depends on for make dependency. */
function pb_insertFile($file, $once = true)
{
    global $pb_loaded_src_files;

    // We make this function be like require_once();
    if($once and (array_search($file, $pb_loaded_src_files) !== false))
        return;

    // Read a file and write it to the output buffer.
    if(readfile($file, true /*use include path*/) === false)
        pb_fail("readfile($file, true)");
    // Add the file to the depend file list.
    $pb_loaded_src_files[] = $file;
}

function pb_insertFilePhAsPhd($file, $once = true)
{
    global $pb_loaded_src_files;

    if($pb_infile_suffix !== '.pphp')
        pb_fail("pb_insertFilePhAsPhd() called in non .pphp file");

    // We make this function be like require_once();
    if($once and (array_search($file, $pb_loaded_src_files) !== false))
        return;

    // Read a file and write it to the output buffer.
    if(($str = file_get_contents($file, true /*use include path*/)) === false)
        pb_fail("file_get_contents(\"$file\", true)");

    $str = preg_replace('/\<\?php/', '<'.'?php /*server*/',$str);
    /* remove the space after at the end of ?> */
    echo preg_replace('/\?>\s*$/', '?'.'>',$str);

    // Add the file to the depend file list.
    $pb_loaded_src_files[] = $file;
}


//fwrite($stderr, "  PHP sourced: ". __FILE__."\n");


?>
