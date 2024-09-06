%% Copyright Sejoon OH (2022.06.20) 
% This code let users to perceive how the solar time changes in the
% reference frame of airplane in long distance(command window). To ensure
% better understanding, sun's position and flight route of airplane is
% plotted at both flat map and the globe of the Earth(figure). 

% You need (1) 'interpm2.m' file by Chad Greene (download link below).
% However, matlab internal 'interpm' function can be used too.
% https://www.mathworks.com/matlabcentral/fileexchange/46923-interpm2
% You also need (2) Mapping Toolbox, (3) Climate Data Toolbox as well
clc; clearvars; close;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% INPUT SECTIONS %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Departure Airpot latitude/longitude [deg] (ex: Seoul/Incheon: 37.4602/126.4407)
dep_lat =  37.4602;                            % -90  ~ +90deg
dep_lon = 126.4407;                            % -180 ~ +180deg
% Arrival Airport latitude/longitude [deg] (ex: London Heathrow: 51.4700/-0.4543)
arr_lat =  51.4700;                            % -90  ~ +90deg
arr_lon =  -0.4543;                            % -180 ~ +180deg

% Departure time (ex: Asiana OZ 521: 2022,06,25,11,50,00)
dep_LT = datetime(2022,06,25,11,50,00);        % Local Time of departing(written in flight ticket)

% Departure Timezone (ex: Asia/Seoul: UTC +09:00)
timezone = +9;                                 % deperture timezone[h]

% Flying Time (ex: Asiana OZ 521 takes 15 hours)
flying_time = minutes(duration('15:00:00'));   % format: hh:mm:ss
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% pre-calculation section
dep_date = dep_LT;
dep_date.Format = 'dd-MMM-yyyy';
new_date = datetime(year(dep_date),01,01);      % get the first day of year of the given date 
day_of_year = days(dep_date - new_date) + 1;    % calculate the day of the year

sun_noon_LST = datetime(year(dep_date),month(dep_date),day(dep_date),12,00,00); % (constant) sun is highest at 12:00, in terms of LST

% calculate the Sun's initial latitude(declination)
sun_lat1 = 23.45*sind(360/365*(day_of_year-81)); 

% obtain Local Solar Time of departing (LST)
LSTM = 15*timezone;                             % Local Standard Time Meridian [deg]
b = 360/365*(day_of_year-81);
EoT = 9.87*sind(2*b)-7.53*cosd(b)-1.5*sind(b);  % Equation of Time [minutes]
TC = 4*(dep_lon-LSTM) + EoT;                    % Time Correction Factor [minutes]
dep_LST = dep_LT + minutes(TC);                 % Local Solar Time of departing

% calculate the Sun's initial longitude
duration_till_noon = minutes(sun_noon_LST - dep_LST);
longitude_till_noon = duration_till_noon/4;
sun_lon1 = dep_lon + longitude_till_noon;

% the Sun's longitude displacement throughout the flight
sun_lon_disp = 0.25*flying_time; % because earth rotates 0.25deg per minute

%% Construct the Flight Route
lat = [dep_lat arr_lat];
lon = [dep_lon arr_lon];

[plane_lat,plane_lon] = interpm2(lat,lon,15,'gc','kilometers',0.010); % 15.00+/-0.01km avg. spacing. This connects departure and arrival airport in the shortest line on globe. 
num_points = length(plane_lat);                                       % get the number of points that consists the flight route

% to make sure the longitude points of plane lies inside -180deg to +180deg
for k=1:num_points
    if plane_lon(k) > 180
        plane_lon(k) = plane_lon(k) - 360;
    elseif plane_lon(k) < -180
        plane_lon(k) = plane_lon(k) + 360;
    end
end

%% Construct the Sun's path
for k=1:num_points
    sun_lat(k,1) = sun_lat1;                                            % the latitude stay's the same throughout the flight(the change is minimal)
    sun_lon(k,1) = sun_lon1 - sun_lon_disp/(num_points - 1)*(k-1);      % only the longitude of the Sun moves West, 0.25deg per minutes. By this equation, it matches the speed with the plane.
end

% to make sure the longitude points of the Sun lies inside -180deg to +180deg
for k=1:num_points
    if sun_lon(k) > 180
        sun_lon(k) = sun_lon(k) - 360;
    elseif sun_lon(k) < -180
        sun_lon(k) = sun_lon(k) + 360;
    end
end

%% Calculate the Local Solar Time in perspective of Plane (the time felt in plane based on the position difference with the Sun)
for k=1:num_points
    plane_LST(k) = sun_noon_LST - minutes((sun_lon(k)-plane_lon(k))*4);
end

%% Plot on Earth flat map using Climate Data Toolbox + Print the Current Solar Time of the Plane in Command Window
subplot(1,3,[1,2])
earthimage
hold on;
borders
xlabel 'longitude [deg]'
ylabel 'latitude [deg]'
title('Flight Route and The Sun Path on Flat Map (cyan: Plane / red: Sun)');

% (option 1) plot with animation
for k=1:num_points
    plot(plane_lon(k),plane_lat(k),'LineStyle','none','Marker','*','MarkerSize',2,'Color','cyan');
    hold on;
    plot(sun_lon(k),sun_lat(k),'LineStyle','none','Marker','o','Color','red');
    pause(0.01);
    fprintf('The Solar Clock in your plane indicates %02.f:%02.f:%02.f\n',hour(plane_LST(k)),minute(plane_LST(k)),second(plane_LST(k)));
end

% (option 2) plot without animation
% plot(plane_lon,plane_lat,'LineStyle','none','Marker','*','MarkerSize',2,'Color','cyan');
% hold on;
% plot(sun_lon,sun_lat,'LineStyle','none','Marker','o','Color','red');


%% Plot on Earth 3D globe image using Climate Data Toolbox
subplot(1,3,3)
globeimage();
title('Flight Route and The Sun Path on Earth Globe');

% (option 1) plot with animation
fprintf('Now plotting in 3D Globe...Please wait\n')
for k=1:num_points
    globeplot(plane_lat(k),plane_lon(k),'LineStyle','none','Marker','*','MarkerSize',2,'Color','cyan');
    hold on;
    globeplot(sun_lat(k),sun_lon(k),'LineStyle','none','Marker','o','Color','red');
    pause(0.01);
end
fprintf('3D Globe plotting Completted! You can now rotate the Earth Globe.\n')
% (option 2) plot without animation
% globeplot(plane_lat,plane_lon,'LineStyle','none','Marker','*','MarkerSize',2,'Color','cyan');
% hold on;
% globeplot(sun_lat,sun_lon,'LineStyle','none','Marker','o','Color','red');
