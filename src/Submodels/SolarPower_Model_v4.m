function [DataSolar, DataClouds] = SolarPower_Model_v4(Time, clouddata, lambda, phi, Tlk, rho, beta, alpha,z, kWp_panel, eta_inverter, eta_heat, no_rng)

n       = length(Time);
t0      = Time(1);
tn      = Time(end);
dt      = seconds(Time(2)-Time(1));  % s/tstep
dt_sim  = 900; % s/tstep of cloud sim

TimeOut = Time;
if dt>dt_sim
    Time = (t0:seconds(dt_sim):tn+seconds(dt_sim))';
end

warning off MATLAB:structOnObject
fieldIDs = [5,8,14,19,20,21,23,24];
this = struct(Time);
[Y,Month,DoY,H,m,s,tz_offset,dst_offset] = matlab.internal.datetime.getDateFields(this.data,fieldIDs,this.tz);
DayID = Y*365+DoY;
[~,DayInd,~] = unique(DayID);


% 2 Cloud model
% 2.1 Cloudy/Overcast days (meteoblue)

if no_rng==true
    rng(92087398)
end

Prob = rand(length(DayInd),1);
OvercastProb = cloudfun_month(Month(DayInd), 3, clouddata); % Chances of being overcast day
CloudyProb = cloudfun_month(Month(DayInd), 2, clouddata); % Chances of being cloudy day

nreps = [DayInd(2:end); length(DayID)+1] - DayInd;

OvercastDay = repelem(1*(Prob<OvercastProb),nreps);
CloudyDay   = repelem(1*((Prob<(CloudyProb+OvercastProb)).*(Prob>OvercastProb)),nreps);
ClearDay    = repelem(1*(Prob >(CloudyProb+OvercastProb)),nreps);

DataClouds = timetable(Time, OvercastDay,CloudyDay,ClearDay);

% Define borders between clear, cloudy, and overcast.
Okta1 = 0.2; % clear
Okta2 = 0.8; % partially cloudy
Okta3 = 1; % overcast

LogParams = cloudfit(Okta1,Okta2,Okta3); %Fit probability function
Pfun = @(Noise,DayType) LogParams(1)./(1+exp(-LogParams(2).*(Noise+DayType-LogParams(3))));

% 2.2 Percentage of day overcast/cloudy

DataClouds.Noise = rand(length(DayID),1); 

DataClouds.CloudProb = DataClouds.OvercastDay.*Pfun(DataClouds.Noise,2)+...
                       DataClouds.CloudyDay.*Pfun(DataClouds.Noise,1)+...
                       DataClouds.ClearDay.*Pfun(DataClouds.Noise,0);
DataClouds.CloudProb = smoothdata(DataClouds.CloudProb,'gaussian',3*24*3600/dt);  % 3-day smoothing to roll in bad weather
DataClouds.Cloud = (DataClouds.CloudProb>DataClouds.Noise); % Spawn in clouds

% 1. Solar irradiation model

%https://www.sciencedirect.com/science/article/pii/B9780128099216000161#bib34
% 1.1 Day angle
J = 360/365.25*DoY; % Day angle, degrees

% 1.2 Equation of time
EoT = -0.128*sind(J-2.8)-0.165*sind(2*J+19.7); % Equation of Time, hours
LMT = H + m/60+s/3600; % Local Mean Time, hours
lambda_R = 15*(tz_offset+dst_offset)/3600; % Standard meridian for the local time zone, degrees
LAT = LMT + (lambda-lambda_R)/15 + EoT; % Local Apparent Time, hours
LAT(LAT<0) = LAT(LAT<0)+24;

% 1.3 Declination
delta = asind(0.3978*sind(J-80.2141+2.034*sind(J-2.8018))); % Declination angle, degrees

% 1.4 Hour angles
omega1 = 15*(LAT-12); % Hour angle, degrees
omega2 = 15*(LAT-12 + dt/3600); % tstep hours shift
omega2(omega2>180) = omega2(omega2>180)-360;
omega2(omega2<-180) = omega2(omega2<-180)+360;

diff = omega2-omega1;
diff(diff<0) = diff(diff<0)+360;

% Integrated form of the solar altitude angle
sin_gamma_s_int = sind(phi).*sind(delta).*(diff*pi()/180)+...
    cosd(phi).*cosd(delta).*(sind(omega2)-sind(omega1)); 
% Interval start solar altitude angle
sin_gamma_s = sind(phi).*sind(delta)+cosd(phi).*cosd(delta).*...
    cosd(omega1); 
gamma_s = asind(sin_gamma_s);
gamma_s_true = gamma_s+0.061359*(180/pi()).*(0.1594+1.1230*(pi()/180)*gamma_s+0.065656*(pi()/180)^2*gamma_s.^2)./(1+28.9344*(pi()/180)*gamma_s+277.3971*(pi()/180)^2.*gamma_s.^2);
gamma_s_true(gamma_s_true<0) = 0;
gamma_s_noon = repelem(arrayfun(@(x) max(gamma_s(DayInd(x)+ (0:nreps(x)-1))),1:length(DayInd)),nreps);

