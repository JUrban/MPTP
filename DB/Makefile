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
		if test ! -e $$d/$$fm; then \
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

# Generic for irrelevant utility linked to $(IRRUTIL)
%.irr: %.evl
	-$(IRRUTIL) -q $* >> $(IRRLOG)
	@touch $@

stdirr	= $(addsuffix .irr,$(STDMIZPREF))

irr_util: links $(stdirr)
	@echo "All irrelevant done"

# the edtfile - risky
move_edt:
	@for i in $(STDMIZPREF); do mv $$i."$$""-$$"  $$i.miz; done

set_mml_time:
	@for i in $(STDMIZPREF); do touch -r $(MMLLAR) $$i.miz; done
	@echo "Miz files made as old as MML"

# Relcprem - we have to ignore errors now, should be fixed in
# relcprem

%.rlc: %.evl
	-$(RELCPREM) -q $* >> $(RLCLOG)	

$(addsuffix .rlc,$(NONSTDMIZPREF)): %.rlc: %.evl
	@echo \! > $*.rlc

stdrlc	=  $(addsuffix .rlc,$(STDMIZPREF))
nonstdrlc	= $(addsuffix .rlc,$(NONSTDMIZPREF))
allrlc	= $(stdrlc) $(nonstdrlc)

rlcfiles: links $(RELCPREM) $(stdrlc)
	@echo "All rlc done"

%.tptp: %.rlc
	$(TPTPEXP) -q $* >> $(TPTPLOG)


# These cause errors to $(FO_TOOL) now in the DNF module
# (too many clause from one formula)

badtptp = g/gate_1 g/gate_2 g/gate_3 g/gate_4 g/gate_5 # p/polynom1

mommworking = $(filter-out $(badtptp),$(STDMIZPREF))
workingtptp = $(addsuffix .tptp,$(mommworking))
workingths  = $(addsuffix .ths,$(mommworking))
workingtyp  = $(addsuffix .typ,$(mommworking))

MOMMTYPES   = $(DBDIR)/all.typ

# MEMLIMIT for reduce.pl
REDMEMLIMIT = 300000000

MOMM	= $(ADDBIN)/MoMM
REDLOG	= $(DBDIR)/00red.log

REDTMPDIR   = $(DBDIR)/REDTMP
REDPLANNER  = $(ADDSCRIPT)/reduce.pl
REDSCRIPT = $(DBDIR)/doreduction.sh

tptp_export: $(TPTPEXP) rlcfiles $(workingtptp)
	@echo "TPTP export done"

$(MOMMTYPES): $(workingtptp)
	rm -r -f $(MOMMTYPES)
#	@if test ! -d $(REDTMPDIR); then mkdir $(REDTMPDIR); fi; 
	@for i in $(workingtyp); do cat $$i >> $(MOMMTYPES); done
	@echo "$(MOMMTYPES) created"

# create all.cb and all.tb for fast loading

all.cb: $(MOMMTYPES)
	time $(MOMM) -s -y $(MOMMTYPES) -a -t nsaccept -w all $(workingths) >>$(REDLOG)

all_untyped.cb: tptp_export
	time $(MOMM) -s -a -t nsaccept -w all_untyped $(workingths) >>$(REDLOG)


# NOT needed for simple interreduction

$(REDSCRIPT): $(workingtptp) $(MOMMTYPES)
	rm -r -f $(REDSCRIPT)
	@echo "Creating $(REDSCRIPT), this will take some time"
	$(REDPLANNER) -s0 -p1 -b$(REDTMPDIR) -m$(REDMEMLIMIT) -t$(MOMMTYPES)  $(notdir $(mommworking)) > $(REDSCRIPT)
	@echo "$(REDSCRIPT) created"

# The simple interreduction

%.ths.cb: %.tptp
	$(MOMM) -s -f -t nsaccept -w $*.ths $*.ths >> $(REDLOG)

%.tptp.cb: %.tptp %.ths.cb
	$(MOMM) -s -f -t nbsaccept -w $*.tptp $*.tptp >> $(REDLOG)
	$(MOMM) -s -f -t nbsaccept -w $*.tptp -T $*.ths1 $*.ths.cb $*.tptp.cb >> $(REDLOG)


momm_ths_cb: tptp_export $(addsuffix .ths.cb,$(mommworking))
	@echo "THS clausebanks done"

momm_tptp_cb: tptp_export $(addsuffix .cb,$(workingtptp))
	@echo "TPTP clausebanks done"


red_simple: $(workingtptp) $(addsuffix .cb,$(workingtptp)) \
           $(addsuffix .ths.cb,$(mommworking))
	touch red_simple
	@echo "Simple iterreduction finished"

red_simple_stats: red_simple
	@rm -r -f red_simple_stats
	@echo "Collecting statistics from"
	@for i in $(mommworking); do \
	  LANG=C;\
	  echo $$i; \
	  a=`grep -c "^accept" $$i.ths`; \
	  b=`grep -c "^nsaccept" $$i.ths.cb`; \
	  c=`grep -c "^accept" $$i.tptp`; \
	  d=`grep -c "^nbsaccept" $$i.tptp.cb`; \
	  echo  $$i  "	" $$a "	" $$b "	" $$c "	" $$d >> red_simple_stats; \
	done;
	@echo "Stats collected in red_simple_stats"

full_tptp_test: red_simple
	time $(MOMM) -s $(addsuffix .cb,$(workingtptp)) >>/dev/null


