#
# Makefile.am for .../testsuite
#
# Do not edit this file (Makefile.am) as it will be overwritten!
#

AUTOMAKE_OPTIONS = dejagnu
EXTRA_DIST = $(wildcard tests/*.out) $(wildcard tests/*.err) $(wildcard tests/*.ycp) $(wildcard tests/*.yh) $(wildcard tests/*.rb)

testsuite_prepare = @ydatadir@/testsuite/Makefile.testsuite

all-local: $(testsuite_prepare)
	make -f $(testsuite_prepare) RPMNAME=$(RPMNAME) srcdir=$(srcdir)

clean-local: $(testsuite_prepare)
	make -f $(testsuite_prepare) RPMNAME=$(RPMNAME) srcdir=$(srcdir) clean

check-local: $(testsuite_prepare)
	make -f $(testsuite_prepare) RPMNAME=$(RPMNAME) srcdir=$(srcdir) check

# EOF
