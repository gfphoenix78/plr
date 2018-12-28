Summary:        R statistics language 
License:        GPLv2        
Name:           R
Version:        %{r_ver}
Release:        %{r_rel} 
Group:          Development/Tools
Prefix:         /temp
AutoReq:        no
AutoProv:       no
BuildArch:      %{buildarch} 
Provides:       R = %{r_ver}, /bin/sh

%description
The R module provides the R statistics language.

%install
mkdir -p %{buildroot}/temp/ext/R-%{r_ver}
cp -RL %{r_dir}/*             %{buildroot}/temp/ext/R-%{r_ver}

%post
echo "## BEGIN PLR ##" >> $GPHOME/greenplum_path.sh
echo "export R_HOME=\$GPHOME/ext/R-%{r_ver}" >> $GPHOME/greenplum_path.sh
echo "export LD_LIBRARY_PATH=\$GPHOME/ext/R-%{r_ver}/lib:\$GPHOME/ext/R-%{r_ver}/extlib:\$LD_LIBRARY_PATH" >> $GPHOME/greenplum_path.sh
echo "export PATH=\$GPHOME/ext/R-%{r_ver}/bin:\$PATH" >> $GPHOME/greenplum_path.sh
echo "## END PLR ##" >> $GPHOME/greenplum_path.sh

%postun
sed -ir "/^## BEGIN PLR ##/,/^## END PLR ##/d" $GPHOME/greenplum_path.sh

%files
/temp
