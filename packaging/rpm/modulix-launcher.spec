%global modulix_launcher_version %{?_modulix_launcher_version:%{_modulix_launcher_version}}%{!?_modulix_launcher_version:0.1.0}
%global modulix_launcher_release %{?_modulix_launcher_release:%{_modulix_launcher_release}}%{!?_modulix_launcher_release:1}

Name:           modulix-launcher
Version:        %{modulix_launcher_version}
Release:        %{modulix_launcher_release}%{?dist}
Summary:        ModuLix launcher for toolbox and nested Ansible EE runs
License:        GPL-2.0-only
URL:            https://github.com/lightning-it/modulix-launcher
Source0:        modulix-launcher-%{version}.tar.gz
BuildArch:      noarch

Requires:       bash
Requires:       podman

%description
modulix-launcher is a lightweight command-line launcher that executes ModuLix
automation workflows through a toolbox container and nested Ansible execution
environment container.

%prep
%autosetup -n modulix-launcher-%{version}

%build
# Nothing to build for script packaging.

%install
rm -rf %{buildroot}

install -d %{buildroot}%{_bindir}
install -m 0755 modulix-launcher %{buildroot}%{_bindir}/modulix-launcher

%files
%license LICENSE
%doc README.md
%{_bindir}/modulix-launcher

%changelog
* Sat Feb 28 2026 Lightning IT <opensource@l-it.io> - %{version}-%{release}
- Initial RPM packaging for modulix-launcher.

