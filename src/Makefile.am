# Sources for udba

module_DATA = \
  modules/Udba.rb

client_DATA = \
  clients/udba_auto.rb \
  clients/udba.rb \
  clients/udba_proposal.rb

yncludedir = @yncludedir@/udba
ynclude_DATA = \
  include/udba/wizards.rb \
  include/udba/dialogs.rb \
  include/udba/complex.rb \
  include/udba/helps.rb

desktop_DATA = \
  desktop/udba.desktop

EXTRA_DIST = $(module_DATA) $(client_DATA) $(ynclude_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common