%data_spacetime.m - return data at points in space/time; land = NaN
%Purpose: Linear interp of monthly data in space and and time
%
% Syntax options:
%     [data_interp,isOcean_all] = data_spacetime(days_since_197001010000_all,lat_mat,lon_mat,data_all,lats_in,...
%            lons_in,years_in,daysofyear_in);
%
% Inputs:
%   days_since_197001010000_all [day] - days since 1970-01-01-0000
%   lat_mat [deg N] - latitude of grid
%   lon_mat [deg E] - longitude of grid
%   data_all [-] - grid of data
%   lats_in [deg N] - latitudes of input points
%   lons_in [deg E] - longitudes of input points
%   dayssince1970_or_yearsin - days since 1970, or years
%   daysinyear_or_months_in - day of year, or month
%   days_in - day
%   hrs_in - hour (optional; 0 = default)
%   mins_in - minute (optional; 0 = default)
%   secs_in - second (optional; 0 = default)
%
% Outputs:
%   data_interp [-] - data values at input spacetime points;
%   isOcean [0/1] - 1 if ocean, 0 if not for input lat/lon ponits
%
% Example: see data_spacetime_example.m
%   
%
% Other m-files required: land_or_ocean, days_since, 
% Subfunctions: none
% MAT-files required: data_all.mat
%
% Author: Dan Chavas
% CEE Dept, Princeton University
% email: drchavas@gmail.com
% Website: http://www.princeton.edu/~dchavas/
% 1 Jul 2015; Last revision:
% Revision history:

%------------- BEGIN CODE --------------

