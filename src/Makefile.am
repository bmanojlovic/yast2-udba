# Makefile.am for udba/src

yncludedir = @yncludedir@/udba

client_DATA =			\
	udba.ycp		\
	udba_auto.ycp	\
	udba_proposal.ycp

ynclude_DATA =			\
	helps.ycp		\
	wizards.ycp		\
	dialogs.ycp		\
	complex.ycp

desktop_DATA =			\
	udba.desktop

module_DATA =			\
	Udba.ycp


# create a symlink for local build, #145327
udba:
	ln -sf . $@
ycpchook = udba
builder = udba-builder
builderdir = $(libexecdir)/udba/bin
nobase_dist_builder_SCRIPTS = $(builder)
EXTRA_DIST = $(client_DATA) $(ynclude_DATA) $(module_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common