cos_alpha_s = (sind(phi).*sin_gamma_s-sind(delta))./(cosd(phi).*cosd(gamma_s));
sin_alpha_s = cosd(delta).*sind(omega1)./cosd(gamma_s);

alpha_s = cos_alpha_s;
    alpha_s(sin_alpha_s<0) = -acosd(cos_alpha_s(sin_alpha_s<0));
    alpha_s(sin_alpha_s>0) = acosd(cos_alpha_s(sin_alpha_s>0));

omegas = acosd(-tand(phi)*tand(delta));

alpha_f = alpha_s - alpha;
    alpha_f(alpha_f>180) = alpha_f(alpha_f>180)-360;
    alpha_f(alpha_f<-180) = alpha_f(alpha_f<-180)+360;

nu = acosd(cosd(gamma_s).*cosd(alpha_f).*sind(beta)+sin_gamma_s.*cosd(beta));
nu(nu<0) = 0;

% 1.5 Earth-Sun distance correction
epsi = 1 + 0.03344*cosd(J-2.800);

% 1.6 Extraterrestrial radiation (W/m²)
I0 = 1367; % W/m², solar constant
G0 = I0.*epsi.*86400/(2*pi()).*sin_gamma_s_int/3600;
G0(G0<0) = 0;

%https://www.researchgate.net/publication/222523393_On_the_clear_sky_model_of_the_ESRA_-_European_Solar_Radiation_Atlas_-_With_respect_to_the_Heliosat_method/link/5b609c17a6fdccf0b204adec/download
pp0 = exp(-z/8434.5); % p/p0

m = pp0./(sind(gamma_s_true)+0.50572*(gamma_s_true+6.07995).^(-1.6364));

delta_R = m;
delta_R(m<=20) = 1./(6.62960+1.75130*m(m<=20)-0.12020*(m(m<=20)).^2+0.00650*(m(m<=20)).^3-0.00013*(m(m<=20)).^4);
delta_R(m>20) = 1./(10.4+0.718*m(m>20));

T_rb = exp(-0.8662*Tlk*pp0*delta_R);
T_rd = -1.5843e-2+3.0543e-2*Tlk+3.797e-4*Tlk^2;

L = zeros([3,3,4]);
L(1,:,:) = [-1.7349e-2 -5.8985e-3 6.8868e-4 0;
                    1.0258 -1.2196e-1 1.9229e-3 0;
                    -7.2178e-3 1.3086e-1 -2.8405e-3 0]; %gamma_s>30°
L(2,:,:) = [-8.2193e-3 4.5643e-4 6.7916e-5 0;
                    8.9233e-1 -1.9991e-1 9.9741e-3 0;
                    2.5428e-1 2.6140e-1 -1.7020e-2 0]; %gamma_s<=30° >15°
L(3,:,:) = [-1.1656e-3 1.8408e-4 -4.8754e-7 0;
                    7.4095e-1 -2.2427e-1 1.5314e-2 0;
                    3.4959e-1 7.2313e-1 -1.2305e-1 5.9194e-3]; %gamma_s<=15°

ind = zeros([length(omega1),1])+2;
ind(gamma_s_noon<=15) = 3;
ind(gamma_s_noon>30) = 1; % determine if gamma_s <30, >15 etc. to index L

C0 = L(ind,1,1)+L(ind,1,2).*Tlk.*pp0+L(ind,1,3).*(Tlk.*pp0).^2;
C1 = L(ind,2,1)+L(ind,2,2).*Tlk.*pp0+L(ind,2,3).*(Tlk.*pp0).^2;
C2 = L(ind,3,1)+L(ind,3,2).*Tlk.*pp0+L(ind,3,3).*(Tlk.*pp0).^2+L(ind,3,4).*(Tlk*pp0).^3;

A0 = 2.6463e-1-6.158110e-2*Tlk+3.1408e-3*Tlk^2;
A1 = 2.0402+1.89451e-2*Tlk-1.116110e-2*Tlk^2;
A2 = -1.3025+3.923110e-2*Tlk+8.507910e-3*Tlk^2;
A0(A0*T_rd<2e-3) = 2e-3/T_rd;

B0 = C0+C1.*sind(phi).*sind(delta)+C2.*sind(delta).^2.*sind(phi).^2+0.5*C2.*cosd(phi).^2.*cosd(delta).^2;
B1 = C1.*cosd(phi).*cosd(delta)+2*C2.*sind(delta).*sind(phi).*cosd(phi).*cosd(delta);
B2 = 0.25*C2.*cosd(phi).^2.*cosd(delta).^2;

