# This is a GNU makefile which uses GNU make extensions
# GNUmakefile is the preferred default makefile for GNU make

build: phpbootstrap README.html

top_files =\
 pb_version.rb\
 pb_main_program.rb\
 pb_END_section.rb

# ruby __DATA__ added to end of phpbootstrap
data_files =\
 pb_make.make\
 pb_php_compile\
 pb_cat_compile\
 pb_auto_prepend.ph\
 pb_auto_append.ph\
 pb_index.cs\
 pb_debug_index.phtml

seperator = "\#\# End: phpbootstrap ruby DATA build file:"

phpbootstrap: $(top_files) $(data_files) GNUmakefile
	echo "#!/usr/bin/ruby -w" > $@
	echo "################################################################" >> $@
	echo "# THIS IS A GENERATED FILE" >> $@
	echo "# Do not edit this file" >> $@
	echo "################################################################" >> $@
	echo >> $@
	echo "\$$pb_file_seperator_regrex = /^$(seperator)/" >> $@
	echo >> $@
	cat $(top_files) >> $@
	for f in $(data_files) ; do\
	    cat $$f >> $@ || exit 1 ;\
	    echo "$(seperator) $$f" >> $@ || exit 1 ;\
	    done
	chmod 755 $@

README.html: %.html: %.md
	marked $< > $@

clean distclean:
	rm -f phpbootstrap README.html
	$(MAKE) -C examples/ distclean


ifdef bindir
install: phpbootstrap
	mkdir -p $(bindir)
	cp phpbootstrap $(bindir)
else
install:
	@echo "Install it where?  Try something like:"
	@echo
	@echo "    $(MAKE) bindir=BINDIR install"
	@echo
	@echo "Where BINDIR is the path to a directory."
endif
