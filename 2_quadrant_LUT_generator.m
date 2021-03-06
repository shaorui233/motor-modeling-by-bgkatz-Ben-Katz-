%%% Uses a different motor_fun, which doesn't rely on a controller
%%% converging - super fast

format compact
clear all
%%% Generate a Percent Max Torque lookup table %%%

n = 600;  % Phase resolution
n2 = 80; % Current intervals
n3 = 200; % Velocity intervals
tdot_max = 600;
mag_max = 40;
id_max = 20;
v_max = 24/2;
tdot = linspace(0.001, tdot_max, n3)';

phase_min = -pi;
phase_max = pi;
tol = (phase_max - phase_min)/n;
%phase_max = 2*pi;

pmi = linspace(1, 0.0, n2);   %Percent Max current.  Easier to generate table this way, then interpolate torques

%v_vec = linspace(1, 40, n2);
%phase = linspace(phase_min, phase_max, n);

v_vec = zeros(n3, 1);
v_log_vec = zeros(n2, n3);
phi_max_vec = zeros(n2, n3);
mag_max_vec = zeros(n2, n3);
v_max_vec = zeros(n2, n3);
tdot_vec = zeros(n2, n3);
torque_max_vec = zeros(n2, n3);
torque_min_vec = zeros(n2, n3);
tdot_vec = zeros(n2, n3);
i_mag_vec =  zeros(n2, n3);
percent = zeros(n2, n3);


%%%% Motor config %%%%
run(strcat('Motor Configs\', 'EX_8.m'));
wb = k1;
%%%
tic
            
parfor j = 1:n2
    %tic
    for k = 1:n3
        %tic
        phi = linspace(phase_min, phase_max, n)';
        delta = phi(2) - phi(1);
        torque = zeros(n, 1);
        v = zeros(n, 1);
        
        for x = 1:n
            i_d = mag_max*pmi(j)*cos(phi(x));
            i_q = mag_max*pmi(j)*sin(phi(x));

            v_d = r_a*i_d - npp*tdot(k)*l_q*i_q;
            v_q = r_a*i_q + npp*tdot(k)*l_d*i_d + npp*tdot(k)*wb;

            v(x) = norm([v_d, v_q]);
            torque(x) =(abs(i_d)<id_max)* npp*(3/2)*(wb+(l_d - l_q)*i_d)*i_q;
            
            %[torque(x), v(x)] = motor_fun_dq(mag_max*pmi(j), phi(x), tdot(k));
        end
        is_valid = (v<v_max);
        tmax = max(torque.*is_valid);
        tmin = min(torque.*is_valid);
        if(tmax<0)
            ind_max = find(torque==tmax);
        else
            torque = 0;
            ind_max = 1;
        end
        if(tmin<0)
            ind_min = find(torque = tmin);
        else
            torque = 0;
            ind_min = 1;
        end
        
        ind_max = ind_max(1);
        ind_min = ind_min(1);
        
        torque_min_vec(j, k) = tmin;
        torque_max_vec(j, k) = tmax;
        phi_max_vec(j, k) = phi(ind_max);
        v_max_vec(j, k) = v(ind_max);
        mag_max_vec(j, k) = mag_max*pmi(j);%mag(ind_max);
        tdot_vec(j, k) = tdot(k);
    %toc    
    end
    
    %j
    
end
toc
id_vec = cos(phi_max_vec).*mag_max_vec;
iq_vec = sin(phi_max_vec).*mag_max_vec;
is_valid = v_max_vec < v_max;
%toc
[operating_area, i] = min(torque_max_vec, [], 1);
n = 1:1:n3;
id_traj = id_vec(sub2ind([n2, n3], i, n));
iq_traj = iq_vec(sub2ind([n2, n3], i, n));
%figure;plot(tdot, torque_max_vec(1,:)); title('Max Torque')
%figure;plot(tdot, phi_max_vec(1,:));  title('Max Phase')
%figure;plot(tdot, mag_max_vec(1,:)); title('Max Current')

figure; surf(tdot_vec, mag_max_vec, torque_max_vec.*is_valid);
xlabel('speed (rad/s)'); ylabel('current (A)'); zlabel('torque (N-m)');
%figure;surf(tdot_vec, mag_max_vec, phi_max_vec);
figure;plot(tdot, operating_area);
figure; plot(tdot, id_traj, tdot, iq_traj);
%figure;plot(tdot, tdot'.*operating_area);

%figure;surf(tdot_vec, mag_max_vec, tdot_vec.*torque_max_vec);
% figure;plot(tdot, i_mag_max_vec); title('Max Current')%figure;plot(tdot, t_max_vec, tdot, t_min_vec); title('Max/Min Torque')
%figure;plot(tdot, phi_max_vec, tdot, phi_min_vec);  title('Max/Min Phase')
%figure;plot(tdot, i_mag_max_vec, tdot, i_mag_min_vec); title('Max/Min Current')

%figure; scatter(phase_vec, torque_vec);
data.tdot = tdot_vec;
data.v = mag_max_vec;
data.torque = torque_max_vec;
data.phi = phi_max_vec;
save('Data/Altermotter/data.mat', 'data');
