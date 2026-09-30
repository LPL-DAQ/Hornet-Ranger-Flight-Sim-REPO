% Hornet/Ranger Flight Simulator Initiation Script
clear; clc; close all

%%Constants
g = 9.81; % m/s^2, gravitational acceleration
m = 100; % kg, vehicle thrust
weight = m*g; % N
Tmax = 400; % N, max EDF thrust
Tmin = 0; % N, minimum EDF thrust
tau = 0.2; % s, EDF spool-up time constant
gimbal_max = deg2rad(6); % rads, maximum gimbal angle

x_hat_body = [1;0;0];
x0 = 0; % m, initial height
y0 = 0; % m, starting position
z0 = 0; % m, starting position

vx0 = 0; % m/s, initial velocity
vy0 = 0; % m/s, initial velocity
vz0 = 0; % m/s, initial velocity

Kp = 10; % N/m, altitude gain
Kd = 10; % N/(m/s), velocity (damping) gain

z_targ = 0; % m, desired altitude
y_targ = 0; % m, desired y-position
x_targ = 0; % m, desired x-position

Position_Target_inertial = [x_targ; y_targ;z_targ]; % m

I = [1 0 0
    0 1 0
    0 0 1]; % Moment of Inertia

L_EDF = 1; % m, EDF standoff from CG

F_g_I = [-weight;0;0]; % N, gravitational force in inertial frame

EDF_thrust = 100; % N, EDF thrust command

L_RCS = 0.01; % m, RCS CG standoff dist

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

