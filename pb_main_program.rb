
require 'fileutils'
require 'etc'

$script_path = File.expand_path __FILE__
$script_path.freeze

# Every file that we generate gets this, generated_file_magic_string, in
# it at or close to the top in a comment.
$generated_file_magic_string = 'This is a phpbootstrap generated file'
$generated_file_magic_string.freeze


# GOOD TO KNOW: This script never changes the working directory


###########################################################################
# Less code without OOP.  Today we say fuck OOP, for tomorrow we may drown
# in spaghetti code.
#

# We need this sub_line() in more than one ruby file, so we do a little
# ruby meta-programming here, so that this function is the same for this
# and another ruby script.

$def_sub_line = <<END
def sub_line(pkg, line)
    pkg.each do |k,v|
        if v.instance_of? String
            val = v
        elsif v.instance_of? Array
            val = v.to_s
        else # boolean
            val = ((v)?"true":"false")
        end
        line = line.gsub("@" + k.to_s + "@", val)
    end
    line
end
END


# define this sub_line() function here
eval($def_sub_line)
# and we'll use it in another place too



def print_gen(path)

    if File.exist? path
        $stderr.print 're'
    else
        $stderr.print '  '
    end
    # We got tired of seeing these long fucking path strings
    p = path.sub(Regexp.new('^' + Regexp.escape(Dir.pwd) + '\/'), '')
    $stderr.print 'generating: ' + p + "\n"

end

# TODO: this interface sucks
def check_arg(name, arg, conf = nil)

    if arg == name
        arg = ARGV.shift
        unless arg
            if conf
                usage(conf)
            else
                bs_usage
            end
        end
        return arg
    end

    regexp = Regexp.new '^' + name + '='

    if arg =~ regexp
        return arg.sub(regexp, '')
    end

    false
end