D0 = A0+A1.*sind(phi).*sind(delta)+A2.*sind(delta).^2.*sind(phi).^2+0.5*A2.*cosd(phi).^2.*cosd(delta).^2;
D1 = A1.*cosd(phi).*cosd(delta)+2*A2.*sind(delta).*sind(phi).*cosd(phi).*cosd(delta);
D2 = 0.25*A2.*cosd(phi).^2.*cosd(delta).^2;


B = I0.*epsi.*24./(2.*pi()).*T_rb.*(B0.*diff*pi()/180+B1.*(sind(omega2)-sind(omega1))+B2.*(sind(2*omega2)-sind(2*omega1))); %Wh/m²
B(B<0) = 0;
B(gamma_s<0) = 0;
D = I0.*epsi.*24./(2.*pi()).*T_rd.*(D0.*diff*pi()/180+D1.*(sind(omega2)-sind(omega1))+D2.*(sind(2*omega2)-sind(2*omega1)));%Wh/m²
D(D<0) = 0;
D(gamma_s<0) = 0;

G = B+D;

%https://www.sciencedirect.com/science/article/pii/0038092X80903916
Gc = G.*(1-0.75*(DataClouds.Cloud).^3.4);


% OLD CODE:
% 1.7 Ground radiation.
%kt = ones([length(DataClouds.Noise),1]);%k*(1+0.0571*(DataClouds.Noise-0.5)); % varies between 0.68 - 0.72
%G = kt.*G0; % Atmospheric transmittivity

%D = G; % init
%D(omegas<81.4 & kt<0.715) = G(omegas<81.4 & kt<0.715).*...
%        (1-0.2727*kt(omegas<81.4 & kt<0.715)+2.4495*kt(omegas<81.4 & kt<0.715).^2-11.9514*kt(omegas<81.4 & kt<0.715).^3+9.3879*kt(omegas<81.4 & kt<0.715).^4);
%D(omegas<81.4 & kt>0.715) = G(omegas<81.4 & kt>0.715).*...
%        0.143.*kt(omegas<81.4 & kt>0.715)/k;
%
%D(omegas>=81.4 & kt<0.722) = G(omegas>=81.4&kt<0.722).*...
%    (1+0.2832*kt(omegas>=81.4 & kt<0.722)-2.5557*kt(omegas>=81.4 & kt<0.722).^2+0.8448*kt(omegas>=81.4 & kt<0.722).^3);
%D(omegas>=81.4 & kt>0.722) = G(omegas>=81.4&kt>0.722).*...
%    0.175.*kt(omegas>=81.4 & kt>0.722)/k;


%B = (G-D);
%B(sin_gamma_s<=sind(5.7)) = 0; % Sun angle < 5.7 degree negligible



% 3. Clouds
% Assumption: clouds will eliminate the B-factor, but the rest will be the
% same 
% --> if DataClouds.Cloud = 1, Gc = Dc, Bc = 0. if DataClouds.Cloud = 0, Gc = B+D
% --> Bc = (1-DataClouds.Cloud)*B
% --> Dc = Gc-Bc
% c indicates taking into account clouds

Bc = max(0,(1-DataClouds.Cloud)).*B;
Dc = Gc-Bc;
Dc(Dc<=0) = 0;

% Modulating functions
Kb = (Gc-Dc)./G0;
Kb(sin_gamma_s<=sind(5.7)) = 0;

b =    1.68*DataClouds.OvercastDay +...
    (-0.62)*DataClouds.ClearDay    +...
       0.53*DataClouds.CloudyDay; % average of other 2
f_beta = cosd(beta/2).^2 + 2*b./(pi().*(3+2*b)).*...
    (sind(beta)-pi()/180*beta.*cosd(beta)-pi().*sind(beta/2).^2);

% Result on surface, p indicate panel
Bp = Bc.*cosd(nu)./sin_gamma_s;
Dp = Dc.*f_beta.*(1-Kb)+Dc.*Kb.*cosd(nu)./sin_gamma_s;
Rp = Gc.*rho.*(1-cosd(beta))/2;

Dp(sin_gamma_s<=sind(5.7)) = 0;
Bp(sin_gamma_s<=sind(5.7)) = 0;
Bp(Bp<0) = 0;
Dp(Dp<0) = 0;
Rp(Rp<0) = 0;

GT = Bp + Dp + Rp;
GT(GT<0) = 0;

DataSolar = timetable(Time, G0,G,Gc,GT,Bp,Dp,Rp, 'VariableNames',{'G0','G','Gc','G(i)','Gb(i)','Gd(i)','Gr(i)'}); % Wh/m²
if dt>dt_sim
    DataSolar = retime(DataSolar,TimeOut,"mean");
    DataClouds = retime(DataClouds,TimeOut,"mean");
end
DataSolar.E_solar = (DataSolar.('G(i)')/1000)*kWp_panel/1*eta_inverter*eta_heat;  % (kWh/m²)*kWp/(1kW/m²)*eta*eta

end