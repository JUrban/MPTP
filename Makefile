#------------------------------------------------------------------------
#
# File  : Makefile (top level make file for MPTP)
#
# Author: Josef Urban
#
# Top level make file. Check Makefile.vars for options.
#
# Changes
#
# <1> Tue Feb 11 21:26:44 2003
#     New
#------------------------------------------------------------------------

include ./Makefile.vars

warn: 
	@echo "Run make cleaninstall to rebuild MPTP from scratch."
	@echo "Use SCRIPTS/mkproblem.pl to work with installed system."

cleaninstall: checkvars
	@cd $(DBDIR); $(MAKE) cleaninstall; cd ..;


checkvars:
	@if test -z $(BASEDIR); then echo \
	"Set the shell variable MPTPDIR or edit Makefile.vars"; fi
	@if test -z $(MIZFILES); then echo \
	"MIZFILES not set, check your Mizar installation"; fi
	@if test -r $(MMLLAR); then echo \
	"Need to set the MMLLAR variable in Makefile.vars"; fi




cleandist: 
	cd $(BASEDIR)
	rm -r -f MPTP
	rm -r -f MPTP.tar.gz


basefiles = Makefile.vars Makefile MPTPFAQ.txt MPTPInstall.txt README_MPTP.txt

basicdist: cleandist
	@mkdir MPTP; cd MPTP; \
	for i in $(basefiles); do cp -a -L $(BASEDIR)/$$i .; done; \
	mkdir DB PROBLEMS; \
	cp -a -L $(ADDBIN) .; cp -a -L $(ADDSCRIPT) .; \
	cd DB; mkdir BYS TMPDB; \
	cp -a -L $(REQDIR) .; cp -a -L $(DBDIR)/Makefile .; \
	cd $(BASEDIR);
	tar czf MPTP.tar.gz MPTP
	@echo "Basic distribution created"

dbdist: basicdist
	@rm -r -f MPTP.tar.gz; \
	cd MPTP/DB; \
	rm -r -f BYS; \
	cp -a -L $(BYSDIR) .; \
	for i in $(ALLDBS); do cp -a -L $(DBDIR)/$$i .; done; \
	cd $(BASEDIR);
	tar czf MPTP.tar.gz MPTP
	@echo "Complete distribution created"
