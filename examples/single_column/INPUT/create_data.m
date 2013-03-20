function [] = create_data()

name='Arabian'; x=66; y=15; doall(x,y,name)
name='BATS'; x=-63.5; y=31.5; doall(x,y,name)
name='Chagos'; x=-284; y=-6; doall(x,y,name)
name='COARE'; x=-180; y=0; doall(x,y,name)
name='Kerguelen'; x=-284; y=-51; doall(x,y,name)
name='Kuroshio'; x=-210; y=30; doall(x,y,name)
name='Labrador'; x=-58; y=61; doall(x,y,name)
name='Mariana'; x=-215; y=13; doall(x,y,name)
name='Nazca'; x=-90; y=20; doall(x,y,name)
name='Nino'; x=-119; y=0; doall(x,y,name)
name='Norwegian'; x=-7; y=75; doall(x,y,name)
name='PAPA'; x=-150; y=51; doall(x,y,name)
name='St_Peter_Rock'; x=-29; y=0; doall(x,y,name)
name='Walvis'; x=5; y=-25; doall(x,y,name)
name='Weddell'; x=-54; y=-74; doall(x,y,name)

% ==============================================================================

function [] = doall(x,y,name)

[success,msg,msgid]=mkdir(name);
create_override(x,y,name)
grab_forcing(x,y,name)
grab_forcing_m(x,y,name)
grab_initconds(x,y,name)
grab_tides(x,y,name)

% ==============================================================================

function [] = create_override(x,y,name)

disp(['Creating GOLD_override for ' name])
f=4*pi/86400*sin(y*pi/180);
fid=fopen( sprintf('%s/GOLD_override',name), 'wt' );
fprintf(fid,'! Generated by create_data.m\n');
fprintf(fid,'#override define F_0 %g\n',f);
fprintf(fid,'#override define INPUTDIR "INPUT/%s"\n',name);
fclose(fid);

% ==============================================================================

function [] = grab_forcing(x,y,name)

disp(['Creating forcing.nc for ' name])
rtpth='/archive/gold/datasets/global/omsk/INPUT/';
evap=mycdf([rtpth 'am2p10_evap_HIM_1995.nc']);
precip=mycdf([rtpth 'am2p10_precip_HIM_1995.nc']);
snow=mycdf([rtpth 'am2p10_snow_HIM_1995.nc']);
shflx=mycdf([rtpth 'am2p10_shflx_HIM_1995.nc']);
lwdn_sfc=mycdf([rtpth 'am2p10_lwdn_sfc_HIM_1995.nc']);
lwup_sfc=mycdf([rtpth 'am2p10_lwup_sfc_HIM_1995.nc']);
swdn_sfc=mycdf([rtpth 'am2p10_swdn_sfc_HIM_1995.nc']);
swup_sfc=mycdf([rtpth 'am2p10_swup_sfc_HIM_1995.nc']);
stress=mycdf([rtpth 'omip.nc']);

X=evap{'gridlon_t'}(:);
Y=evap{'gridlat_t'}(:);

i=findi(X,x);
j=round( interp1(Y,0.5:length(Y),y) );

EVAP=evap{'evap'}(:,j:j+1,i:i+1);
PRECIP=precip{'precip'}(:,j:j+1,i:i+1);
SNOW=snow{'snow'}(:,j:j+1,i:i+1);
SHFLX=shflx{'shflx'}(:,j:j+1,i:i+1);
LWDN_SFC=lwdn_sfc{'lwdn_sfc'}(:,j:j+1,i:i+1);
LWUP_SFC=lwup_sfc{'lwup_sfc'}(:,j:j+1,i:i+1);
SWDN_SFC=swdn_sfc{'swdn_sfc'}(:,j:j+1,i:i+1);
SWUP_SFC=swup_sfc{'swup_sfc'}(:,j:j+1,i:i+1);
STRESS_X=stress{'STRESS_X'}(:,j:j+1,i:i+1);
STRESS_Y=stress{'STRESS_Y'}(:,j:j+1,i:i+1);
NETLWDN_SFC=LWDN_SFC-LWUP_SFC;
NETSWDN_SFC=SWDN_SFC-SWUP_SFC;

