#- -*-Mode: Makefile;-*--------------------------------------------------
#
# File  : Makefile for the DB part of MPTP
#
# Author: Josef Urban
#
#
# Changes
#
# <1> Tue Feb 11 21:26:44 2003
#     New
#------------------------------------------------------------------------

include ../Makefile.vars

# Project specific variables

allreq 	= $(addprefix $(REQDIR)/, $(addsuffix .dre,$(REQFILES)))

cleanlogs:
	@echo "Cleaning logs"
	@for i in $(LOGS); do if test -f $$i; then rm -r -f $$i; fi; done;

cleandirs:
	@echo "Removing directories"
	@for dir in $(LETTERS); do \
		if test -d $$dir; then rm -r -f $$dir; fi; \
	done;

dirs:	
	@echo "Setting directories"
	@for dir in $(LETTERS); do \
		if test ! -d $$dir; then mkdir $$dir; fi; \
	done;

links:	dirs $(MMLLAR) 
	@echo "Setting links to MML files using $(MMLLAR)"
	@for f in $(ALLMIZ); do \
		d=$${f:0:1};\
		fm=$$f.$(MIZ);\
		if test ! -L $$d/$$fm; then \
			$(LN) $(MFILES)/mml/$$fm $$d/$$fm; \
		fi;\
	done;

reqlinks: dirs
	@echo "Setting links to requirement files"
	@for f in $(REQFILES); do \
		d=$${f:0:1};\
		fm=$$f.dre;\
		if test ! -L $$d/$$fm; then \
			$(LN) $(REQDIR)/$$fm $$d/$$fm; \
		fi;\
	done;

