function rocketTelemetryUDP(block)
% Jack: sends telemetry as JSON over UDP to 127.0.0.1 port 50000 at 60 Hz (sim time).
% to be recieved by threejs renderer in the browser. 
% Inputs are:
% position_e [3]
% quaternion_eb [4] (w x y z)
% velocity_b [3]
% omega_b [3]
% gimbal [2] (dy dz, from TVC)
% rcs [1]

dims = [3 4 3 3 2 1];
block.NumInputPorts  = numel(dims);
block.NumOutputPorts = 0;
for k = 1:numel(dims)
    block.InputPort(k).Dimensions        = dims(k);
    block.InputPort(k).DirectFeedthrough = true;
end
block.SampleTimes = [1/60 0];
block.RegBlockMethod('Outputs', @Outputs);
end

function Outputs(block)
persistent udp
if isempty(udp), udp = udpport("datagram"); end

names = {'position_e', 'quaternion_eb', 'velocity_b', 'omega_b', 'gimbal', 'rcs'};
msg.t = block.CurrentTime;
for k = 1:numel(names)
    msg.(names{k}) = block.InputPort(k).Data;
end
write(udp, unicode2native(jsonencode(msg), 'UTF-8'), "127.0.0.1", 50000);
end
