#####################################################################
# This file is part of the phpbootstrap package build system
#
# This is a GNU make file which uses GNU make extensions
#


ifneq ($(strip $(srcdir)),.)
  VPATH := .:$(srcdir)
endif

ifdef SUBDIRS
  subdirs := $(strip $(SUBDIRS))
  ifeq ($(strip subdirs),)
    undefine subdirs
  endif
endif


# built_compilerscript_finalsuffix

built_in_any = $(sort $(patsubst $(srcdir)/%.in, %, $(wildcard $(srcdir)/*.in)))

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
  define GET_fromsrc =
    # gen_file_str matches gen_file_str in pb_php_compile
    gen_file_str := This is the generated file $$(notdir $(1))
    installed_fromsrc := $$(installed_fromsrc) $$(shell\
      if ! head -5 $(1) | grep -q '$$(gen_file_str)' ; then echo "$$(notdir $(1))"; fi)
  endef
$(foreach f,$(fromsrc),$(eval $(call GET_fromsrc,$(f))))
undefine GET_fromsrc
undefine gen_file_str
endif
undefine fromsrc
installed_fromsrc := $(strip $(installed_fromsrc))


ifndef srcdir_equals_builddir
  ifneq ($(strip $(wildcard $(top_srcdir)/pb_php_compile)),)
    $(error You cannot build this code in this directory\
 while building it in the source at $(top_srcdir))
  endif
endif


built_uncompressed = $(strip $(built_php) $(built_cat) $(built_md_html))
built_gzip_gz = $(addsuffix .gz,\
 $(filter-out %.cs %.jsp, $(built_uncompressed) $(installed_fromsrc)))

built := $(strip $(built_uncompressed) $(built_gzip_gz))

installed := $(strip $(filter-out %.cs %.jsp, $(built)) $(installed_fromsrc))

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


clean_files := $(sort $(built))
distclean_files := $(clean_files)\
 GNUmakefile

ifeq ($(strip $(top_builddir)),.)
distclean_files := $(strip\
 $(distclean_files)\
 pb_auto_prepend.ph\
 pb_auto_append.ph\
 pb_php_compile\
 pb_cat_compile\
 pb_config)
endif

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



.DEFAULT_GOAL = build

#####################################################################
# END VARIABLE DEFINITIONS
#####################################################################

#####################################################################
# BEGIN RULES    How we do stuff.  There are some rules above :(
#####################################################################

.PHONY: $(build_rec) $(clean_rec) $(_debug_rec) $(distclean_rec) $(install_rec)\
 build clean _debug distclean install _debug_norec $(install) all

.SUFFIXES:
.SUFFIXES: .md .html .htm .html .php .ph .phd .css .js .in .d .gz\
 .pphp .phtml .phtm .pjs .pcss .cphp .chtml .chtm .cjs .ccss .txt\
 .jsp .cs .ht .ph .phd .cjsp .ccs


.INTERMEDIATE:

.SECONDARY:


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


# generic suffix rules
%: %.in
	$(top_builddir)/pb_config $< $@
%.html: %.md
	marked $< > $@
%.php: %.pphp
	$(top_builddir)/pb_php_compile $< $@
%.php: %.cphp
	$(top_builddir)/pb_cat_compile $< $@
%.html: %.phtml
	$(top_builddir)/pb_php_compile $< $@
%.html: %.chtml
	$(top_builddir)/pb_cat_compile $< $@
%.htm: %.phtm
	$(top_builddir)/pb_php_compile $< $@
%.htm: %.chtm
	$(top_builddir)/pb_cat_compile $< $@
%.js: %.pjs
	$(top_builddir)/pb_php_compile $< $@
%.jsp: %.pjsp
	$(top_builddir)/pb_php_compile $< $@
%.css: %.pcss
	$(top_builddir)/pb_php_compile $< $@
%.cs: %.pcs
	$(top_builddir)/pb_php_compile $< $@
%.js: %.cjs
	$(top_builddir)/pb_cat_compile $< $@
%.jsp: %.cjsp
	$(top_builddir)/pb_cat_compile $< $@
%.css: %.ccss
	$(top_builddir)/pb_cat_compile $< $@
%.cs: %.ccs
	$(top_builddir)/pb_cat_compile $< $@
%.gz: %
	gzip -k -v $<


clean: $(clean_rec)
ifneq ($(clean_files),)
	rm -f $(clean_files)
else
	@echo "nothing to clean"
endif

distclean: $(distclean_rec)
ifneq ($(distclean_files),)
	rm -f $(distclean_files)
else
	@echo "nothing to distclean"
endif


_debug: _debug_norec $(_debug_rec)
$(_debug_rec): _debug_norec
_debug_norec:
	@echo "subdirs = $(subdirs)"
	@echo "built = $(built)"
	@echo "installed = $(installed)"



# Force the order in which things are built
$(build_rec): $(built)
build all: $(built)

ifdef installed
install: $(installed)
endif
$(install_rec): $(installed)




# We check for sub directory make file removal as we recurse
ifdef subdirs
build_rec clean_rec _debug_rec distclean_rec install_rec:
	@for d in $(subdirs); do\
          target="$(patsubst %_rec,%,$@)" ;\
          cd $$d || exit 1 ;\
	  if [ ! -f GNUmakefile ] ; then\
	    echo 'Missing GNUmakefile in ${PWD}' ;\
	    exit 1 ;\
	  fi ;\
          $(MAKE) $$target || exit 1 ;\
          cd .. || exit 1 ;\
          done
endif

