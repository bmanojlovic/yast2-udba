#
# spec file for package yast2-udba
#
# Copyright (c) 2012 SUSE LINUX Products GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           yast2-udba
Version:        0.0.5
Release:        0
License:	GPL-2.0
Group:		System/YaST

BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        yast2-udba-%{version}.tar.bz2


Requires:	yast2
BuildRequires:	perl-XML-Writer update-desktop-files yast2 yast2-devtools yast2-testsuite

BuildArchitectures:	noarch

Summary:	Universal Driver Build Assistant

%description
YaST2 helper that enables you to build binary packages from
sources which are not allowed to be hosted on OBS but can be
built locally from it. Example are binary video drivers (nvidia)


%prep
%setup -n yast2-udba-%{version}

%build
%{_prefix}/bin/y2tool y2autoconf
%{_prefix}/bin/y2tool y2automake
autoreconf --force --install

export CFLAGS="$RPM_OPT_FLAGS -DNDEBUG"
export CXXFLAGS="$RPM_OPT_FLAGS -DNDEBUG"

./configure --libdir=%{_libdir} --prefix=%{_prefix} --mandir=%{_mandir}
# V=1: verbose build in case we used AM_SILENT_RULES(yes)
# so that RPM_OPT_FLAGS check works
make %{?jobs:-j%jobs} V=1

%install
make install DESTDIR="$RPM_BUILD_ROOT"
[ -e "%{_prefix}/share/YaST2/data/devtools/NO_MAKE_CHECK" ] || Y2DIR="$RPM_BUILD_ROOT/usr/share/YaST2" make check DESTDIR="$RPM_BUILD_ROOT"
for f in `find $RPM_BUILD_ROOT/%{_prefix}/share/applications/YaST2/ -name "*.desktop"` ; do
    d=${f##*/}
    %suse_update_desktop_file -d ycc_${d%.desktop} ${d%.desktop}
done


%clean
rm -rf "$RPM_BUILD_ROOT"

%files
%defattr(-,root,root)
%dir /usr/share/YaST2/include/udba
/usr/share/YaST2/include/udba/*
/usr/share/YaST2/clients/udba.rb
/usr/share/YaST2/clients/udba_*.rb
/usr/share/YaST2/modules/Udba.*
/usr/sbin/udba
%dir /usr/lib/udba
%dir /usr/lib/udba/bin
%dir /usr/lib/udba/fakebin/
/usr/lib/udba/bin/udba-builder
/usr/lib/udba/bin/udba-fetcher
/usr/lib/udba/fakebin/aria2c  
/usr/lib/udba/fakebin/curl  
/usr/lib/udba/fakebin/wget
%{_prefix}/share/applications/YaST2/udba.desktop
%doc %{_prefix}/share/doc/packages/yast2-udba
