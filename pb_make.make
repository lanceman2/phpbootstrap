# This is a GNU make file which uses GNU make extensions

ifdef SUBDIRS
  subdirs := $(strip $(SUBDIRS))
  ifeq ($(strip subdirs),)
    undefine subdirs
  endif
endif


# built_compilerscript_finalsuffix

built_in_any = $(strip $(patsubst $(srcdir)/%.in, %, $(wildcard $(srcdir)/*.in)))

built_php_html = $(sort \
 $(patsubst $(srcdir)/%.phtml, %.html, $(wildcard $(srcdir)/*.phtml))\
 $(patsubst $(srcdir)/%.phtml.in, %.html, $(wildcard $(srcdir)/*.phtml.in)))
built_php_htm = $(sort \
 $(patsubst $(srcdir)/%.phtm, %.htm, $(wildcard $(srcdir)/*.phtm))\
 $(patsubst $(srcdir)/%.phtm.in, %.htm, $(wildcard $(srcdir)/*.phtm.in)))
built_php_php = $(sort \
 $(patsubst $(srcdir)/%.pphp, %.php, $(wildcard $(srcdir)/*.pphp))\
 $(patsubst $(srcdir)/%.pphp.in, %.php, $(wildcard $(srcdir)/*.pphp.in)))
built_php_js = $(sort \
 $(patsubst $(srcdir)/%.pjs, %.js, $(wildcard $(srcdir)/*.pjs))\
 $(patsubst $(srcdir)/%.pjs.in, %.js, $(wildcard $(srcdir)/*.pjs.in)))
built_php_css = $(sort \
 $(patsubst $(srcdir)/%.pcss, %.css, $(wildcard $(srcdir)/*.pcss))\
 $(patsubst $(srcdir)/%.pcss.in, %.css, $(wildcard $(srcdir)/*.pcss.in)))
built_php_jsp = $(sort \
 $(patsubst $(srcdir)/%.pjsp, %.jsp, $(wildcard $(srcdir)/*.pjsp))\
 $(patsubst $(srcdir)/%.pjsp.in, %.jsp, $(wildcard $(srcdir)/*.pjsp.in)))
built_php_cs = $(sort \
 $(patsubst $(srcdir)/%.pcs, %.cs, $(wildcard $(srcdir)/*.pcs))\
 $(patsubst $(srcdir)/%.pcs.in, %.cs, $(wildcard $(srcdir)/*.pcs.in)))
built_php = $(strip\
 $(built_php_html)\
 $(built_php_htm)\
 $(built_php_php)\
 $(built_php_js)\
 $(built_php_css)\
 $(built_php_jsp)\
 $(built_php_cs))


built_cat_html = $(sort \
 $(patsubst $(srcdir)/%.chtml, %.html, $(wildcard $(srcdir)/*.chtml))\
 $(patsubst $(srcdir)/%.chtml.in, %.html, $(wildcard $(srcdir)/*.chtml.in)))
built_cat_htm = $(sort \
 $(patsubst $(srcdir)/%.chtm, %.htm, $(wildcard $(srcdir)/*.chtm))\
 $(patsubst $(srcdir)/%.chtm.in, %.htm, $(wildcard $(srcdir)/*.chtm.in)))
built_cat_php = $(sort \
 $(patsubst $(srcdir)/%.cphp, %.php, $(wildcard $(srcdir)/*.cphp))\
 $(patsubst $(srcdir)/%.cphp.in, %.php, $(wildcard $(srcdir)/*.cphp.in)))
built_cat_js = $(sort \
 $(patsubst $(srcdir)/%.cjs, %.js, $(wildcard $(srcdir)/*.cjs))\
 $(patsubst $(srcdir)/%.cjs.in, %.js, $(wildcard $(srcdir)/*.cjs.in)))
built_cat_css = $(sort \
 $(patsubst $(srcdir)/%.ccss, %.css, $(wildcard $(srcdir)/*.ccss))\
 $(patsubst $(srcdir)/%.ccss.in, %.css, $(wildcard $(srcdir)/*.ccss.in)))
built_cat_jsp = $(sort \
 $(patsubst $(srcdir)/%.cjsp, %.jsp, $(wildcard $(srcdir)/*.cjsp))\
 $(patsubst $(srcdir)/%.cjsp.in, %.jsp, $(wildcard $(srcdir)/*.cjsp.in)))
built_cat_cs = $(sort \
 $(patsubst $(srcdir)/%.ccs, %.cs, $(wildcard $(srcdir)/*.ccs))\
 $(patsubst $(srcdir)/%.ccs.in, %.cs, $(wildcard $(srcdir)/*.ccs.in)))
built_cat = $(strip\
 $(built_cat_html)\
 $(built_cat_htm)\
 $(built_cat_php)\
 $(built_cat_js)\
 $(built_cat_css)\
 $(built_cat_jsp)\
 $(built_cat_cs))


built_md_html = $(sort \
 $(patsubst $(srcdir)/%.md, %.html, $(wildcard $(srcdir)/*.md))\
 $(patsubst $(srcdir)/%.md.in, %.html, $(wildcard $(srcdir)/*.md.in)))
built_depend = $(strip $(addsuffix .d, $(built_php) $(built_cat)))


# find the files that are installed but not generated
fromsrc := $(strip\
 $(wildcard $(srcdir)/*.php)\
 $(wildcard $(srcdir)/*.html)\
 $(wildcard $(srcdir)/*.htm)\
 $(wildcard $(srcdir)/*.js)\
 $(wildcard $(srcdir)/*.css)\
 $(wildcard $(srcdir)/*.txt))
installed_fromsrc :=
ifneq ($(fromsrc),)
  # String '@generated_file_string@' matches string
  # put in files from pb_php_compile and pb_cat_compile
  define GET_fromsrc =
    installed_fromsrc := $$(installed_fromsrc) $$(shell\
      if ! head -5 $(1) | grep -q '@generated_file_string@' ;\
        then echo "$$(notdir $(1))"; fi)
  endef
$(foreach f,$(fromsrc),$(eval $(call GET_fromsrc,$(f))))
undefine GET_fromsrc
undefine gen_file_str
endif
undefine fromsrc
installed_fromsrc := $(strip $(installed_fromsrc))


ifndef srcdir_equals_builddir
  ifneq ($(strip $(wildcard $(top_srcdir)/@pb_build_prefix@pb_php_compile)),)
    $(error You cannot build this code in this directory\
 while building it in the source at $(top_srcdir))
  endif
endif


built_gzip_gz := $(addsuffix .gz,\
 $(filter-out %.cs %.jsp %.php,\
 $(built_php)\
 $(built_cat)\
 $(built_md_html)\
 $(installed_fromsrc)))

built := $(strip\
 $(built_in_any)\
 $(built_php)\
 $(built_cat)\
 $(built_md_html)\
 $(built_gzip_gz))

ifdef installdir
installed := $(strip $(filter-out %.cs %.jsp %.ph %.phd, $(built)) $(installed_fromsrc))

# Check for duplicate installed files.
# This is why we did not sort $(built) and $(installed).
dups :=
define CHECK_dups =
  ifneq ($$(findstring $(1),$$(dups)),)
      $$(error Found duplicate installed file $(1)\
 in installed files = "$$(installed)")
  endif
  dups := $$(dups) $(1)
endef
$(foreach f,$(installed),$(eval $(call CHECK_dups,$(f))))
undefine dups
undefine CHECK_dups
endif # ifdef installdir


clean_files := $(sort $(built) $(wildcard *.d))
distclean_files := $(strip\
 $(clean_files)\
 GNUmakefile\
 $(add_distclean))


php_compile := $(top_builddir)/@pb_build_prefix@pb_php_compile
cat_compile := $(top_builddir)/@pb_build_prefix@pb_cat_compile

ifdef subdirs
build_rec = build_rec
clean_rec = clean_rec
_debug_rec = _debug_rec
distclean_rec = distclean_rec
install_rec = install_rec
endif


ifeq ($(strip $(installed)),)
undefine installed
endif
ifeq ($(strip $(built)),)
undefine built
endif



.DEFAULT_GOAL = build


#####################################################################
# BEGIN RULES    How we do stuff.  There are some rules above :(
#####################################################################

.PHONY: _debug build install clean distclean\
 $(_debug_rec) $(build_rec) $(install_rec) $(clean_rec) $(distclean_rec)\
 _debug_norec build_norec install_norec clean_norec distclean_norec\
 _debug_do build_do install_do clean_do distclean_do post_install


.SUFFIXES:
.SUFFIXES: .md .html .htm .html .ht .php .ph .phd .css .js .gz\
 .pphp .phtml .phtm .pjs .pcss .cphp .chtml .chtm .cjs .ccss .txt\
 .jsp .cs .ht .ph .phd .cjsp .ccs


.INTERMEDIATE:

.SECONDARY:


define MAKE_in_rules =
  $(1): $(1).in
	$(top_builddir)/@pb_build_prefix@pb_config $(srcdir)/$(1).in $(1)
endef
$(foreach suf,$(built_in_any),$(eval $(call MAKE_in_rules,$(suf))))
undefine MAKE_in_rules



# remove some GNU make implicit rules
% : s.%
% : RCS/%,v
% : SCCS/s.%
% : %,v
% : RCS/%
% : %.o

# include depend files which are generated each time
# pb_php_compile and pb_cat_compile run.
include $(wildcard *.d)


# NOTE: we do not compile .jsp to a .js directly with YUI, and the same
# goes for .cs to .css; instead we use .cjs and .ccss or .pjs and .pcss
# respectively.

# generic suffix rules
%.html: %.md
	marked $< > $@
%.php: %.pphp
	$(php_compile) $< $@ $(url_path_dir)
%.php: %.cphp
	$(cat_compile) $< $@
%.html: %.phtml
	$(php_compile) $< $@ $(url_path_dir)
%.html: %.chtml
	$(cat_compile) $< $@
%.htm: %.phtm
	$(php_compile) $< $@ $(url_path_dir)
%.htm: %.chtm
	$(cat_compile) $< $@
%.js: %.pjs
	$(php_compile) $< $@ $(url_path_dir)
%.jsp: %.pjsp
	$(php_compile) $< $@ $(url_path_dir)
%.css: %.pcss
	$(php_compile) $< $@ $(url_path_dir)
%.cs: %.pcs
	$(php_compile) $< $@ $(url_path_dir)
%.js: %.cjs
	$(cat_compile) $< $@
%.jsp: %.cjsp
	$(cat_compile) $< $@
%.css: %.ccss
	$(cat_compile) $< $@
%.cs: %.ccs
	$(cat_compile) $< $@
%.gz: %
	gzip -kf $<


clean: clean_norec $(clean_rec)
clean_norec: $(clean_rec)

clean_do:

clean_do clean_norec:
ifneq ($(clean_files),)
	rm -f $(clean_files)
else
	@echo "nothing to clean"
endif

distclean: distclean_norec $(distclean_rec)
distclean_norec: $(distclean_rec)

distclean_do:

distclean_norec:
ifneq ($(distclean_files),)
	rm -f $(distclean_files)
  ifeq ($(strip $(top_builddir)),.)
	if [ -n '@pb_build_prefix@' ] &&\
	    [ -z "$(ls -A @pb_build_prefix@)" ] ; then\
	    rmdir @pb_build_prefix@ ; fi
  endif
else
	@echo "nothing to distclean"
endif


_debug: _debug_norec $(_debug_rec)
ifdef subdirs
$(_debug_rec): _debug_norec
endif
_debug_norec: _debug_do

_debug_do:
	@echo "subdirs = $(subdirs)"
	@echo "built = $(built)"
	@echo "installed = $(installed)"
	@echo "install_rec=$(install_rec)"
	@echo "build_rec=$(build_rec)"
	@echo "built_in_any=$(built_in_any)"
	@echo "srcdir=$(srcdir)"
	@echo "VPATH=$(VPATH)"


build_norec build_do: $(built)
install_norec install_do: $(installed)


install_norec install_do:
ifeq ($(MAKELEVEL),0)
ifdef pre_install
	$(pre_install)
endif
endif
ifdef installed
	if [ ! -d $(installdir) ] ; then\
	    mkdir -p $(installdir) ; fi
	cp $(installed) $(installdir)
endif


ifdef post_install
ifeq ($(MAKELEVEL),0)
install: post_install
post_install: install_do $(install_rec)
	$(post_install)
endif
endif


ifeq ($(findstring .,$(subdirs)),.)
  build: build_rec
  install: install_rec
else
  ifdef subdirs
    build_rec: build_norec
    install_rec: install_norec
    build: build_norec build_rec
    install: install_norec install_rec
  else
    build: build_do
    install: install_do
  endif
endif


# We check for sub directory make file removal as we recurse
ifdef subdirs

build_rec clean_rec _debug_rec distclean_rec install_rec:
	for d in $(subdirs); do\
	  if [ $$d != . ] ; then\
	    $(MAKE) -C $$d $(patsubst %_rec,%,$@) || exit 1 ;\
	  else\
	    $(MAKE) -C $$d $(patsubst %_rec,%_do,$@) || exit 1 ;\
	  fi ; done
endif
