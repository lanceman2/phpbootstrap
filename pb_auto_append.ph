<?php /**pb_auto_append.ph**/

/* This file is sourced after all others at pb_php_compile time */

function pb_finish()
{
    global $pb_loaded_src_files, $pb_debug;

    $all_src_files = array_unique(
        array_merge(
            $pb_loaded_src_files, get_included_files()
        ), SORT_STRING);
    unset($pb_loaded_src_files);
    foreach($all_src_files as &$file)
        $file = basename($file);
    unset($file);

    // Use full path for the auto files since they may not be
    // in the PHP bld_include/ directory.
    $key = array_search('pb_auto_prepend.ph', $all_src_files);
    $all_src_files[$key] = dirname(__FILE__).'/pb_auto_prepend.ph';
    $key = array_search('pb_auto_append.ph', $all_src_files);
    $all_src_files[$key] = __FILE__;

    if(!$pb_debug)
        foreach($all_src_files as $file)
            if(strncmp($file, 'dbg_', 4) === 0)
                trigger_error('file: '.$file. ' is included in '.
                    $script. ' and this is not a DEBUG build',
                    E_USER_ERROR);


    /* Dump the depend file */
    $filename = $_ENV['PHP_OUTFILENAME'].'.d';
    $out = @fopen($filename, 'w');
    if($out === FALSE)
        trigger_error('fopen("'.$filename.'", \'w\') failed', E_USER_ERROR);

    fwrite($out, "# this is a generated make depend file\n\n".
        $_ENV['PHP_OUTFILENAME'].':');

    foreach($all_src_files as $file)
        fwrite($out, "\\\n ".$file);
    fwrite($out, "\n");
    fclose($out);
}

pb_finish();

//fwrite($stderr, "  PHP sourced: ". __FILE__."\n");

?>