nt=size(EVAP,1);
for n=1:nt;
  EVAP(n,:,:)=interp2(Y(j:j+1),X(i:i+1),squeeze(EVAP(n,:,:)),y,x);
  PRECIP(n,:,:)=interp2(Y(j:j+1),X(i:i+1),squeeze(PRECIP(n,:,:)),y,x);
  SNOW(n,:,:)=interp2(Y(j:j+1),X(i:i+1),squeeze(SNOW(n,:,:)),y,x);
  SHFLX(n,:,:)=interp2(Y(j:j+1),X(i:i+1),squeeze(SHFLX(n,:,:)),y,x);
  LWDN_SFC(n,:,:)=interp2(Y(j:j+1),X(i:i+1),squeeze(LWDN_SFC(n,:,:)),y,x);
  LWUP_SFC(n,:,:)=interp2(Y(j:j+1),X(i:i+1),squeeze(LWUP_SFC(n,:,:)),y,x);
  NETLWDN_SFC(n,:,:)=interp2(Y(j:j+1),X(i:i+1),squeeze(NETLWDN_SFC(n,:,:)),y,x);
  SWDN_SFC(n,:,:)=interp2(Y(j:j+1),X(i:i+1),squeeze(SWDN_SFC(n,:,:)),y,x);
  SWUP_SFC(n,:,:)=interp2(Y(j:j+1),X(i:i+1),squeeze(SWUP_SFC(n,:,:)),y,x);
  NETSWDN_SFC(n,:,:)=interp2(Y(j:j+1),X(i:i+1),squeeze(NETSWDN_SFC(n,:,:)),y,x);
  STRESS_X(n,:,:)=interp2(Y(j:j+1),X(i:i+1),squeeze(STRESS_X(n,:,:)),y,x);
  STRESS_Y(n,:,:)=interp2(Y(j:j+1),X(i:i+1),squeeze(STRESS_Y(n,:,:)),y,x);
end

% Define new netCDF file
nc=netcdf(sprintf('%s/forcing.nc',name),'clobber');
nc.filename='forcing.nc';
nc('gridlon_t') = 2;
nc('gridlat_t') = 2;
nc('TIME14') = 0;

nc{'gridlon_t'} = ncfloat('gridlon_t'); %% 360 elements.
nc{'gridlon_t'}.long_name = ncchar('gridlon_t');
nc{'gridlon_t'}.units = ncchar('degree_east');
nc{'gridlon_t'}.cartesian_axis = ncchar('X');

nc{'gridlat_t'} = ncfloat('gridlat_t'); %% 176 elements.
nc{'gridlat_t'}.long_name = ncchar('gridlat_t');
nc{'gridlat_t'}.units = ncchar('degree_north');
nc{'gridlat_t'}.cartesian_axis = ncchar('Y');

nc{'TIME14'} = ncdouble('TIME14'); %% 365 elements.
nc{'TIME14'}.units = ncchar('days since 1982-01-01 00:00:00');
nc{'TIME14'}.time_origin = ncchar('01-JAN-1982 00:00:00');
nc{'TIME14'}.calendar = ncchar('JULIAN');
nc{'TIME14'}.modulo = ncchar(' ');
nc{'TIME14'}.cartesian_axis = ncchar('T');

nc{'geolon_t'} = ncdouble('gridlat_t', 'gridlon_t'); %% 63360 elements.
nc{'geolon_t'}.long_name = ncchar('geographic longitude of t-cell centers');
nc{'geolon_t'}.units = ncchar('degrees_E');

nc{'geolat_t'} = ncdouble('gridlat_t', 'gridlon_t'); %% 63360 elements.
nc{'geolat_t'}.long_name = ncchar('geographic latitude of t-cell centers');
nc{'geolat_t'}.units = ncchar('degrees_N');