function [data_interp,isOcean] = data_spacetime(days_since_197001010000_all,lat_mat,lon_mat,data_all,lats_in,lons_in,dayssince1970_or_yearsin,daysinyear_or_months_in,days_in,hrs_in,mins_in,secs_in)

    year0_Unix = 1970;
    month0_Unix = 1;
    day0_Unix = 1;    %can use fractions of days

    if(nargin==7)   %days_since_197001010000 is assumed to be input
    
        dayss_since_197001010000_in = dayssince1970_or_yearsin;
        
    elseif(nargin==8)   %day of year is assumed to be input
        
        years_in = dayssince1970_or_yearsin;
        days_in_year = daysinyear_or_months_in;
        
        %% Calculate total days since 1 Jan 1970 0000UTC (Unix standard)
        dayss_since_197001010000_in = (days_in_year-1) + days_since(years_in,...
            ones(size(years_in)),ones(size(years_in)),year0_Unix,month0_Unix,day0_Unix);
        
    elseif(nargin>8)    %figure out day of year from date
        
        years_in = dayssince1970_or_yearsin;
        months_in = daysinyear_or_months_in;
        
        if(nargin == 9) %month and day given
            hrs_in = zeros(size(lats_in));
            mins_in = zeros(size(lats_in));
            secs_in = zeros(size(lats_in));
        elseif(nargin == 10) %month and day and hour
            mins_in = zeros(size(lats_in));
            secs_in = zeros(size(lats_in));
        elseif(nargin == 11) %month and day and hour and min
            secs_in = zeros(size(lats_in));
        end
        
        %% Calculate total days since 1 Jan 1970 0000UTC (Unix standard)
        day_hrmin_temp = days_in + hrs_in/24 + ...
            mins_in/(60*24) + secs_in/(60*60*24); %day+fraction
        dayss_since_197001010000_in = days_since(years_in,...
            months_in,day_hrmin_temp,year0_Unix,month0_Unix,day0_Unix);
        
    else
        assert(1==2,'not enough input arguments')
    end
    
    %% Adjust longitude to [0,360) deg E
    lons_in_temp = lons_in;
    lons_in_temp(lons_in_temp<0) = lons_in_temp(lons_in_temp<0)+360;
    
    %% Convert longitude to [0,360)
    lon_mat(lon_mat<0) = lon_mat(lon_mat<0) + 360;
    
    %% Make lat = rows, lon = cols
    lat_mat = lat_mat';
    lon_mat = lon_mat';
    data_all = permute(data_all,[2 1 3]);
    
    %% Vectors for lat/lon
    lat_vec_temp = lat_mat(:,1);
    lon_vec_temp = lon_mat(1,:);
    
    %% Extract max dlat, dlon, dt
    dlat = abs(max((lat_vec_temp(2:end)-lat_vec_temp(1:end-1))));
    dlon = abs(max((lon_vec_temp(2:end)-lon_vec_temp(1:end-1))));
    dt = abs(max((days_since_197001010000_all(2:end)-days_since_197001010000_all(1:end-1))));

    %% Make same-sized matrices out of lat,lon,time data too
    size_temp = size(data_all);    %size of complete data matrix
    temp(1,1,:) = days_since_197001010000_all;
    time_mat = repmat(temp,[size_temp(1:2) 1]);
    assert(sum(size(time_mat)==size_temp)==3,'matrix size error')
    clear temp
    lat_mat = repmat(lat_mat,[1 1 size_temp(3)]);
    lon_mat = repmat(lon_mat,[1 1 size_temp(3)]);

    %%OPTION 1 : SPACETIME INTERPOLATION -- loop through values, as
    %%vectorized approach may require tons of the data
    data_interp = NaN(size(lats_in));
    isOcean = NaN(size(lats_in));
    for jj=1:length(lats_in)

        jj
        
        lat_in = lats_in(jj);
        lon_in_temp = lons_in_temp(jj);
        days_since_197001010000_in = dayss_since_197001010000_in(jj);
        
        %%Subset data data to minimal size lat/lon/time range for speed        
        i_good_time = find(days_since_197001010000_all>=min(days_since_197001010000_in)-dt & ...
            days_since_197001010000_all<=max(days_since_197001010000_in)+dt);
        i_good_lat = find(lat_vec_temp>=min(lat_in)-dlat & ...
            lat_vec_temp<=max(lat_in)+dlat);
        i_good_lon = find(lon_vec_temp>=min(lon_in_temp)-dlon & ...
            lon_vec_temp<=max(lon_in_temp)+dlon);

        assert(length(i_good_time)>1,'cannot interpolate, not enough data')
        assert(length(i_good_lat)>1,'cannot interpolate, not enough data')
        assert(length(i_good_lon)>1,'cannot interpolate, not enough data')

        lat_subset = lat_mat(i_good_lat,i_good_lon,i_good_time);
        lon_subset = lon_mat(i_good_lat,i_good_lon,i_good_time);
        time_subset = time_mat(i_good_lat,i_good_lon,i_good_time);
        data_subset = data_all(i_good_lat,i_good_lon,i_good_time);

        data_interp(jj) = griddata(lat_subset,lon_subset,time_subset,data_subset,lat_in,lon_in_temp,days_since_197001010000_in);    %linear interp is default

        %% Apply land mask
        coastal_res = 1;    %[pts/deg]
        make_plot = 0;
        [isOcean_temp] = land_or_ocean(lat_in,lon_in_temp,coastal_res,make_plot);
        if(~isOcean_temp)
            data_interp(jj) = NaN;
        end
        isOcean(jj) = isOcean_temp;


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% TESTING: PLOT relative SST %%%%
        %{
        %%Default options -- as desired
        set(0,'defaultaxesfontsize',18,'defaultaxesfontweight','normal',...
            'defaultlinelinewidth',2,'DefaultAxesFontName','Helvetica')

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
        cint = 1;   %[K]
        %data_temp = squeeze(interp1(days_since_197001010000_all,permute(data_all,[3 1 2]),days_since_197001010000_in(1)));
        i_time_pl = find(days_since_197001010000_all==mode(time_subset(:)));
        data_temp = data_all(:,:,i_time_pl);
        [cpl,hpl] = contourfm(lat_mat,lon_mat,data_temp,-10:cint:10);
        ht = clabelm(cpl,hpl,'LabelSpacing',10^4);
        set(ht,'Color','r','BackgroundColor','white','FontWeight','bold')
        contourm(lat_mat,lon_mat,data_temp,[0 0],'Color','g','LineStyle','--','LineWidth',2);  %%Zero contour
        %caxis([0 25])
        colorbar
        data_colors = interp1(xvals,cvals,data_interp);
        if(~isempty(lat_in(isOcean)))
            lat_pl_temp = lat_in(isOcean);
            lon_pl_temp = lon_in_temp(isOcean);
            data_color_pl_temp = data_colors(isOcean,:);
            for ii=1:length(lat_pl_temp)
                if(sum(isnan(data_color_pl_temp(ii,:)))==0)
                    plotm(lat_pl_temp(ii),lon_pl_temp(ii),'Marker','o','MarkerEdgeColor','g','MarkerFaceColor',data_color_pl_temp(ii,:),'MarkerSize',20)
                else
                    plotm(lat_pl_temp(ii),lon_pl_temp(ii),'Marker','o','MarkerEdgeColor','g','MarkerFaceColor','k','MarkerSize',20)
                end
            end
        end
        if(~isempty(lat_in(~isOcean)))
            plotm(lat_in(~isOcean),lon_in_temp(~isOcean),'Marker','o','MarkerEdgeColor','k','MarkerFaceColor','k','MarkerSize',20)
        end
        title(sprintf('data = %3.1f',data_interp))

        %}
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% TESTING: Plot points, values on top of closest monthly %%
        %{
        figure(1001)
        clf(1001)
        i_time = find(days_since_197001010000_all==mode(time_subset(:)))
        pcolor(lon_mat(:,:,1),lat_mat(:,:,1),data_all(:,:,i_time))
        hold on
        plot(lon_in_temp(isOcean),lat_in(isOcean),'Marker','x','MarkerEdgeColor','m','MarkerSize',20)
        plot(lon_in_temp(~isOcean),lat_in(~isOcean),'Marker','o','MarkerEdgeColor','w','MarkerSize',20)
        colorbar
        title(sprintf('data = %3.1f',data_interp))
        'hi'

        %}
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %}

        %%OPTION 2: SPACE INTERPOLATION ONLY -- use most common month
        %{
        data_all_monthtemp = data_all(:,:,mode(months_in));
        tic
        data_monthly = griddata(lat_mat,lon_mat,data_all_monthtemp,lat_in,QS_lon_mat);
        toc

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% TESTING: Plot points, values on top of monthly %%

        figure(1002)
        clf(1002)
        pcolor(lon_mat,lat_mat,data_all_monthtemp)
        hold on
        plot(QS_lon_mat,lat_in,'Marker','x','MarkerEdgeColor','m','MarkerSize',20)
        colorbar
        title(sprintf('V_p = %3.1f',data_monthly))
        'hi'

        %}
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %}

    end
        
assert(length(data_interp)==length(lats_in),'Output data  not same length as input data!')

end
%------------- END OF CODE --------------