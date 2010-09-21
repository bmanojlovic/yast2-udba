#
# Makefile.am for udba/scripts
#

sbin_SCRIPTS =	udba 
udbabindir = $(prefix)/lib/udba/bin
udbafakebindir = $(prefix)/lib/udba/fakebin

dist_udbabin_SCRIPTS = udba-builder udba-fetcher
dist_udbafakebin_SCRIPTS = curl wget aria2c

EXTRA_DIST = $(sbin_SCRIPTS) $(dist_udbabin_SCRIPTS) $(dist_udbafakebin_SCRIPTS)