nc{'evap'} = ncfloat('TIME14', 'gridlat_t', 'gridlon_t'); %% 23126400 elements.
nc{'evap'}.long_name = ncchar('Evaporation');
nc{'evap'}.units = ncchar('nounits');

nc{'precip'} = ncfloat('TIME14', 'gridlat_t', 'gridlon_t'); %% 23126400 elements.
nc{'precip'}.long_name = ncchar('Precipitation');
nc{'precip'}.units = ncchar('nounits');

nc{'snow'} = ncfloat('TIME14', 'gridlat_t', 'gridlon_t'); %% 23126400 elements.
nc{'snow'}.long_name = ncchar('Snow');
nc{'snow'}.units = ncchar('nounits');

nc{'shflx'} = ncfloat('TIME14', 'gridlat_t', 'gridlon_t'); %% 23126400 elements.
nc{'shflx'}.long_name = ncchar('Sensible heat flux');
nc{'shflx'}.units = ncchar('nounits');

nc{'lwdn_sfc'} = ncfloat('TIME14', 'gridlat_t', 'gridlon_t'); %% 23126400 elements.
nc{'lwdn_sfc'}.long_name = ncchar('Downward long wave raditation');
nc{'lwdn_sfc'}.units = ncchar('nounits');

nc{'lwup_sfc'} = ncfloat('TIME14', 'gridlat_t', 'gridlon_t'); %% 23126400 elements.
nc{'lwup_sfc'}.long_name = ncchar('Upward long wave raditation');
nc{'lwup_sfc'}.units = ncchar('nounits');

nc{'netlwdn_sfc'} = ncfloat('TIME14', 'gridlat_t', 'gridlon_t'); %% 23126400 elements.
nc{'netlwdn_sfc'}.long_name = ncchar('Net down long wave raditation');
nc{'netlwdn_sfc'}.units = ncchar('nounits');

nc{'swdn_sfc'} = ncfloat('TIME14', 'gridlat_t', 'gridlon_t'); %% 23126400 elements.
nc{'swdn_sfc'}.long_name = ncchar('Downward short wave raditation');
nc{'swdn_sfc'}.units = ncchar('nounits');

nc{'swup_sfc'} = ncfloat('TIME14', 'gridlat_t', 'gridlon_t'); %% 23126400 elements.
nc{'swup_sfc'}.long_name = ncchar('Upward short wave raditation');
nc{'swup_sfc'}.units = ncchar('nounits');

nc{'netswdn_sfc'} = ncfloat('TIME14', 'gridlat_t', 'gridlon_t'); %% 23126400 elements.
nc{'netswdn_sfc'}.long_name = ncchar('Net down long wave raditation');
nc{'netswdn_sfc'}.units = ncchar('nounits');

nc{'STRESS_X'} = ncfloat('TIME14', 'gridlat_t', 'gridlon_t'); %% 23126400 elements.
nc{'STRESS_X'}.long_name = ncchar('Eastward wind stress');
nc{'STRESS_X'}.units = ncchar('nounits');

nc{'STRESS_Y'} = ncfloat('TIME14', 'gridlat_t', 'gridlon_t'); %% 23126400 elements.
nc{'STRESS_Y'}.long_name = ncchar('Northward wind stress');
nc{'STRESS_Y'}.units = ncchar('nounits');

