% Hornet/Ranger Flight Simulator Initiation Script

g = 9.81; % m/s^2, gravitational acceleration
m = 2; % kg, vehicle thrust
Tmax = 32; % N, max EDF thrust
Tmin = 0; % N, minimum EDF thrust
tau = 0.2; % s, EDF spool-up time constant

x0 = 1; % m, initial height
% y0 = 0; % m, starting position
% z0 = 0; % m, starting position

vx0 = 0; % m/s, initial velocity
% vy0 = 0; % m/s, initial velocity
% vz0 = 0; % m/s, initial velocity

Kp = 10; % N/m, altitude gain
Kd = 10; % N/(m/s), velocity (damping) gain

m_true = m; % mass the plant 'actually' has

x_targ = 10; % m, desired altitude