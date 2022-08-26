# 
# Do NOT Edit the Auto-generated Part!
# Generated by: spectacle version 0.32
# 

Name:       harbour-moremahjong

# >> macros
# << macros

Summary:    Not so Simple Mahjong
Version:    1.6.1
Release:    1
Group:      Qt/Qt
License:    MIT
URL:        https://github.com/poetaster/harbour-moremahjong
BuildArch:  noarch
Source0:    %{name}-%{version}.tar.bz2
Requires:   libsailfishapp-launcher

BuildRequires:  pkgconfig(sailfishapp) >= 1.0.2
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  pkgconfig(qt5embedwidget)
BuildRequires:  desktop-file-utils

%description
a not so simple mahjong tile solitaire originating at: https://github.com/ffalt/mah/

%if "%{?vendor}" == "chum"
PackageName: Mah Solitaire
Type: desktop-application
Categories:
 - Game
PackagerName: Mark Washeim (poetaster)
Custom:
 - Repo: https://github.com/poetaster/harbour-moremahjong
Icon: https://raw.githubusercontent.com/poetaster/harbour-moremahjong/master/icons/172x172/harbour-moremahjong.png
Screenshots:
 - https://raw.githubusercontent.com/poetaster/harbour-moremahjong/main/screen-1.png
 - https://raw.githubusercontent.com/poetaster/harbour-moremahjong/main/screen-2.png
 - https://raw.githubusercontent.com/poetaster/harbour-moremahjong/main/screen-3.png
Url:
  Homepage: https://github.com/poetaster/harbour-moremahjong
  Donation: https://www.paypal.me/poetasterFOSS
%endif

%prep
%setup -q -n %{name}-%{version}

# >> setup
# << setup

%build
# >> build pre
# << build pre

%qmake5 

make %{?_smp_mflags}

# >> build post
# << build post

%install
rm -rf %{buildroot}
# >> install pre
# << install pre
%qmake5_install

# >> install post
# << install post

desktop-file-install --delete-original       \
  --dir %{buildroot}%{_datadir}/applications             \
   %{buildroot}%{_datadir}/applications/*.desktop

%files
%defattr(-,root,root,-)
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
# >> files
# << files