% Write data into netCDF file
nc{'gridlon_t'}(:)=[0.5:2]; % 1 degree grid starting at Greenwich
nc{'gridlat_t'}(:)=[0.5:2]; % 1 dgree grid starting at equator
for n=1:nt;
  nc{'TIME14'}(n)=n-0.5;
  nc{'evap'}(n,1:2,1:2)=EVAP(n,1:2,1:2);
  nc{'precip'}(n,1:2,1:2)=PRECIP(n,1:2,1:2);
  nc{'snow'}(n,1:2,1:2)=SNOW(n,1:2,1:2);
  nc{'shflx'}(n,1:2,1:2)=SHFLX(n,1:2,1:2);
  nc{'lwdn_sfc'}(n,1:2,1:2)=LWDN_SFC(n,1:2,1:2);
  nc{'lwup_sfc'}(n,1:2,1:2)=LWUP_SFC(n,1:2,1:2);
  nc{'netlwdn_sfc'}(n,1:2,1:2)=NETLWDN_SFC(n,1:2,1:2);
  nc{'swdn_sfc'}(n,1:2,1:2)=SWDN_SFC(n,1:2,1:2);
  nc{'swup_sfc'}(n,1:2,1:2)=SWUP_SFC(n,1:2,1:2);
  nc{'netswdn_sfc'}(n,1:2,1:2)=NETSWDN_SFC(n,1:2,1:2);
  nc{'STRESS_X'}(n,1:2,1:2)=STRESS_X(n,1:2,1:2);
  nc{'STRESS_Y'}(n,1:2,1:2)=STRESS_Y(n,1:2,1:2);
end

close(nc)

% ==============================================================================

function [] = grab_forcing_m(x,y,name)

disp(['Creating forcing_monthly.nc for ' name])
rtpth='/archive/gold/datasets/global/omsk/INPUT/';
evap=mycdf([rtpth 'am2p10_evap_HIM_1995.nc']);
disch=mycdf([rtpth 'am2p10_disch_HIM_1995.nc']);
sss=mycdf([rtpth 'levitus_sss_HIM.nc']);
sst=mycdf([rtpth 'levitus_temp_HIM.nc']);

X=evap{'gridlon_t'}(:);
Y=evap{'gridlat_t'}(:);

i=findi(X,x);
j=round( interp1(Y,0.5:length(Y),y) );

DISCH_W=disch{'disch_w'}(:,j:j+1,i:i+1);
DISCH_S=disch{'disch_s'}(:,j:j+1,i:i+1);
SSS=sss{'SALT'}(:,j:j+1,i:i+1);
SST=sst{'TEMP'}(:,j:j+1,i:i+1);
nt=size(DISCH_W,1);
for n=1:nt;
  DISCH_W(n,:,:)=interp2(Y(j:j+1),X(i:i+1),squeeze(DISCH_W(n,:,:)),y,x);
  DISCH_S(n,:,:)=interp2(Y(j:j+1),X(i:i+1),squeeze(DISCH_S(n,:,:)),y,x);
  SSS(n,:,:)=interp2(Y(j:j+1),X(i:i+1),squeeze(SSS(n,:,:)),y,x);
  SST(n,:,:)=interp2(Y(j:j+1),X(i:i+1),squeeze(SST(n,:,:)),y,x);
end

rtpth='/archive/gold/datasets/CM2G/perth/INPUT/';
chl_a=mycdf([rtpth 'seawifs_1998-2006_GOLD_smoothed_2X.nc']);
gust=mycdf([rtpth 'gustiness_qscat.nc']);

X=chl_a{'LON'}(:);
Y=chl_a{'LAT'}(:);

i2=findi(X,x);
j2=round( interp1(Y,0.5:length(Y),y) );

CHL_A=chl_a{'CHL_A'}(:,j2:j2+1,i2:i2+1);
GUST=gust{'gustiness'}(j2:j2+1,i2:i2+1);
nt=size(CHL_A,1);
for n=1:nt;
  CHL_A(n,:,:)=interp2(Y(j2:j2+1),X(i2:i2+1),squeeze(CHL_A(n,:,:)),y,x);
end
GUST(:,:)=interp2(Y(j2:j2+1),X(i2:i2+1),squeeze(GUST(:,:)),y,x);

% Define new netCDF file
nc=netcdf(sprintf('%s/forcing_monthly.nc',name),'clobber');
nc.filename='forcing_monthly.nc';
nc('LON') = 2;
nc('LAT') = 2;
nc('TIME') = 0;