cleanevl: 
	rm -r -f [a-z]/*.evl

# This is a bit insufficient, if prels changed, then we need the
# accommodator anyway, regardless of .miz

%.evl: %.miz
	$(ACCOM) $* >> $(ACCLOG)

allevl	=  $(addsuffix .evl,$(ALLMIZPREF))

accommodate: links $(allevl)
	@echo "All accommodated"

# This used to be %.pre, but other programs than just verifier
# create .pre, so verifier would not run after them

%.vrf: %.evl
	$(VERIFIER) $* >> $(VERIFLOG)
	@touch $@

stdverify	=  $(addsuffix .vrf,$(STDMIZPREF))

verify:  links $(stdverify)
	@echo "All verified"

# Relcprem

%.rlc: %.evl
	$(RELCPREM) $* >> $(RLCLOG)	

stdrlc	=  $(addsuffix .rlc,$(STDMIZPREF))

rlcfiles: links $(stdrlc)
	@echo "All rlc done"

# Some .dsf have size zero, so on not so old reiserfs, they will
# be rebuilt :-(. Fixing this by touching them now.
# .bys files are produced by $(FO_TOOL), we gzip them immediately.
# and move to $(BYSDIR)

%.dsf: %.evl $(FO_TOOL)
	$(FO_TOOL) $(FO_FLAGS) $* >> $(FOLOG)
	@if test ! -s $@; then touch $@; fi
	@if test -f $*.bys; then \
	 	$(GZIP) -f $*.bys; mv -f $*.bys.gz $(BYSDIR); \
	fi


stddsf	=  $(addsuffix .dsf,$(STDMIZPREF))

# This overrides the implicit pattern for error causing files

$(addsuffix .dsf,$(NONSTDMIZPREF)): %.dsf: %.evl $(FO_TOOL)
	-$(FO_TOOL) $(FO_FLAGS) $* >> $(FOLOG)
	@if test ! -s $@; then touch $@; fi
	@if test -f $*.bys; then \
		$(GZIP) -f $*.bys; mv -f $*.bys.gz $(BYSDIR); \
	fi

nonstddsf	= $(addsuffix .dsf,$(NONSTDMIZPREF))

alldsf	= $(stddsf) $(nonstddsf)

cleandsf: 
	rm -r -f [a-z]/*.dsf

hiddenexts 	= dco dem dsf dsp evl pro
linkhidden:
	@for e in $(hiddenexts); do \
		rm -r -f  h/hidden.$$e; \
		$(LN) $(REQDIR)/hidden.$$e h/hidden.$$e; \
	done;


dfg_export: links reqlinks $(alldsf) linkhidden
	@echo "All exported"

# Check that the number of formulas is equal to the number of the 
# last one - this assumes canceled are exported too.

checkthe: $(alldsf)
	@for f in $(ALLMIZPREF);do \
		if test -s $$f.the;then \
		  nr=`grep -c formula $$f.the`; t=`tail -n1 $$f.the`;\
		  hit=`echo $$t|grep $$nr`; \
		  if test ! $$hit; then echo "Error in $$f.the"; exit 1; fi;\
	         fi;\
	done;
	@echo "All .the files checked ok"

checkdef: $(alldsf)
	@for f in $(ALLMIZPREF);do \
		if test -s $$f.def;then \
		  nr=`grep -c formula $$f.def`; t=`tail -n1 $$f.def`;\
		  hit=`echo $$t|grep $$nr`; \
		  if test ! $$hit; then echo "Error in $$f.def"; exit 1; fi;\
	         fi;\
	done;
	@echo "All .def files checked ok"


theorems.db: $(alldsf)
	rm -r -f theorems.db
	@for f in $(ALLMIZPREF);do \
		if test -f $$f.the;then cat $$f.the; fi;\
	done > theorems.db 
	@echo "Created theorems.db using $(MMLLAR)"

definitions.db: $(alldsf)
	rm -r -f definitions.db
	@for f in $(ALLMIZPREF);do \
		if test -f $$f.def;then cat $$f.def; fi;\
	done > definitions.db 
	@echo "Created definitions.db using $(MMLLAR)"

constrtypes.db:  $(alldsf) 
	rm -r -f constrtypes.db
	@for f in $(ALLMIZPREF);do \
		if test -f $$f.dco;then cat $$f.dco; fi;\
	done > constrtypes.db 
	@echo "Created constrtypes.db using $(MMLLAR)"


STDEXTS = the def dco dem pro cle clf clc dsf dsp dre

# Just a check, is produced by $(alldsf)

allbys	=  $(addprefix $(BYSDIR)/, $(addsuffix .bys.gz,$(ALLMIZ)))


counts.db: $(alldsf) $(allbys)
	@echo "Making all databases, be patient"
	rm -r -f counts.db
	for e in $(STDBS) references.db; do rm -r -f $$e; done
# Insert the first newline
	@for e in $(STDEXTS); do rm -r -f $$e;  echo > $$e; done
	for f in $(ALLMIZREQPREF); do n=$${f:2}; \
	  echo -n "counts(" >> counts.db; \
	  for e in $(STDEXTS); do \
	    if test -f $$f.$$e;then cat $$f.$$e >>$$e; \
	      c=`grep -c "[.]" $$f.$$e`;	\
	    else c=0; \
	    fi; \
	    echo -n "$$c," >> counts.db; \
	  done;\
	  if test -f $(BYSDIR)/$$n.bys.gz;then \
            c=`gzip -dc $(BYSDIR)/$$n.bys.gz | grep -c "[.]"`;	\
	    else c=0; \
	  fi; \
	  echo -n "$$c," >> counts.db; \
	  echo "$$n)." >> counts.db; \
	  if test -f $$f.thr;then cat $$f.thr >>references.db; fi;\
	  echo "$$n inserted";\
	done;
	@mv the theorems.db; mv def definitions.db; \
	mv dco constrtypes.db; mv dem exmodes.db; mv pro properties.db; \
	mv cle exclusters.db; mv clf  funcclusters.db; mv clc condclusters.db; \
	mv dsf funcarities.db; mv dsp predarities.db; mv dre requirements.db
	@echo "Created $(STDBS) references.db and counts.db using $(MMLLAR)"

runningcounts.db: counts.db
	rm -r -f runningcounts.db
	@perl -e '$$t=0;$$d=0;$$co=0;$$em=0;$$pr=0;$$ec=0;$$fc=0; \
	$$cc=0; $$fa=0;$$pa=0;$$r=0;$$chk=0; \
	while (<>) { \
	/counts[(](\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\w+)[)][.]/;\
	print "runningcounts($$t,$$d,$$co,$$em,$$pr,$$ec,$$fc,$$cc,$$fa,$$pa,$$r,$$chk,$$13).\n"; \
	$$t+=$$1;$$d+=$$2;$$co+=$$3;$$em+=$$4;$$pr+=$$5;$$ec+=$$6; \
	$$fc+=$$7;$$cc+=$$8; \
	$$fa+=$$9;$$pa+=$$10;$$r+=$$11;$$chk+=$$12}' < counts.db \
	> runningcounts.db
	@echo "Created runningounts.db from counts.db"


# To have environments.db corresponding to counts.db

ADDEDREQENVFIX	= "env([],[],[],[],[],[],[],[],[])."

environments.db: $(alldsf)
	rm -r -f environments.db;
	@for f in $(ADDEDREQFILES); do \
	  echo $(ADDEDREQENVFIX) >> environments.db; \
	done;
	@for f in $(ALLMIZPREF);do \
	  perl -F $(DBENV) $$f >> environments.db; \
	  echo "Environment for $$f inserted"; \
	done; 
	@echo "Created environments.db"



reinstall: cleandirs cleanlogs dfg_export counts.db runningcounts.db environments.db

cleaninstall: reinstall cleandirs cleanlogs


# theorems.db:
# references.db:  Contains refernces needed for each theorem.
# definitions.db:
# constrtypes.db:
# exmodes.db;
# properties.db;
# exclusters.db:
# funcclusters.db:
# condclusters.db:
# funcarities.db:
# predarities.db:
# requirements.db:
# # usersymbols.db:
# environments.db: This db contains info on each article's environment 
# 		 directives, these are now:
# 		  dirVocabulary,dirNotations, dirDefinitions,dirTheorems,
# 		  dirSchemes,dirClusters, dirConstructors,dirRequirements,
# 		  dirProperties.
# 		 Since the dirConstructors behaves recursively, we keep
# 		 its transitive closure already here.

# counts.db: Contains for each article counts of its various items.
# runningcounts.db: Is a version of counts.db with running sums. This
# 		  is used for fast access into the databases.
