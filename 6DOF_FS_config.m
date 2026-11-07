% Hornet/Ranger Flight Simulator Initiation Script
clear; clc; close all

%% Constants and Starting Conditions
g = 9.81; % m/s^2, gravitational acceleration

z_targ = 0; % m, desired altitude
y_targ = 0; % m, desired y-position
x_targ = 0; % m, desired x-position

x0 = 0; % m, initial height
y0 = 0; % m, starting position
z0 = 0; % m, starting position

roll0  = 0.0; % rad, initial roll
pitch0 = 0.0; % rad, initial pitch
yaw0   = 0.0; % rad, initial yaw

vx0 = 0; % m/s, initial velocity
vy0 = 0; % m/s, initial velocity
vz0 = 0; % m/s, initial velocity

Position_Target_inertial = [x_targ; y_targ;z_targ]; % m

Kp = 10; % N/m, altitude gain
Kd = 10; % N/(m/s), velocity (damping) gain

x_hat_body = [1;0;0];

% position of vehicle foot pads in body frame  TODO: check with cad these
% are guessed by jack
feet_pos_body_m = [ -1.87  -1.87  -1.87  -1.87 ;
                    1.0   0.0  -1.0   0.0 ;
                    0.0   1.0   0.0  -1.0 ];

%% RANGER Geometry and Mass Properties
% Mass properties
params_ranger.m = 250.7891; % kg, vehicle mass
params_ranger.weight = 2459.4007; % N
params_ranger.I = [126.9426 0 0
    0 127.0886 0
    0 0 22.8931]; % Moment of Inertia
params_ranger.F_g_i = [-params_ranger.weight;0;0]; % N, gravitational force in inertial frame
% Primary Engine
params_ranger.Tmax = 400; % N, max engine thrust
params_ranger.Tmin = 0; % N, minimum engine thrust
params_ranger.spool = 0.2; % s, engine time constant
params_ranger.gimbal_max = deg2rad(8); % rads, maximum gimbal angle
params_ranger.L_engine = 1; % m, engine standoff from CG
params_ranger.thrust = 100; % N, thrust command
% RCS
params_ranger.L_RCS = 0.01; % m, RCS CG standoff dist


%% HORNET Geometry and Mass Properties
% Mass properties
params_hornet.mass = 100; % kg, vehicle mass
params_hornet.weight = params_hornet.mass * g; % N
params_hornet.I = [1 0 0
    0 1 0
    0 0 1]; % Moment of Inertia
params_hornet.F_g_i = [-params_hornet.weight;0;0]; % N, gravitational force in inertial frame
% Primary Engine
params_hornet.Tmax = 400; % N, max EDF thrust
params_hornet.Tmin = 0; % N, minimum EDF thrust
params_hornet.spool = 0.2; % s, EDF spool-up time constant
params_hornet.gimbal_max = deg2rad(8); % rads, maximum gimbal angle
params_hornet.L_engine = 1; % m, EDF standoff from CG
params_hornet.thrust = 100; % N, EDF thrust command
% RCS
params_hornet.L_RCS = 0.01; % m, RCS CG standoff dist

%% Sensors
% Lidar Structs (Benewake TF-02 Pro)
Lidar_1.Xb = [-0.1,0.1,0.1]; % [m,m,m], Position of lidar 1 in body frame
Lidar_2.Xb = [-0.1,-0.1,0.1]; % [m,m,m], Position of lidar 2 in body frame
Lidar_1.pointing_b = Lidar_1.Xb/(norm(Lidar_1.Xb)); % unit vector in body frame
Lidar_2.pointing_b = Lidar_2.Xb/(norm(Lidar_2.Xb)); % unit vector in body frame
Lidar_1.max_range = 40; % m, maximum lidar range
Lidar_2.max_range = 40; % m, maximum lidar range
Lidar_1.sigma = 0.02; % m, standard deviation of lidar data (for 0.1 to 34 m)
Lidar_2.sigma = 0.02; % m, standard deviation of lidar data
Lidar_1.sample_rate = 100; % Hz, sample rate of Lidar (default)
Lidar_2.sample_rate = 100; % Hz, sample rate of Lidar

% IMU/GNSS Struct (VectorNav VN-300)
VN300Config.sigma_pos = [1;1;1.5];% RMS, steady-state standard deviation of position
VN300Config.sigma_vel = 0.5;% m/s, steady-state standard deviation of velocity
VN300Config.sigma_att = [deg2rad(0.03);deg2rad(0.03);deg2rad(0.2)];% rad, stead-state standard deviation of attitude
VN300Config.nav_imu_sample_rate = 400;% Hz, VN300 Navigation and IMU data rates
VN300Config.gnss_solution_rate = 5;% Hz, GNSS solution update rate
VN300Config.latency = NaN; % s, Can't find Latency data
VN300Config.tau_pos = 10; % s, time correlation constant for time-correlated error (have to tune it)
VN300Config.tau_vel = 10; % s, time correlation constant for time-correlated error (have to tune it)
VN300Config.tau_att = 10; % s, time correlation constant for time-correlated error (have to tune it)
VN300Config.mounting_pos_b = [0,0,0];% [m,m,m], mounted position in body frame
VN300Config.gnss_available = true; % Error grows is GNSS is off
VN300Config.enable_correlated_errors = true; % Simplified model if false

%% PID Gains
% Inertial Position Gains
PIDX_KP_pos = 0.0;
PIDX_KI_pos = 0.0;
PIDX_KD_pos = 0.0;

PIDY_KP_pos = 0.0;
PIDY_KI_pos = 0.0;
PIDY_KD_pos = 0.0;

PIDZ_KP_pos = 0.0;
PIDZ_KI_pos = 0.0;
PIDZ_KD_pos = 0.0;

% Velocity Gains
PIDZ_KP_vel = 0.0;
PIDZ_KI_vel = 0.0;
PIDZ_KD_vel = 0.0;

% Attitude Gains
PID_KP_pitch = 0.0;
PID_KI_pitch = 0.0;
PID_KD_pitch = 0.0;

PID_KP_yaw = 0.0;
PID_KI_yaw = 0.0;
PID_KD_yaw = 0.0;

PID_KP_roll = 0.0;
PID_KI_roll = 0.0;
PID_KD_roll = 0.0;

fprintf("Initialized!")

%% Choose Vehicle
VEHICLE = 1;                       % 1 = Ranger, 2 = Hornet

switch VEHICLE
    case 1, veh = params_ranger();
    case 2, veh = params_hornet();
end