nc{'LON'} = ncfloat('LON'); %% 360 elements.
nc{'LON'}.long_name = ncchar('LON');
nc{'LON'}.units = ncchar('degree_east');
nc{'LON'}.cartesian_axis = ncchar('X');

nc{'LAT'} = ncfloat('LAT'); %% 176 elements.
nc{'LAT'}.long_name = ncchar('LAT');
nc{'LAT'}.units = ncchar('degree_north');
nc{'LAT'}.cartesian_axis = ncchar('Y');

%nc{'TIME'} = ncdouble('TIME'); %% 365 elements.
%nc{'TIME'}.units = ncchar('days since 1982-01-01 00:00:00');
%nc{'TIME'}.time_origin = ncchar('01-JAN-1982 00:00:00');
%nc{'TIME'}.calendar = ncchar('JULIAN');

nc{'TIME'} = ncdouble('TIME'); %% 12 elements.
nc{'TIME'}.units = ncchar('months since 0001-01-01 00:00:00');
nc{'TIME'}.timaxe_origin = ncchar('01-JAN-0001 00:00:00');
nc{'TIME'}.calendar = ncchar('NOLEAP');
nc{'TIME'}.modulo = ncchar(' ');
nc{'TIME'}.axis = ncchar('T');
nc{'TIME'}.cartesian_axis = ncchar('T');


nc{'geolon_t'} = ncdouble('LAT', 'LON'); %% 63360 elements.
nc{'geolon_t'}.long_name = ncchar('geographic longitude of t-cell centers');
nc{'geolon_t'}.units = ncchar('degrees_E');

nc{'geolat_t'} = ncdouble('LAT', 'LON'); %% 63360 elements.
nc{'geolat_t'}.long_name = ncchar('geographic latitude of t-cell centers');
nc{'geolat_t'}.units = ncchar('degrees_N');

nc{'disch_w'} = ncfloat('TIME', 'LAT', 'LON'); %% 23126400 elements.
nc{'disch_w'}.long_name = ncchar('Water discharge');
nc{'disch_w'}.units = ncchar('nounits');

nc{'disch_s'} = ncfloat('TIME', 'LAT', 'LON'); %% 23126400 elements.
nc{'disch_s'}.long_name = ncchar('Snow discharge');
nc{'disch_s'}.units = ncchar('nounits');

nc{'SALT'} = ncfloat('TIME', 'LAT', 'LON'); %% 23126400 elements.
nc{'SALT'}.long_name = ncchar('Sea surface salinity');
nc{'SALT'}.units = ncchar('nounits');

nc{'TEMP'} = ncfloat('TIME', 'LAT', 'LON'); %% 23126400 elements.
nc{'TEMP'}.long_name = ncchar('Sea surface temperature');
nc{'TEMP'}.units = ncchar('nounits');

nc{'CHL'} = ncfloat('TIME', 'LAT', 'LON'); %% 23126400 elements.
nc{'CHL_A'} = ncfloat('TIME', 'LAT', 'LON'); %% 23126400 elements.
%nc{'CHL'}.long_name = ncchar('Chlorophyl');
%nc{'CHL'}.units = ncchar('nounits');

nc{'CHL'}.missing_value = ncfloat(-9.99999979021477e+33);
nc{'CHL'}.FillValue_ = ncfloat(-9.99999979021477e+33);
nc{'CHL'}.long_name = ncchar('CHL_A = monthly mean');
nc{'CHL'}.long_name_mod = ncchar('From GSFC monthly mean files');
nc{'CHL'}.units = ncchar('mg/m^3');

nc{'CHL_A'}.missing_value = ncfloat(-9.99999979021477e+33);
nc{'CHL_A'}.FillValue_ = ncfloat(-9.99999979021477e+33);
nc{'CHL_A'}.long_name = ncchar('CHL_A = monthly mean');
nc{'CHL_A'}.long_name_mod = ncchar('From GSFC monthly mean files');
nc{'CHL_A'}.units = ncchar('mg/m^3');