if File.basename($script_path) == 'phpbootstrap'

    def bs_usage

        puts <<-END
  Usage: phpbootstrap [-h|--help]|[-V|--version]

  Generate a phpbootstrap configure and other scripts.  Reads ruby file pb.config
  and calls config() in that file, if the file is found in the current directory.

  
      OPTIONS

   -h|--help            print this help and exit

   -V|--version         print the phpbootstrap version (#{$pb_version}) and exit

  

        END
        exit
    end


    arg = ARGV.shift
    package_name = File.basename Dir.pwd

    while arg
        if arg =~ /(--version|-V)/
            puts $pb_version
            exit
        else
            bs_usage
        end
        arg = ARGV.shift
    end

    opts = {}
    conf = {}

    if File.exist? 'pb.config'
        $stderr.print "Found file: pb.config\n"
        load 'pb.config'
        config(conf, opts)
        # puts conf.to_s
        if conf[:package_name] and conf[:package_name].is_a? String
            package_name = conf.delete(:package_name)
        end
    end
    
    package_name.gsub!(/[^a-zA-Z0-9_]/, '')

    if conf.length
        conf = '$pb_conf = ' + conf.to_s
    else
        conf = ''
    end
    
    if opts.length
        opts = '$pb_options = ' + opts.to_s
    else
        opts = ''
    end

    ##############################################################
    # This script copies itself to configure with some additions #
    ##############################################################

    print_gen Dir.pwd + '/configure'
    rd = File.open($script_path, 'r')
    wr = File.open('configure', 'w')
    wr.write rd.gets # get the #! line first
    wr.write <<-END
# #{$generated_file_magic_string}
#####################################################
# This file was generated when phpbootstrap ran
#####################################################
# pb_package_name was defined when phpbootstrap ran
$pb_package_name = '#{package_name}'
#{conf}
#{opts}
    END
    while line = rd.gets
        # skip up to pb_file_seperator_regrex
        if line =~ /^\$pb_file_seperator_regrex/
            wr.write line
            break
        end
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

    # Ain't meta-programming fun!  Ruby's reflexivity.

    f.print <<-END
#!/usr/bin/ruby -w
#############################################
###### #{conf[:sub][:generated_file_string]}
#############################################

require 'fileutils'


def usage

puts <<EEND

  Usage: pb_config INFILE OUTFILE [--no-comment]

  Subsitute @strings@ in INFILE and create OUTFILE.
  If INFILE is '-' use stdin.

EEND
exit 1

end # usage()

if ARGV.length < 2 or ARGV.length > 3
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
  # These values get substituted in place of @key@ in input files when
  # this script runs.
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

# define the sub_line() function here
#{$def_sub_line}


def write_line(pkg, l, out)
    out.write sub_line(pkg, l)
end


  if outpath and not ARGV[2]
    l = fin.gets
    suffix = outpath.gsub(/^.*\\./, '')
    if suffix =~ /^(ht|htm|html)$/ and l =~ /^<!DOCTYPE /
      write_line(pkg, l, out)
      out.write "<!-- \#{pkg[:generated_file_string]} -->\\n"
    elsif suffix =~ /^(ht|htm|html)$/
      out.write "<!-- \#{pkg[:generated_file_string]} -->\\n"
      write_line(pkg, l, out) if l
    elsif suffix =~ /^(pphp|php|phtml|ph|phd|pjs|pcss|pjsp|pcs)$/
      out.write "<?php\\n/* \#{pkg[:generated_file_string]}*/\\n ?>"
      write_line(pkg, l, out) if l
    elsif suffix =~ /^(js|jsp|css|cs)$/
      out.write "/* \#{pkg[:generated_file_string]} */\\n"
      write_line(pkg, l, out) if l
    elsif suffix == 'txt'
      out.write "\# \#{pkg[:generated_file_string]}\\n"
      write_line(pkg, l, out)
    elsif suffix =~ /^(cjs|cjsp|ccss|ccs|cht|chtm|chtml)$/
      out.write "# \#{pkg[:generated_file_string]}\\n"
      write_line(pkg, l, out) if l
    else # for bash of ruby script file 
      FileUtils.chmod 0755, outpath
      if l
        write_line(pkg, l, out)
      else
        out.write "#!/bin/bash\\n"
      end
      out.write "\\n# \#{pkg[:generated_file_string]}\\n\\n"
    end
  end

  while l = fin.gets
    write_line(pkg, l, out)
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



def gen_pb_file(name, data, conf, is_exe = false,
                pre = conf[:sub][:pb_build_prefix])

    path =  Dir.pwd + '/' + pre + name
    print_gen path
    p = File.open(path, 'w')
    p.write data
    p.close
    File.chmod(0755, path) if is_exe
end


def get_subdirs_from_make(buildpath, bp_make_path)

    # Get subdirs from bp.make if we can

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
    f.write "\t@echo \"@@@@$(strip $(SUBDIRS))####\"\n"
    f.close
    run = "make -C #{buildpath} --silent -f GNUmakefile.tmp_zZ " +
        "test__subdirs_FASDiefjmzzz"
    # We found that there can be extra spew in the output of GNU make
    # even with --silent, if this is run from another make process,
    # so we look for a string between @@@@ and ####.
    out = %x[#{run}]
    subdirs = ''
    out.each_line do |s|
        if s =~ /@@@@.*####/
            subdirs = s.gsub(/(^.*@@@@|####.*$)/,'')
            break
        end
    end
        
    # error/bug check
    if subdirs =~ /Entering directory/
        # WTF: Is echo in the make file not run in an atomic way?
        $stderr.print "running: #{run}\nspewed badly the following\n"
        $stderr.print out + "\n"
        exit 1
    elsif not $?.success?
        # make failed
        $stderr.print <<-END
  configure failed: running:
    #{run}
  FAILED
        END
        exit 1
    end
    File.unlink gpath
    #$stderr.print 'subdirs ="' + subdirs.to_s + "\"\n"

    # make an array of sub-directories from space separated list
    subdirs.split
end


# buildpath is the dir where to write GNUmakefile, like . or 'foo' or
# 'foo/bar' which is a relative path from the top of the source directory
# tree which is the same in the build directory tree.
# top_builddir is a relative path like . or .. or ../..
def print_make_file(buildpath, conf, top_builddir, data)

    unless File.exist? buildpath
        $stderr.print 'making directory: ' + buildpath + "/\n"
        FileUtils.mkdir_p buildpath
    end

    vpath = '.'
    if conf[:srcdir_equals_builddir]
        top_srcdir = top_builddir # relative path
        srcdir = '.'
        srcdir_equals_builddir = "srcdir_equals_builddir = true\n"
        if buildpath != conf[:sub][:rel_include_dir]
            vpath += ':' + top_srcdir + '/' + conf[:sub][:rel_include_dir]
        end
    else
        top_srcdir = conf[:top_src_fullpath] # full path when not in src dir
        if top_builddir == '.'
            srcdir = top_srcdir
        else
            srcdir = top_srcdir + '/' + buildpath
        end
        vpath += ':' +
            srcdir + ':' + 
            top_builddir + '/' + conf[:sub][:rel_include_dir] + ':' +
            top_srcdir + '/' + conf[:sub][:rel_include_dir]
        srcdir_equals_builddir = "# srcdir_equals_builddir = false\n"
    end
    vpath += ':' + top_builddir + '/' + conf[:sub][:pb_build_prefix].sub(/\/$/, '')

    # default is not accessible by web
    url_path_dir = '# url_path_dir is not set; this directory is not served'

    if buildpath =~ conf[:rel_include_dir_regrex]
        installdir = false # nothing in this dir is installed
    elsif buildpath =~ /^private($|\/)/
        # installed in private
        installdir = buildpath.sub(/^private/,conf[:private])
    elsif conf[:public_in_topsrc] or buildpath =~ /^public($|\/)/
        # installed in public and served to web
        if buildpath != '.'
            installdir = conf[:public] + '/' + buildpath
            url_path_dir = 'url_path_dir := /' + buildpath
        else
            conf[:top_public_dir] = buildpath
            installdir = conf[:public]
            url_path_dir = 'url_path_dir := /'
        end
        unless conf[:top_public_dir]
            conf[:top_public_dir] = buildpath
        end
    else
        installdir = false # nothing in this dir is installed
    end

    add_distclean = ''

    if top_builddir == '.'
        add_distclean += "\\\n $(pre_install)\\\n $(post_install)"
        [
            'pb_auto_prepend.ph', 'pb_auto_append.ph',
            'pb_utils.ph',
            'pb_php_compile', 'pb_cat_compile',
            'pb_config',
            'pb_index.cs'
        ].each do |pb|
            add_distclean += "\\\n " + conf[:sub][:pb_build_prefix] + pb
        end
    end

    # We generate an array list of directories that are
    # seem by the web browsers from the path in the URL.
    dirs = []

    if installdir
        unless buildpath =~ /^private($|\/)/
            # This dir may be seem on the web
            dirs.push buildpath
        end
        installdir = "installdir := #{installdir}"
    else
        installdir = "# installdir is not defined for this directory"
    end

    if installdir and buildpath == '.'
        add_distclean += "\\\n pb_index.pphp"
    end

    if add_distclean.length > 0
        add_distclean = 'add_distclean =' + add_distclean
    else
        add_distclean = '# add_distclean is not defined'
    end


    path = File.expand_path(buildpath) + '/GNUmakefile'
    print_gen path
    f = File.open(path , 'w')
    f.print <<-END
# #{conf[:sub][:generated_file_string]}
#
# This is a GNU make file which uses GNU make extensions

top_builddir := #{top_builddir}

top_srcdir := #{top_srcdir}

srcdir := #{srcdir}

#{installdir}

VPATH = #{vpath}

#{srcdir_equals_builddir}

#{add_distclean}

#{url_path_dir}

    END

    if buildpath != '.'
        bp_make_path = conf[:top_src_fullpath] + '/' + buildpath + '/pb.make'
    else
        bp_make_path = conf[:top_src_fullpath] + '/pb.make'
    end

    dumpFile(bp_make_path, f, conf, false)

    if File.exist? conf[:top_src_fullpath] + '/pre_install'
        f.print <<-END

pre_install := #{top_builddir}/#{conf[:sub][:pb_build_prefix]}pb_pre_install
$(pre_install):  #{top_srcdir}/pre_install
\t#{top_builddir}/#{conf[:sub][:pb_build_prefix]}pb_config $< $@

        END
    else
        f.print "# there is no pre_install script\n\n"
    end


    if File.exist? conf[:top_src_fullpath] + '/post_install'
        f.print <<-END

post_install := #{top_builddir}/#{conf[:sub][:pb_build_prefix]}pb_post_install
$(post_install):  #{top_srcdir}/post_install
\t#{top_builddir}/#{conf[:sub][:pb_build_prefix]}pb_config $< $@

    END
    else
        f.print "# there is no post_install script\n\n"
    end


    f.write data
    f.close

    return dirs unless File.exist? bp_make_path

    subdirs = get_subdirs_from_make(buildpath, bp_make_path)

    # go to the next directory
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
        dirs.concat print_make_file(bld, conf, top_builddir, data)
    end

    dirs

end


# makes pb_pre_install or pb_post_install scripts using program pb_config
def check_gen_p_install_script(name, conf)

    inPath = conf[:top_src_fullpath] + '/' + name
 
    if File.exist? inPath
        outPath = Dir.pwd + '/' + conf[:sub][:pb_build_prefix] + 'pb_' + name
        config = conf[:sub][:pb_build_prefix] + 'pb_config'
        print_gen outPath
        f = IO.popen(config + ' - ' + outPath, 'w')
        f.write File.read(inPath)
        f.close
        unless $?.success?
            $stderr.print "  Failed to make #{outPath} from #{inPath}\n"
            exit 1
        end
    end
end


def get_DATA(conf, type, header = true)

    pre = ''
    post = ''
    first = ''
    last = ''

    if type == 'bash'
        first = "#!/bin/bash\n"
        pre = '#'
        last = "\n"
    elsif type == 'ruby'
        first = "#!/usr/bin/ruby -w\n"
        pre = '#'
        last = "\n"
    elsif type == 'php'
        first = "<?php\n"
        pre = '/* '
        post = ' */'
        last = '?>'
    elsif type == 'js' or type == 'css'
        pre = '/* '
        post = ' */'
    elsif type == 'make'
        first = "# This is a GNU make file which uses GNU make extensions\n"
        pre = '#'
        last = "\n"
    end

    if(header)
        data =
            "#{first}" +
            "#{pre}-------------------------------------------------#{post}\n" +
            "#{pre}#{conf[:sub][:generated_file_string]}#{post}\n" +
            "#{pre}-------------------------------------------------#{post}\n" +
            "#{last}"
    else
        data = ''
    end


    first_line = DATA.gets
    # We skip the first line if it starts with #!/ since we
    # added that above already.
    if first_line and not first_line =~ /^#!\//
        return data if first_line =~ $pb_file_seperator_regrex
        data += sub_line(conf[:sub], first_line)
    end

    DATA.each_line do |line|
        return data if line =~ $pb_file_seperator_regrex
        data += sub_line(conf[:sub], line)
    end
    data
end


def configure (conf)

    $stderr.print "(Re)Creating the following files in: #{Dir.pwd}/\n"

    if conf[:sub][:pb_build_prefix] and
        conf[:sub][:pb_build_prefix].length > 0
        pb_bld_dir = Dir.pwd + '/' + conf[:sub][:pb_build_prefix]
        if not File.exist? pb_bld_dir
            $stderr.print "    creating: #{pb_bld_dir}\n"
            FileUtils.mkdir_p pb_bld_dir
        end
    end

    # The order of the calls to get_DATA() matters and must
    # be compatible with the file GNUmakefile that makes phpbootstrap

    public_dirs = print_make_file('.', conf, '.', get_DATA(conf, 'make', false))
    conf[:sub][:public_dirs] = public_dirs

    gen_pb_config conf

    gen_pb_file('pb_php_compile', get_DATA(conf, 'bash'), conf, true)

    gen_pb_file('pb_cat_compile', get_DATA(conf, 'ruby'), conf, true)

    gen_pb_file('pb_auto_prepend.ph', get_DATA(conf, 'php').strip!, conf)

    gen_pb_file('pb_auto_append.ph', get_DATA(conf, 'php').strip!, conf)
    
    gen_pb_file('pb_utils.ph', get_DATA(conf, 'php').strip!, conf)

    gen_pb_file('pb_index.pphp', get_DATA(conf, 'php').strip!, conf, false, '')

    gen_pb_file('pb_index.cs', get_DATA(conf, 'css').strip, conf)

    check_gen_p_install_script('pre_install', conf)
    
    check_gen_p_install_script('post_install', conf)

end


def help_printParagraph(f, pre_space, text, width)

    len = text.length
    text.gsub!(/\n/,' ')
    charPerLine = width - pre_space.length
    i = 0

    while i < len do
        n = charPerLine
        i += 1 while i < len and text[i, 1] == ' '
        break if i == len
        if i + n < len
            n -= 1 while text[i + n - 1, 1] != ' ' and n > 10
        end
        n = charPerLine if n == 10
        f.print pre_space + text[i, n] + "\n"
        i += n
    end

    f.print "\n"

end

def help_printOpt(f, pre, text, max)

    text.gsub!(/\n/,' ')

    spaces = "                 " # indent
    indent = spaces.length
    charPerLine = max - indent
    itext = 0 # test index printed so far
    textLen = text.length

    pre = '   ' + pre + '  '

    f.print pre

    space_done = false

    if pre.length < indent
        # pad to indent position
        f.print spaces[0, indent - pre.length]
        space_done = true
    else
        f.print "\n"
    end


    while itext < textLen do
        n = charPerLine
        itext += 1 while itext < textLen and text[itext, 1] == ' '
        break if itext == textLen
        if itext + n < textLen
            n -= 1 while text[itext + n - 1, 1] != ' ' and n > 10
        end
        n = charPerLine if n == 10

        f.print spaces unless space_done
        f.print text[itext, n] + "\n"

        space_done = false
        itext += n
    end

    f.print "\n"
end


def usage(conf)

    # length of printed text line
    max = %x[tput cols]
    if $?.success?
        max = max.to_i - 5
        if max > 90
            max = 90
        elsif max < 40
            max = 40
        end
    else
        max = 80
    end


    $stdout.print "\n"
    help_printParagraph($stdout, '    ', <<END, max)
Usage: #{File.basename __FILE__} [OPTIONS]
END
    help_printParagraph($stdout, '  ', <<END, max)
This configure script was generated by phpbootstrap
for the package: #{$pb_package_name}.
END
    help_printParagraph($stdout, '  ', <<END, max)
Creates GNUmakefile make files.  Files are installed with the same
directory structure as the source files in a web accessible directory
we refer to as PUBLIC below, with some exceptions.  Files in the top
source directory in a directory named private/ will be installed into
the directory refered to as PRIVATE below.  Files in the top source
directory in a directory named bld_include/ will not be installed.
bld_include/ will contain files that the compiles use to make other
files.  So there are four classes of files in the source tree:
END
    help_printParagraph($stdout, '       ', <<END, max)
1. (optional) all files in bld_include/,
END
    help_printParagraph($stdout, '       ', <<END, max)
2. (optional) all files in private/,
END
    help_printParagraph($stdout, '       ', <<END, max)
3. all other files that have file suffixes that are installed or
have make rules that generate files that are installed, and
END
    help_printParagraph($stdout, '       ', <<END, max)       
4. all other files.
END
    help_printParagraph($stdout, '  ', <<END, max)
This will likely conflict with a pre-existing web serivce project.
phpbootstrap is not designed for retrofixed into pre-existing web
serivce projects.
END
    $stdout.print <<END


            -------- standard OPTIONS --------


END

    help_printOpt($stdout, '--help|-h', 'print this help and exit', max)
  
    help_printOpt($stdout, '--debug true|false',
                'make it a debug build, i.e. not production, or not', max)

    help_printOpt($stdout, '--prefix PREFIX',<<END, max)
full path to where to install PUBLIC and PRIVATE docs.
The current default is: #{conf[:default_prefix]}
Setting this will set PRIVATE and PUBLIC to PREFIX/private
and PREFIX/public respectively.
END

    help_printOpt($stdout, '--private PRIVATE', <<END, max)
full path prefix to installed files that are not web accessible.
The default is PREFIX/private.  Setting this will override PREFIX.
END
    help_printOpt($stdout, '--public PUBLIC', <<END, max)
full path prefix to installed files that are web accessible.
The default is PREFIX/public.  Setting this will override PREFIX.
END

    help_printOpt($stdout, '--version|-V',
        'print the phpbootstrap version number (#{$pb_version}) and exit.', max)


    if $pb_options

        $stdout.print <<-END



              -------- #{$pb_package_name} OPTIONS --------



        END

        $pb_options.each do |name,val|
            help_printOpt($stdout, '--' + name.to_s + ' VALUE',
                         val[:description] +
                         ".  The default VALUE is '" + val[:value] + "'", max)
        end
    end
    exit 1
end



def which(path)

    return path if path[0] == '/'
    ENV['PATH'].split(':').each do |d|
        p =  d + '/' + path
        if File.exist? p
            return p
        end
    end
    path
end

def check_package_option(arg, conf)

    $pb_options.each do |name,val|
        if ret = check_arg('--' + name.to_s, arg, conf)
            return [name, ret]
        end
    end
    false
end

def parse_args

    arg = ARGV.shift
    conf = {}
    conf[:sub] = {}
    conf[:sub][:php_path] = which 'php'
    conf[:sub][:yui_path] = which 'yui-compressor'
    conf[:sub][:js_compile] = false
    conf[:sub][:css_compile] = false
    # default debug value # TODO change this
    conf[:sub][:debug] = true

    conf[:default_prefix] =  Dir.pwd + '/pb_service'
    conf[:public] = Dir.pwd + '/pb_service/public'
    conf[:private] = Dir.pwd + '/pb_service/private'

    conf[:sub][:install_user] = Etc.getpwuid(Process.uid).name

    # Get the package info into conf[:sub]
    $pb_conf.each { |k,v| conf[:sub][k] = v }

    $pb_options.each do |name,val|
         conf[:sub][name] = val[:value]
    end


    while arg
        if  arg =~ /(--version|-V)/
            puts $pb_version
            exit
        elsif ret = check_arg('--public', arg, conf)
            conf[:public] = File.expand_path ret
        elsif ret = check_arg('--private', arg, conf)
            conf[:private] = File.expand_path ret
        elsif ret = check_arg('--prefix', arg, conf)
            ret = File.expand_path ret
            conf[:public] = ret + '/public'
            conf[:private] = ret + '/private'
        elsif ret = check_arg('--debug', arg, conf)
            ret = ret.downcase
            if conf[:sub][:debug] # default is true
                conf[:sub][:debug] = 'false' if ret =~ /(^n|^f|^0|^of)/
            else
                conf[:sub][:debug] = 'true' if ret =~ /(^y|^t|^[1-9]|^on|^al)/
            end
        elsif ret = check_package_option(arg, conf)
            conf[:sub][ret[0]] = ret[1]
        else
            usage conf
        end
        arg = ARGV.shift
    end

    conf[:top_src_fullpath] = File.dirname $script_path
    conf[:top_build_path] = Dir.pwd

    [ conf[:public], conf[:private]].each do |f|
        if File.exist?(f) and not File.directory?(f)
            $stderr.print "\nfile #{f} exists and is not a directory\n\n"
            exit 1
        end
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

    conf[:sub][:private] = conf[:private]
    conf[:sub][:public] = conf[:public]

    # TODO: see if public is in a subdirectory?
    if File.directory?('public')
        conf[:public_in_topsrc] = false
    else
        conf[:public_in_topsrc] = true
    end

    conf[:sub][:include_path_relto_pb_build] =
        find_include_path_relto_pb_build(conf[:sub][:pb_build_prefix],
                                        conf[:sub][:rel_include_dir])

    conf[:rel_include_dir_regrex] =
        Regexp.new( '^' +
                   Regexp.escape(conf[:sub][:rel_include_dir]) +
                   '($|\\/)')

    conf
end

configure parse_args

