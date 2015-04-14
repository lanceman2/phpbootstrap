# END_CONFIGURATION

require 'fileutils'


$script_path = File.expand_path __FILE__
$script_path.freeze

# Every file that we generate gets this, generated_file_magic_string, in
# it at or close to the top in a comment.
$generated_file_magic_string = 'phpbootstrap: This is a generated file'
$generated_file_magic_string.freeze

########################################################################


def print_gen(path)

    if File.exist? path
        $stderr.print 're'
    else
        $stderr.print '  '
    end
    $stderr.print 'generating: ' + path + "\n"

end


if File.basename($script_path) == 'phpbootstrap'

    def usage
        puts <<-END
  Usage: phpbootstrap [-h|--help]|[-V|--version]

  Generate a phpbootstrap configure and other scripts.

  
      OPTIONS

        -h|--help            print this help and exit

        -V|--version         print the phpbootstrap version (#{$pb_version}) and exit

        --name PACKAGE_NAME  set the package name to PACKAGE_NAME, the default is the
                             current directory file name

        END
        exit
    end

    arg = ARGV.shift
    package_name = File.basename Dir.pwd

    while arg
        case arg
        when /(--version|-V)/
            puts $pb_version
            exit
        when /--name=/
            package_name = arg.sub(/--name=/, '')
        when /^--name$/
            usage if not (arg = ARGV.shift)
             package_name = arg
        else
            usage
        end
    end

    package_name.gsub!(/[^a-zA-Z0-9_]/, '')

    ##############################################################
    # This script copies itself to configure with some additions #
    ##############################################################

    print_gen Dir.pwd + '/configure'
    rd = File.open($script_path, 'r')
    wr = File.open('configure', 'w')
    wr.write rd.gets # get the #! line
    wr.write <<-END
# #{$generated_file_magic_string}
#####################################################
# This file was generated when phpbootstrap ran
#####################################################
# pb_package_name was defined when phpbootstrap ran
$pb_package_name = '#{package_name}'

# END_CONFIGURATION
    END
    while line = rd.gets
        break if line =~ /^# END_CONFIGURATION/
    end
    while line = rd.gets
        wr.write line
    end
    wr.close
    rd.close
    FileUtils.chmod 0755, 'configure'
    exit 0
end


def dumpFile(in_path, out_file, conf, required = true)

    if required or File.exist? in_path
        out_file.print '#>>>>> BEGIN FILE: ' + in_path + "\n"
        File.open(in_path, 'r').each_line do |line|
            out_file.print sub_line(conf[:sub], line)
        end
        out_file.print '#<<<<< END   FILE: ' + in_path + "\n"
    else
        out_file.print "\n# no file: " + in_path + " to add\n\n"
    end
end


def gen_pb_config(conf)

    path = Dir.pwd + '/' + conf[:sub][:pb_build_prefix] + 'pb_config'
    print_gen path
    f = File.open(path , 'w')
    f.print <<-END
#!/usr/bin/ruby -w
#############################################
###### #{conf[:sub][:generated_file_string]}
#############################################

require 'fileutils'


def usage

puts <<EEND

  Usage: pb_config INFILE OUTFILE

  Subsitute @strings@ in INFILE and create OUTFILE.
  If INFILE is '-' use stdin.

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

out = File.open(ARGV[1], 'w')
outpath = ARGV[1]


begin

  # pkg is how this "#{File.basename(Dir.pwd)}" package is configured
  pkg = {
  END
  
    got = false
    conf[:sub].each do |k,v|
        f.print ",\n" if got
        got = true
        val = v.to_s
        val = "'" + v + "'" if v.instance_of? String
        f.print "    :#{k.to_s} => #{val}"
    end
  
    f.print <<-END

  }

  def sub_line(pkg, line, out)
    # this needs to match code at xxZZconf in pb_main_program.rb
    pkg.each do |k,v|
        if v.instance_of? String
            val = v
        elsif v.instance_of? Array
            if v[0].instance_of? String
                val = v[0]
            else
                val = ((v[0])?'true':'false')
            end
        else
            val = ((v)?'true':'false')
        end
        line.gsub!('@' + k.to_s + '@', val)
    end
    out.write line
  end


  l = fin.gets

  if outpath
    suffix = outpath.gsub(/^.*\\./, '')
    if suffix =~ /^(ht|htm|html)$/ and l =~ /^<!DOCTYPE /
      sub_line(pkg, l, out)
      out.write "<!-- \#{pkg[:generated_file_string]} -->\\n"
    elsif suffix =~ /^(ht|htm|html)$/
      out.write "<!-- \#{pkg[:generated_file_string]} -->\\n"
      sub_line(pkg, l, out) if l
    elsif suffix =~ /^(pphp|php|phtml|ph|phd|pjs|pcss|pjsp|pcs)$/
      out.write "<?php\\n/* \#{pkg[:generated_file_string]}*/\\n ?>"
      sub_line(pkg, l, out) if l
    elsif suffix =~ /^(js|jsp|css|cs)$/
      out.write "/* \#{pkg[:generated_file_string]} */\\n"
      sub_line(pkg, l, out) if l
    elsif suffix == 'txt'
      out.write "\# \#{pkg[:generated_file_string]}\\n"
      sub_line(pkg, l, out)
    elsif suffix =~ /^(cjs|cjsp|ccss|ccs|cht|chtm|chtml)$/
      out.write "# \#{pkg[:generated_file_string]}\\n"
      sub_line(pkg, l, out) if l
    else # for bash script file
      FileUtils.chmod 0755, outpath
      if l
        sub_line(pkg, l, out)
      else
        out.write "#!/bin/bash\n"
      end
      out.write "\n# \#{pkg[:generated_file_string]}\\n\\n"
    end
  end

  while l = fin.gets
    sub_line(pkg, l, out)
  end

rescue Exception => e

  if outpath
    # It's all or nothing.
    out.close
    # remove the file that we just made.
    FileUtils.rm_f outpath
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



def gen_pb_file(name, data, conf)

    path =  Dir.pwd + '/' + conf[:sub][:pb_build_prefix] + name
    print_gen path
    p = File.open(path, 'w')
    p.write data
    p.close
end


# buildpath is the dir where to write GNUmakefile
# top_builddir is a relative path like . or .. or ../..
# rel_srcdir is path relative to the top source dir like foo/bar
def print_make_file(buildpath, conf, top_builddir, rel_srcdir, data)

    unless File.exist? buildpath
        $stderr.print 'making directory: ' + buildpath + "/\n"
        FileUtils.mkdir_p buildpath
    end

    if conf[:srcdir_equals_builddir]
        top_srcdir = top_builddir # relative path
        srcdir = '.'
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
# #{conf[:sub][:generated_file_string]}

top_builddir := #{top_builddir}

top_srcdir := #{top_srcdir}

srcdir := #{srcdir}

#{vpath}

#{srcdir_equals_builddir}

    END

    bp_make_path = top_srcdir + '/' + rel_srcdir + '/pb.make'
    dumpFile(bp_make_path, f, conf, false)

    f.write data
    f.close

    subdirs = []

    # Get subdirs from bp.make if we can
    if File.exist? bp_make_path
        gpath = buildpath + '/GNUmakefile.tmp_zZ'
        f = File.open(gpath, "w")
        f.write <<-END
# Temporary GNU makefile used to get value of SUBDIRS
include #{bp_make_path}
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
        Dir.chdir buildpath
        subdirs = %x[make -C #{buildpath} test__subdirs_FASDiefjmzzz --silent -f GNUmakefile.tmp_zZ].split
        # bug check
        if subdirs =~ /Entering directory/
            $stderr.print "running make spewed badly again\n"
            exit 1
        elsif not $?.success?
            $stderr.print "  configure failed: running make failed\n"
            exit 1
        end

        File.unlink gpath
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
        next if dir == '.'
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
        print_make_file(bld, conf, top_builddir, rel, data)
    end

end

def sub_line(pkg, line)

    # this needs to match code at xxZZconf in this file
    pkg.each do |k,v|
        if v.instance_of? String
            val = v
        elsif v.instance_of? Array
            if v[0].instance_of? String
                val = v[0]
            else
                val = ((v[0])?'true':'false')
            end
        else # boolean
            val = ((v)?'true':'false')
        end
        line.gsub!('@' + k.to_s + '@', val)
    end
    line
end

def configure (conf)

    if conf[:sub][:pb_build_prefix] and
        conf[:sub][:pb_build_prefix].length > 0
        pb_bld_dir = Dir.pwd + '/' + conf[:sub][:pb_build_prefix]
        if not File.exist? pb_bld_dir
            $stderr.print "    creating: #{pb_bld_dir}\n"
            FileUtils.mkdir_p pb_bld_dir
        end
    end

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
# #{conf[:sub][:generated_file_string]}
############################

            END
        elsif i >= 2 and i < 4 and
            (line =~ /^<\?php \/\*\*pb_auto_prepend\.ph\*\*\// or\
            line =~ /^<\?php \/\*\*pb_auto_append\.ph\*\*\//)
            data[i += 1] += "<?php /*** #{conf[:sub][:generated_file_string]} ***/\n"
        elsif i >= 0 and i <= 4
            data[i] += sub_line(conf[:sub], line)
        else
            $stderr.print "Code error reading DATA in #{__FILE__}\n"
            exit 1
        end
    end


    print_make_file('.', conf, '.', '.', data[0])

    gen_pb_file('pb_php_compile', data[1], conf)
    File.chmod(0755, conf[:sub][:pb_build_prefix] + 'pb_php_compile')

    gen_pb_file('pb_cat_compile', data[2], conf)
    File.chmod(0755, conf[:sub][:pb_build_prefix] + 'pb_cat_compile')

    gen_pb_file('pb_auto_prepend.ph', data[3].strip!, conf)

    gen_pb_file('pb_auto_append.ph', data[4].strip!, conf)

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

  --help|-h           print this help and exit

  --version|-V        print the phpbootstrap version number (#{$pb_version}) and exit.

  --public PUBLIC     full path prefix to installed files that are web accessible

  --private PRIVATE   full path prefix to installed files that are not web accessible
  --debug true|false  make it a debug build, i.e. not production, or not


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
    # default debug value # TODO change this
    conf[:sub][:debug] = true

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
        elsif ret = check_arg('--debug', arg)
            ret.downcase!
            if conf[:sub][:debug] # default is true
                conf[:sub][:debug] = 'false' if ret =~ /(^n|^f|^0|^of)/
            else
                conf[:sub][:debug] = 'true' if ret =~ /(^y|^t|^[1-9]|^on|^al)/
            end
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
    conf[:sub][:top_src_fullpath] = conf[:top_src_fullpath]
    conf[:sub][:srcdir_equals_builddir] = conf[:srcdir_equals_builddir]

    conf[:sub][:js_compile] = conf[:sub][:yui_path] +\
        ' --type js --line-break 50' unless conf[:sub][:js_compile]
    conf[:sub][:css_compile] = conf[:sub][:yui_path] +\
        ' --type css --line-break 50' unless conf[:sub][:css_compile]

    conf[:sub][:debug] = 'true' unless conf[:sub][:debug]
    conf[:sub][:generated_file_string] = $generated_file_magic_string
    conf[:sub][:package_name] = $pb_package_name
    # pb_build_prefix must be relative a path
    conf[:sub][:pb_build_prefix] = 'pb_build/'

    conf[:sub][:pb_build_prefix] += '/' if conf[:sub][:pb_build_prefix].length > 0 and
        conf[:sub][:pb_build_prefix][-1] != '/'
    
    # rel_include_dir must be a relative path
    #conf[:sub][:pb_build_prefix] = ''
    conf[:sub][:rel_include_dir] = 'bld_include'

    # remove starting or ending '/'s 
    conf[:sub][:rel_include_dir].gsub!(/(^\/*|\/*$)/, '')


    def find_include_path_relto_pb_build(build_prefix, rel_include_dir)

        # something this butt ugly needs to be a function

        # ret is something like '' or '/..' or '/../..' or '/../../..' etc.
        ret = ''
        # strip leading '/' or '//' or './/' or './/' and so on
        prefix = build_prefix.gsub(/^(\.\/*|\/*)/, '')

        while prefix.length > 0
            if prefix =~ /^\//
                ret += '/..'
                prefix.gsub!(/^\/*/, '')
            else
                # strip one char
                prefix = prefix[1...10000]
            end
        end

        # now add rel_include_dir and return it
        if rel_include_dir.length > 0
            ret + '/' + rel_include_dir
        else
            ret
        end
    end

    conf[:sub][:include_path_relto_pb_build] =
        find_include_path_relto_pb_build(conf[:sub][:pb_build_prefix],
                                        conf[:sub][:rel_include_dir])

    conf
end

configure parse_args