nc{'gustiness'} = ncfloat('LAT', 'LON'); %% 23126400 elements.
nc{'gustiness'}.long_name = ncchar('Wind gustiness');
nc{'gustiness'}.units = ncchar('nounits');


% Write data into netCDF file
nc{'LON'}(:)=[0.5:2]; % 1 degree grid starting at Greenwich
nc{'LAT'}(:)=[0.5:2]; % 1 dgree grid starting at equator
for n=1:nt;
  nc{'TIME'}(n)=n-0.5;
  nc{'disch_w'}(n,1:2,1:2)=DISCH_W(n,1:2,1:2);
  nc{'disch_s'}(n,1:2,1:2)=DISCH_S(n,1:2,1:2);
  nc{'SALT'}(n,1:2,1:2)=SSS(n,1:2,1:2);
  nc{'TEMP'}(n,1:2,1:2)=SST(n,1:2,1:2);
  nc{'CHL'}(n,1:2,1:2)=CHL_A(n,1:2,1:2);
  nc{'CHL_A'}(n,1:2,1:2)=CHL_A(n,1:2,1:2);
end
nc{'gustiness'}(1:2,1:2)=GUST(1:2,1:2);

close(nc)

% ==============================================================================

function [] = grab_initconds(x,y,name)

disp(['Creating ICs.nc for ' name])
rtpth='/archive/gold/datasets/global/omsk/INPUT/';
ics=mycdf([rtpth 'Global_HIM_IC.nc']);

X=ics{'gridlon_t'}(:);
Y=ics{'gridlat_t'}(:);

i=findi(X,x);
j=round( interp1(Y,0.5:length(Y),y) );

Layer=ics{'Layer'}(:);
PTEMP=ics{'PTEMP'}(:,j:j+1,i:i+1);
SALT=ics{'SALT'}(:,j:j+1,i:i+1);
ETA=ics{'eta'}(:,j:j+1,i:i+1);
nk=size(PTEMP,1);
for n=1:nk;
  PTEMP(n,:,:)=interp2(Y(j:j+1),X(i:i+1),squeeze(PTEMP(n,:,:)),y,x);
  SALT(n,:,:)=interp2(Y(j:j+1),X(i:i+1),squeeze(SALT(n,:,:)),y,x);
  ETA(n,:,:)=interp2(Y(j:j+1),X(i:i+1),squeeze(ETA(n,:,:)),y,x);
end
ETA(nk+1,:,:)=interp2(Y(j:j+1),X(i:i+1),squeeze(ETA(nk+1,:,:)),y,x)-5000.;

% Define new netCDF file
nc=netcdf(sprintf('%s/ICs.nc',name),'clobber');
nc.filename='ICs.nc';
nc('gridlon_t') = 2;
nc('gridlat_t') = 2;
nc('Layer') = nk;
nc('Interface') = nk+1;

nc{'gridlon_t'} = ncfloat('gridlon_t'); %% 360 elements.
nc{'gridlon_t'}.long_name = ncchar('gridlon_t');
nc{'gridlon_t'}.units = ncchar('degree_east');

nc{'gridlat_t'} = ncfloat('gridlat_t'); %% 176 elements.
nc{'gridlat_t'}.long_name = ncchar('gridlat_t');
nc{'gridlat_t'}.units = ncchar('degree_north');

nc{'Layer'} = ncfloat('Layer'); %% 48 elements.
nc{'Layer'}.long_name = ncchar('Layer potential density relative to 2000 dbar');
nc{'Layer'}.units = ncchar('kg m-3');
nc{'Layer'}.positive = ncchar('down');
nc{'Layer'}.axis = ncchar('Z');
nc{'Layer'}.edges = ncchar('Interface');
nc{'Layer'}.ref_pres = ncfloat(20000000);
nc{'Layer'}.ref_pres_units = ncchar('Pa\0');
nc{'Layer'}.cartesian_axis = ncchar('Z\0');