# this is hack to allow usqge of $(REDSCRIPT)
# now used for comparing versions of tptpexp too, so typs backed up too
backup_tptp: $(workingtptp)
	@for i in $(workingtptp); do mv -f $$i $$i.backup; done
	@for i in $(workingths); do mv -f $$i $$i.backup; done
	@for i in $(workingtyp); do mv -f $$i $$i.backup; done	
	@echo "tptp and ths files backed up"

fake_tptp:
	@for i in $(mommworking);do \
	  sed -e 's/nbsaccept:/accept:/' $$i.tptp.cb > $$i.tptp; \
	  sed -e 's/nsaccept:/accept:/' $$i.ths.cb > $$i.ths; \
	done

restore_tptp: 
	@for i in $(workingtptp); do mv -f $$i.backup $$i; done
	@for i in $(workingths); do mv -f $$i.backup $$i; done
	@for i in $(workingtyp); do mv -f $$i.backup $$i; done	
	@echo "tptp and ths files restored up"

momm_dist: red_simple all.cb $(MOMMTYPES)
	@if test ! -d $(BASEDIR)/MOMM; then \
	  echo "MoMM dir must exist and contain the source"; exit 1; \
	fi;
	cp -a -L all.typ $(BASEDIR)/MOMM;
	cp -a -L all.tb $(BASEDIR)/MOMM/all.ths.tb;
	cp -a -L all.cb $(BASEDIR)/MOMM/all.ths.cb;
	cd $(BASEDIR); 
	cp -a -L $(MOMM) $(RELCPREM) $(TPTPEXP) $(TPTPVER) $(BASEDIR)/MOMM; 
	@echo "Compressing ths files"
	@cd $(BASEDIR)/MOMM; \
	rm -r -f ths tptp typ;\
	mkdir  ths tptp typ; \
	cd ths; \
	for i in $(addprefix $(DBDIR)/,$(workingths)); do \
              gzip -c $$i.cb > `basename $$i`.cb.gz ; done; 
	@echo "Compressing tptp files, will take a while"
	@cd $(BASEDIR)/MOMM/tptp; \
	for i in $(addprefix $(DBDIR)/,$(workingtptp)); do \
              gzip -c $$i.cb > `basename $$i`.cb.gz ; done; 
	@cd $(BASEDIR)/MOMM; \
	for i in $(addprefix $(DBDIR)/,$(workingtyp)); do \
              cp -a -L $$i typ; done; 
	cd $(BASEDIR); \
	tar czf MOMM.tar.gz MOMM;
	@echo "MoMM distribution created"

%.aa: %.evl $(REPORTER)
	$(REPORTER) -q $* >> $(AA_LOG)

stdaa	=  $(addsuffix .aa,$(STDMIZPREF))

$(addsuffix .aa,$(NONSTDMIZPREF)): %.aa: %.evl $(REPORTER)
	-$(REPORTER) -q $* >> $(AA_LOG)

nonstdaa	= $(addsuffix .aa,$(NONSTDMIZPREF))

allaa	= $(stdaa) $(nonstdaa)

cleanaa: 
	rm -r -f [a-z]/*.aa

aa_report: links $(allaa)
	@echo "All reported"


%.pl: %.aa $(ABS2PROL)
	$(ABS2PROL)  $* >> $(PL_LOG)

stdpl	=  $(addsuffix .pl,$(STDMIZPREF))

$(addsuffix .pl,$(NONSTDMIZPREF)): %.pl: %.aa $(ABS2PROL)
	-$(ABS2PROL)  $* >> $(PL_LOG)

nonstdpl	= $(addsuffix .pl,$(NONSTDMIZPREF))

allpl	= $(stdpl) $(nonstdpl)

cleanpl: 
	rm -r -f [a-z]/*.pl

pl_report: links $(allpl)
	@echo "All prolog reports done"

# this SWI command does not set exit status if error!
PLTEST 	= 	pl -g halt -f

pl_check:  # $(allpl)
	@for f in $(allpl);do $(PLTEST) $$f; done;
	@echo "All .pl files checked ok"



# Some .dsf have size zero, so on not so old reiserfs, they will
# be rebuilt :-(. Fixing this by touching them now.
# .bys files are produced by $(FO_TOOL), we gzip them immediately.
# and move to $(BYSDIR)

%.dsf: %.evl %.rlc $(FO_TOOL)
	$(FO_TOOL) $(FO_FLAGS) $* >> $(FOLOG)
	@if test ! -s $@; then touch $@; fi
	@if test -f $*.bys; then \
	 	$(GZIP) -f $*.bys; mv -f $*.bys.gz $(BYSDIR); \
	fi


stddsf	=  $(addsuffix .dsf,$(STDMIZPREF))

# This overrides the implicit pattern for error causing files

$(addsuffix .dsf,$(NONSTDMIZPREF)): %.dsf: %.evl %.rlc $(FO_TOOL)
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
ifneq ($(strip $(ADDEDREQFILES)),)
	@for f in $(ADDEDREQFILES); do \
	  echo $(ADDEDREQENVFIX) >> environments.db; \
	done;
endif
	@for f in $(ALLMIZPREF);do \
	  perl -F $(DBENV) $$f >> environments.db; \
	  echo "Environment for $$f inserted"; \
	done; 
	@echo "Created environments.db"

MKTHPINFO	= $(ADDSCRIPT)/MPTPThProblemInfo.pl
ALLMIZREQ	= $(ADDEDREQFILES) $(ALLMIZ) 
thprobleminfo.db: counts.db runningcounts.db environments.db
	@echo "Creating thprobleminfo.db, this will take some time"
	@ cd $(ADDSCRIPT); $(MKTHPINFO) $(ALLMIZREQ); cd ..
	@echo "thprobleminfo.db created"


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
