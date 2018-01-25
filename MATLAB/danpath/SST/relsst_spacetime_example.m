%relsst_spacetime_example.m - test relsst_spacetime
%
% Other m-files required: relsst_spacetime, land_or_ocean
% Subfunctions: none
% MAT-files required: relsst_mat_allmonths.mat
%
% Author: Dan Chavas
% CEE Dept, Princeton University
% email: drchavas@gmail.com
% Website: http://www.princeton.edu/~dchavas/
% 5 Sep 2014; Last revision:
% Revision history:

%------------- BEGIN CODE --------------

clear
clc
close all

addpath(genpath('~/Dropbox/Research/MATLAB/danpath/'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% USER INPUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%relsst data
relsst_file = sprintf('~/Dropbox/Research/WxDATA/SST/DATA/HadISST_relsst.mat');

%%Point of interest
N_pts = 9;
lats_in = round(linspace(-40,40,N_pts));    %[deg N]
lons_in = 3*lats_in+100;   %[deg E]
% lats_in = 20;    %[deg N]
% lons_in = -50;   %[deg E]
years_in = round(linspace(1880,2010,N_pts));
daysofyear_in = round(linspace(10,360,N_pts));
% years_in = 1971*ones(size(lats_in));
% daysofyear_in = 227*ones(size(lats_in));
% months_in = 8*ones(size(lats_in));
% days_in = 1*ones(size(lats_in));

%%Make a plot?
make_plot = 1;  %1: makes a plot; ow: no plot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%Load relsst monthly data
listOfVariables={
        'days_since_197001010000_all',...
        'lat_relsst_mat','lon_relsst_mat','relsst_mat'
        };
load(relsst_file,listOfVariables{:})
sprintf('Loading relative SST data from %s',relsst_file)

length(lats_in)
[relsst_interp_all,isOcean_all] = data_spacetime(days_since_197001010000_all,lat_relsst_mat,lon_relsst_mat,relsst_mat,lats_in,...
            lons_in,years_in,daysofyear_in);
clear lat_mat lon_mat days_since_197001010000_all relsst_all

        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PLOTTING: Plot points, values on top of closest monthly %%
if(make_plot)
    
    %% Load relsst monthly data
    listOfVariables={
            'year_all','month_all','monthnum','days_since_197001010000_all',...
            'lat_tropicsedge','sst_tropicsmean',...
            'lat_relsst_mat','lon_relsst_mat','relsst_mat'
            };
    load(relsst_file,listOfVariables{:})
    sprintf('Loading relative SST data from %s',relsst_file)

    coastal_res = 1;    %[pts/deg]
    make_plot = 0;
    [isOcean_mat] = land_or_ocean(lat_relsst_mat,lon_relsst_mat,coastal_res,make_plot);

    for jj=1:length(relsst_interp_all)
    
        relsst_interp = relsst_interp_all(jj);
        isOcean = isOcean_all(jj);
        
        lat_in = lats_in(jj);
        lon_in = lons_in(jj);
        year_in = years_in(jj);
        day_in_year = daysofyear_in(jj);

        %% Calculate total days since 1 Jan 1970 0000UTC (Unix standard)
        year0_Unix = 1970;
        month0_Unix = 1;
        day0_Unix = 1;    %can use fractions of days
        days_since_197001010000_in = (day_in_year-1) + days_since(year_in,...
            ones(size(year_in)),ones(size(year_in)),year0_Unix,month0_Unix,day0_Unix);

        %%Extract relsst map data for desired time
        dtime = abs(days_since_197001010000_all-mode(days_since_197001010000_in));
        i_time_pl = find(dtime==min(dtime));
        i_time_pl = i_time_pl(1);
        relsst_temp = relsst_mat(:,:,i_time_pl);
        days_since_197001010000_map = days_since_197001010000_all(i_time_pl);

        relsst_temp(~isOcean_mat) = NaN;

        %%Adjust lon to [0,360) deg E
        lon_in_temp = lon_in;
        lon_in_temp(lon_in_temp<0) = lon_in_temp(lon_in_temp<0)+360;

        %%INITIAL SETUP %%%%%%%%
        hh=figure(1001);
        clf(hh)
        set(hh,'units','centimeters');
        hpos = [0 0 60 30];
        set(hh,'Position',hpos);
        set(hh,'PaperUnits','centimeters');
        set(hh,'PaperPosition',hpos);
        set(hh,'PaperSize',hpos(3:4));

        set(gca,'position',[0.08    0.07    0.86    0.91]);

    %     subplot(2,1,1)
    %     ax = worldmap('World');
    %     setm(ax, 'Origin', [0 180 0])
    %     land = shaperead('landareas', 'UseGeoCoords', true);
    %     geoshow(ax, land, 'FaceColor', [0.8 0.9 0.8])
    %     hold on
    %     contourfm(lat_mat,lon_mat,sst_temp,0:1:max(sst_temp(:)));
    %     %caxis([0 25])
    %     colorbar

        %subplot(2,1,2)
        caxis([-10 10]);  %must set this before redefining colormap!
        cvals = colormap(bluewhitered(256));   %custom color map: pos = red, neg = blue, 0 = white
        xvals = linspace(-10,10,length(cvals)); %values corresponding to color map scale
        ax = worldmap([-90 90],[-180 180]);
        setm(ax, 'Origin', [0 180 0])
        land = shaperead('landareas', 'UseGeoCoords', true);
        geoshow(ax, land, 'FaceColor', [0.8 0.9 0.8])
        hold on
        cint = 2;   %[K]
        [cpl,hpl] = contourfm(lat_relsst_mat,lon_relsst_mat,relsst_temp,-10:cint:10);
        ht = clabelm(cpl,hpl,'LabelSpacing',10^4);
        set(ht,'Color','r','BackgroundColor','white','FontWeight','bold')
        contourm(lat_relsst_mat,lon_relsst_mat,relsst_temp,[0 0],'Color','g','LineStyle','--','LineWidth',2);  %%Zero contour
        %caxis([0 25])
        colorbar
        relsst_colors = interp1(xvals,cvals,relsst_interp);
        if(isOcean==1)
            lat_pl_temp = lat_in(isOcean);
            lon_pl_temp = lon_in(isOcean);
            relsst_color_pl_temp = relsst_colors(isOcean,:);
            for ii=1:length(lat_pl_temp)
                if(sum(isnan(relsst_color_pl_temp(ii,:)))==0)
                    plotm(lat_pl_temp(ii),lon_pl_temp(ii),'Marker','o','MarkerEdgeColor','g','MarkerFaceColor',relsst_color_pl_temp(ii,:),'MarkerSize',20,'LineWidth',5)
                else
                    plotm(lat_pl_temp(ii),lon_pl_temp(ii),'Marker','o','MarkerEdgeColor','g','MarkerFaceColor','k','MarkerSize',20,'LineWidth',5)
                end
            end
        end
        if(isOcean==0)
            plotm(lat_in(~isOcean),lon_in_temp(~isOcean),'Marker','o','MarkerEdgeColor','k','MarkerFaceColor','k','MarkerSize',20,'LineWidth',5)
        end
        title(sprintf('pt: relsst = %3.1f, yr = %i, days since 1970 = %i; map: days since 1970 = %i',relsst_interp,year_in,days_since_197001010000_in,days_since_197001010000_map))

        %% Save plot
        plot_filename = sprintf('relsst_spacetime_example_%i.jpg',jj)
        saveas(gcf,plot_filename,'jpg')
        
    end
    
end
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


        
%------------- END OF CODE --------------