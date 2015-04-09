
require 'fileutils'


$script_path = File.expand_path __FILE__
$script_path.freeze

######################################################################


def print_gen(path)

    if File.exist? path
        $stderr.print 're'
    else
        $stderr.print '  '
    end
    $stderr.print 'generating: ' + path + "\n"

end


if File.basename($script_path) == 'phpbootstrap'

    arg = ARGV.shift

    while arg
        case arg
        when /(--version|-V)/
            puts $pb_version
            exit
        else
            puts <<-END
  Usage: phpbootstrap [-h|--help]|[-V|--version]

  Generate a phpbootstrap configure and other scripts.

  
      OPTIONS

        -h|--help      print this help and exit

        -V|--version   print the phpbootstrap version (#{$pb_version})
                       and exit

            END
            exit
        end
    end

    ##########################################
    # This script copies itself to configure #
    ##########################################

    print_gen Dir.pwd + '/configure'
    FileUtils.copy $script_path, 'configure'
    exit 0
end


def dumpFile(in_path, out_file, required = true)

    if required or File.exist? in_path
        out_file.print '#>>>>> BEGIN FILE: ' + in_path + "\n"
        $pkg.sub_strings(in_path, out_file)
        out_file.print '#<<<<< END   FILE: ' + in_path + "\n"
    else
        out_file.print "\n# no file: " + in_path + " to add\n\n"
    end
end

def gen_pb_config(conf)

    path = Dir.pwd + '/pb_config'
    print_gen path
    f = File.open(path , 'w')
    f.print <<-END
#!/usr/bin/ruby -w
######################################
###### This is a generated file ######
######################################


require 'fileutils'

def usage

puts <<EEND

  Usage: #{$0} INFILE OUTFILE

  Subsitute @strings@ in INFILE and create OUTFILE.
  If INFILE is '-' use stdin.  If OUTFILE is '-' use
  stdout.

EEND
exit 1

end # usage()

if ARGV.length != 2
    usage
end


if ARGV[0] == '-'
  fin = $stdin
else
  fin = File.open(ARGV[0], 'r')
end

if ARGV[1] == '-'
  out = $stdout
  outpath = nil
else
  out = File.open(ARGV[1], 'w')
  outpath = ARGV[1]
end

begin

  if outpath
    suffix = outpath.gsub(/^.*\./,'')
    if suffix =~ /(ht|htm|html|php|phtml|ph|phd)/
      out.write "<!-- This is a generated file -->\\n"
    elsif suffix =~ /(js|jsp|css|cs)/
      out.write "/* This is a generated file */\\n"
    else # for bash script file
      FileUtils.chmod 0755, outpath
    end
  end

  pkg = #{conf[:sub].to_s}

  fin.each_line do |line|
    pkg.each do |k,v|
        if v.instance_of? String
            val = v
        elsif v.instance_of? Array
            if v[0].instance_of? String
                val = v[0]
            else
                val = ((v[0])?'1':'0')
            end
        else
            val = ((v)?'1':'0')
        end
        line.gsub!('@' + k.to_s + '@', val)
    end
    out.write line
  end

rescue Exception => e

  if outpath
    # It's all or nothing.
    out.close
    # remove the file that we just made.
    FileUtils.unlink outpath
    $stderr.print "writing " + outpath + " failed\\n"
    $stderr.print e.message  
    $stderr.print e.backtrace.inspect
    exit 1 # error return code
  end

  #success

end

    END

    f.close
    File.chmod(0755, path)
end



def gen_pb_file(name, data)

    path =  Dir.pwd + '/' + name
    print_gen path
    p = IO.popen('./pb_config - ' + path, 'w')
    p.write data
    p.close
    exit 1 unless $?.success?
end

# buildpath is the dir where to write GNUmakefile
# top_builddir is a relative path like . or .. or ../..
# rel_srcdir is path relative to the top source dir like foo/bar
def print_make_file(buildpath, conf, top_builddir, rel_srcdir)

    unless File.exist? buildpath
        $stderr.print 'making directory: ' + buildpath + "/\n"
        FileUtils.mkdir_p buildpath
    end

    if conf[:srcdir_equals_builddir]
        top_srcdir = top_builddir # relative path
        srcdir = rel_srcdir
        srcdir_equals_builddir = "srcdir_equals_builddir = true\n"
        if rel_srcdir != conf[:sub][:rel_include_dir]
            vpath = 'VPATH = .:' + top_srcdir + '/' + conf[:sub][:rel_include_dir]
        else
            vpath = '# VPATH not set'
        end
    else
        top_srcdir = conf[:top_src_fullpath] # full path when not in src dirs
        if top_builddir == '.'
            srcdir = top_srcdir
        else
            srcdir = top_srcdir + '/' + rel_srcdir
        end
        vpath = 'VPATH = .:' +
            srcdir + ':' + 
            top_builddir + '/' + conf[:sub][:rel_include_dir] + ':' +
            top_srcdir + '/' + conf[:sub][:rel_include_dir]
        srcdir_equals_builddir = "# srcdir_equals_builddir = false\n"
    end

    path = File.expand_path(buildpath) + '/GNUmakefile'
    print_gen path
    f = File.open(path , 'w')
    f.print <<-END
#This is a generated file

top_builddir := #{top_builddir}

top_srcdir := #{top_srcdir}

srcdir := #{srcdir}

VPATH := #{vpath}

#{srcdir_equals_builddir}

    END

    bp_make_path = srcdir + '/bp.make'
    dumpFile(bp_make_path, f, false)

    f.write $makefile_DATA
    f.close

    subdirs = []

    # Get subdirs from bp.make if we can
    if File.exist? bp_make_path
        gpath = buildpath + '/GNUmakefile.tmp_zZ'
        f = File.open(gpath, "w")
        f.write <<-END
# Temporary GNU makefile used to get value of SUBDIRS
include #{from_dir + '/qb.make'}
undefine build
ifeq ($(strip $(SUBDIRS)),)
SUBDIRS :=
endif
test__subdirs_FASDiefjmzzz:
        END
        f.write "\t@echo \"$(strip $(SUBDIRS))\"\n"
        f.close
        #$stderr.print "running: make test__subdirs_FASDiefjmzzz --silent\n"
        pwd = Dir.pwd
        Dir.chdir to_pwd
        subdirs = %x[make test__subdirs_FASDiefjmzzz --silent -f #{gpath}].split
        # bug check
        if subdirs =~ /Entering directory/
            $stderr.print "running make spewed badly again\n"
            exit 1
        end
        File.unlink gpath unless exists
        ##$stderr.print 'subdirs ="' + subdirs.to_s + "\"\n"
        Dir.chdir pwd
    end

    return unless subdirs.length > 0

    if top_builddir == '.'
        top_builddir = '..'
    else
        top_builddir += '/..'
    end

    subdirs.each do |dir|
        if buildpath != '.'
            bld = buildpath + '/' + dir
        else
            bld = dir
        end
        if rel_srcdir != '.'
            rel = rel_srcdir + '/' + dir
        else
            rel = dir
        end
        print_make_file(bld, conf, top_builddir, rel)
    end

end


def configure (conf)

    conf.each { |k,v| puts k.to_s + " = " + v.to_s }

    gen_pb_config conf

    data = ['','','','','']
    i = 0
    DATA.each_line do |line|
        # There must be a cleaner way to do this.
        if i < 2 and (line =~ /^#\!\s*\/bin\/bash/ or
                line =~ /^#\!\s*\/usr\/bin\//)
            data[i += 1] += <<-END
#{line}
############################
# This is a generated file
############################

            END
        elsif i >= 2 and i < 4 and
            (line =~ /^<\?php \/\*\*pb_auto_prepend\.ph\*\*\// or\
            line =~ /^<\?php \/\*\*pb_auto_append\.ph\*\*\//)
            data[i += 1] += "<?php /*** This is a generated file ***/\n"
        elsif i >= 0 and i <= 4
            data[i] += line
        else
            $stderr.print "Code error reading DATA in #{__FILE__}\n"
            exit 1
        end
    end

    $makefile_DATA = data[0]

    print_make_file('.', conf, '.', '.')

    gen_pb_file('pb_php_compile', data[1])
    File.chmod(0755, 'pb_php_compile')

    gen_pb_file('pb_cat_compile', data[2])
    File.chmod(0755, 'pb_cat_compile')

    gen_pb_file('pb_auto_prepend.ph', data[3].strip!)

    gen_pb_file('pb_auto_append.ph', data[4].strip!)

end


def help_printOpt(f, pre, text)

    max = 76 # length of printed text line
    spaces = "                         " # indent
    indent = spaces.length
    charPerLine = max - indent
    itext = 0 # test index printed so far
    textLen = text.length

    pre = "  " + pre

    f.print pre

    if pre.length < indent
        # pad to indent position
        f.print spaces[0, indent - pre.length]
        f.print text[0, charPerLine]
        itext += charPerLine
    end

    f.print "\n"

    while itext < textLen do
        f.printf spaces + text[itext, charPerLine] + "\n"
        itext += charPerLine
    end

    f.print "\n"
end


def usage

    $stdout.print <<END
  
  Usage: #{File.basename __FILE__} [OPTIONS]

    Creates GNUmakefile make files.


                 OPTIONS

  --help|-h          print this help and exit

  --version|-V       print the phpbootstrap version number (#{$pb_version}) and exit.

  --public PUBLIC    full path prefix to installed files that are web accessible

  --private PRIVATE  full path prefix to installed files that are not web accessible


END
    exit 1
end


def check_arg(name, arg)

    if arg == name
        arg = ARGV.shift
        usage unless arg
        $argOpts += ' ' + arg
        return arg
    end

    regexp = Regexp.new '^' + name + '='

    if arg =~ regexp
        return arg.sub(regexp, '')
    end

    return false
end

def which(path)

    return path if path[0] == '/'
    ENV['PATH'].split(':').each do |d|
        p =  d + '/' + path
        if File.exist? p
            return p
        end
    end
    return path
end


def parse_args

    arg = ARGV.shift
    conf = {}
    conf[:sub] = {}
    conf[:sub][:php_path] = which 'php'
    conf[:sub][:yui_path] = which 'yui'
    conf[:sub][:js_compile] = false
    conf[:sub][:css_compile] = false

    conf[:public] = Dir.pwd + '/testPublic'
    conf[:private] = Dir.pwd + '/testPrivate'

    while arg
        if  arg =~ /(--version|-V)/
            puts $pb_version
            exit
        elsif ret = check_arg('--public', arg)
            conf[:public] = File.expand_path ret
        elsif ret = check_arg('--private', arg)
            conf[:private] = File.expand_path ret
        elsif ret = check_arg('--private', arg)
            conf[:private] = File.expand_path ret
        else
            usage
        end
    end

    conf[:top_src_fullpath] = File.dirname $script_path
    conf[:top_build_path] = Dir.pwd

    if File.exist? conf[:public] and File.exist? conf[:private]
        unless File.directory? conf[:public] and File.directory? conf[:private]
            $stderr.print "\nfiles " +
                conf[:public] + " and " +
                conf[:private] + " exist and are " +
                "not both directories\n"
            exit 1
        end
        conf[:exists] = true
    elsif (File.exist? conf[:public] or File.exist? conf[:private])
        $stderr.print "\nfile:\n  " +
            conf[:public] + "\n or\n  " +
            conf[:private] + "\nexist, but not both\n"
        exit 1
    else
        conf[:exists] = false
    end

    if conf[:top_src_fullpath] == conf[:top_build_path]
        conf[:srcdir_equals_builddir] = true
    else
        conf[:srcdir_equals_builddir] = false
    end

    # building include path relative to top source dir
    conf[:sub][:rel_include_dir] = 'bld_include'
    conf[:sub][:top_src_fullpath] = conf[:top_src_fullpath]
    conf[:sub][:srcdir_equals_builddir] = conf[:srcdir_equals_builddir].to_s

    conf[:sub][:js_compile] = conf[:sub][:yui_path] +\
        ' --type js --line-break 50' unless conf[:sub][:js_compile]
    conf[:sub][:css_compile] = conf[:sub][:yui_path] +\
        ' --type css --line-break 50' unless conf[:sub][:css_compile]

    conf[:sub][:debug] = 'true' unless conf[:sub][:debug]

    conf
end

configure parse_args

