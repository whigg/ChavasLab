%GWB_V_to_P_RHcnst.m -- calculate pressure field for given wind profile
% %Note: requires absolute pressure, so works with P rather than dP (i.e.
% different than GWB_V_to_P.m)
%
% Syntax:
%
% Inputs:
%
% Outputs:
%
% Example: 
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% See also:

% Author: Dan Chavas
% CEE Dept, Princeton University
% email: drchavas@gmail.com
% Website: --
% 24 Apr 2015; Last revision:

% Revisions:
%------------- BEGIN CODE --------------

function [Pmin,PP] = GWB_V_to_P(rr,VV,renv,Penv,fcor_BT,T,RH)

assert(max(rr(~isnan(VV)))>=renv,'renv lies beyond the input radial profile')

%% Calculate some things
fcor = abs(fcor_BT);

%% Define a high-res radial vector to perform the actual calculation
rr_temp = (0:1000:renv);    %[m]
VV_temp = interp1(rr,VV,rr_temp,'pchip',NaN);

%% Calculate Pmin: gradient wind balance
term1 = fcor*VV_temp;
term2 = (VV_temp.^2)./rr_temp;

const = CM1_constants;

sprintf('GWB: RH assumed constant')
[esat] = satvappres(T); %[Pa]
e = RH*esat;
rl = 0;
ri = 0;
dr = mean(rr_temp(2:end)-rr_temp(1:end-1));

%%Calculate dP/dr, iterating radially inwards towards center
dPdr = NaN(size(rr_temp));
P_temp = Penv;
for ii=length(rr_temp):-1:1
    
    %%Calculate density
    rv = const.eps*(e/(P_temp-e));   %mixing ratio[kg water / kg dry air]
    [Trho] = densitytemp(T,rv,rl,ri);
    rho = P_temp/(const.Rd*Trho);
    temp(ii) = rho;
    
    dPdr(ii) = rho*(term1(ii) + term2(ii));
    P_temp = P_temp - dPdr(ii)*dr;
    
end

Pdef = flip(cumsum(flip(dPdr*dr,2)),2);   %[Pa]; pressure deficit
Pdef(1) = Pdef(2)+(Pdef(2)-Pdef(3));    %linear extrap to r=0;
PP_temp = Penv-Pdef;
Pmin = min(PP_temp);

%% TESTING
%{
figure(999)
clf(999)
subplot(2,1,1)
plot(rr_temp/1000,VV_temp,'k')
hold on
subplot(2,1,2)
plot(rr_temp/1000,PP_temp/100,'k')
hold on
%}

%% Interpolate to user grid
PP = interp1(rr_temp,PP_temp,rr,'pchip',NaN);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TESTING:  V and P
%{
hh=figure(1);
clf(hh)
set(hh,'Units','centimeters');
hpos = [0 0 30 30];
set(hh,'Position',hpos);
set(hh,'PaperUnits','centimeters');
set(hh,'PaperPosition',hpos);
set(hh,'PaperSize',hpos(3:4));
set(gca,'position',[0.08    0.09    0.90    0.89]);

clear hpl input_legend
hnum = 0;

subplot(2,1,1)
plot(rr/1000,pp1_grid,'b')
hold on
plot(rr_p2_grid/1000,pp2_grid,'r')
xlabel('radius [km]')
ylabel('pressure [hPa]')

subplot(2,1,2)
plot(rr_v1/1000,VV1,'b')
hold on
%plot(rr_v1/1000,VV1_cycl,'b:')
plot(rr_v2/1000,VV2,'r')
%plot(rr_v2/1000,VV2_cycl,'r:')
xlabel('radius [km]')
ylabel('Wind speed [m/s]')
axis([0 250 0 70])
%}

end

%------------- END OF CODE --------------