nc{'PTEMP'} = ncfloat('Layer', 'gridlat_t', 'gridlon_t'); %% 23126400 elements.
nc{'PTEMP'}.long_name = ncchar('Potential temperature');
nc{'PTEMP'}.units = ncchar('nounits');

nc{'SALT'} = ncfloat('Layer', 'gridlat_t', 'gridlon_t'); %% 23126400 elements.
nc{'SALT'}.long_name = ncchar('Salinity');
nc{'SALT'}.units = ncchar('nounits');

nc{'eta'} = ncfloat('Interface', 'gridlat_t', 'gridlon_t'); %% 23126400 elements.
nc{'eta'}.long_name = ncchar('Interface depth');
nc{'eta'}.units = ncchar('nounits');

% Write data into netCDF file
nc{'gridlon_t'}(:)=[0.5:2]; % 1 degree grid starting at Greenwich
nc{'gridlat_t'}(:)=[0.5:2]; % 1 dgree grid starting at equator
nc{'Layer'}(:)=Layer;
nc{'PTEMP'}(1:nk,1:2,1:2)=PTEMP(1:nk,1:2,1:2);
nc{'SALT'}(1:nk,1:2,1:2)=SALT(1:nk,1:2,1:2);
nc{'eta'}(1:nk+1,1:2,1:2)=ETA(1:nk+1,1:2,1:2);

close(nc)

% ==============================================================================

function [] = grab_tides(x,y,name)

disp(['Creating itides.nc for ' name])
rtpth='/archive/gold/datasets/CM2G/perth/INPUT/';
h2=mycdf([rtpth 'sgs_h2.nc']);
tideamp=mycdf([rtpth 'tideamp.nc']);

X=h2{'GRID_X_T'}(:);
Y=h2{'GRID_Y_T'}(:);

i=findi(X,x);
j=round( interp1(Y,0.5:length(Y),y) );

H2=h2{'h2'}(j:j+1,i:i+1);
TIDEAMP=tideamp{'tideamp'}(j:j+1,i:i+1);

% Define new netCDF file
nc=netcdf(sprintf('%s/itides.nc',name),'clobber');
nc.filename='ICs.nc';
nc('gridlon_t') = 2;
nc('gridlat_t') = 2;

nc{'gridlon_t'} = ncfloat('gridlon_t'); %% 360 elements.
nc{'gridlon_t'}.long_name = ncchar('gridlon_t');
nc{'gridlon_t'}.units = ncchar('degree_east');

nc{'gridlat_t'} = ncfloat('gridlat_t'); %% 176 elements.
nc{'gridlat_t'}.long_name = ncchar('gridlat_t');
nc{'gridlat_t'}.units = ncchar('degree_north');

nc{'h2'} = ncfloat('gridlat_t', 'gridlon_t'); %% 23126400 elements.
nc{'h2'}.long_name = ncchar('SGS bottom topography');
nc{'h2'}.units = ncchar('nounits');

nc{'tideamp'} = ncfloat('gridlat_t', 'gridlon_t'); %% 23126400 elements.
nc{'tideamp'}.long_name = ncchar('Tidal amplitude');
nc{'tideamp'}.units = ncchar('nounits');

% Write data into netCDF file
nc{'gridlon_t'}(:)=[0.5:2]; % 1 degree grid starting at Greenwich
nc{'gridlat_t'}(:)=[0.5:2]; % 1 dgree grid starting at equator
nc{'h2'}(1:2,1:2)=H2(1:2,1:2);
nc{'tideamp'}(1:2,1:2)=TIDEAMP(1:2,1:2);

close(nc)

% ==============================================================================

function [nc] = mycdf(filename)
str=['!dmget ' filename];
%disp(str)
eval(str);
nc=netcdf(filename);

function [i] = findi(X,x)
xx=x;
if xx<min(X)
  xx=xx+360;
elseif xx>max(X)
  xx=xx-360;
end
i=round( interp1(X,0.5:length(X),xx) );
