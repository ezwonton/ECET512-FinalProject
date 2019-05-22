transmitPower = 100; % Watts
transmitGain = 10^(17/10); % 17 dB basestation antenna gain to linear scale
receiveGain = 10^(0/10);   % 0 dB mobile antenna gain to linear scale
systemLoss = 10^(3/10);    % 3 dB system loss
frequency = 900*10^6;      % 900 MHz 
lambda = 3*10^8 / frequency; % Wavelength
cellRadius = 20 / sqrt(3); % 20 meters between adjacent cell centers
iValue = 2;
jValue = 1;

% Reference distance for extended shadowing-based path loss model
shadowStdDev =  4;% typical outdoor shadow standard deviation
refDistance = 1; % reference distance of 1 meter
refPower = 10^(0/10)*10e-3;  % 0 dBm = 1mW = 0.001W
%refDistance = 10; % 10 meter reference distance
%refPower = transmitPower * transmitGain * receiveGain / systemLoss * (lambda / (4*pi*refDistance))^2;
     % Reference power by Friis Free Space equation -- ideally would use measurement
     % data
pathLossExp = 2.9;  % path loss exponent 



N = iValue^2+iValue*jValue+jValue^2;
spawnRadius = 3*cellRadius;
numUsers = 5;

colors = [ [1 0 0] ; [0 1 0] ; [0 0 1] ; [1 0 0] ; [0 1 0] ; [0 0 1] ];
lines = [ '- ' ; '- ' ; '- ' ; '--' ; '--' ; '--']; 

numFrames = 150;
fig1 = figure(1);
winSize = get(fig1, 'Position');
winSize(1:2) = [0 0];

%Commented for student version of matlab
%movieFrames = moviein( numFrames, fig1, winSize );
set( fig1, 'NextPlot', 'replacechildren' );

figure(1);
clf;
cellCenters = drawTier( 0, iValue, jValue, cellRadius );
channelUsage = zeros( N, numFrames );

% Randomized user start and end positions
for index2 = 1:numUsers
   mobilePos(index2,:) = linspace( rand*spawnRadius*exp(j*2*pi*rand), rand*spawnRadius*exp(j*2*pi*rand), numFrames );   
end



distance_m2m = zeros(numUsers, numUsers, numFrames, 'double');
signalPowerReceived = zeros(numUsers, numUsers, numFrames, 'double');
signalPowerReceived_shad = zeros(numUsers, numUsers, numFrames, 'double');

for index = 1:numFrames
    figure(1);
    clf;
    hold on;
    drawTier( 0, iValue, jValue, cellRadius );
    axis off;
    
    for index2 = 1:numUsers
       plot( real(mobilePos(index2,index)), imag(mobilePos(index2,index)), 'bx' );
 %      Draw line to serving Basestation      
 %      [cell, tier, center] = findServingCell( mobilePos(index2,index), cellCenters );    
 %      if( tier == 1)
 %         channelUsage( cell, index) = channelUsage(cell, index) + 1;
 %      end
 %      line( [real(center) real(mobilePos(index2,index))], [imag(center) imag(mobilePos(index2,index))] );   
        for index3 = 1:numUsers
           if index2 ~= index3
              distance_m2m(index2, index3, index) = abs(mobilePos(index2,index) - mobilePos(index3,index));
              signalPowerReceived(index2, index3, index) = 10^((refPower - 10*pathLossExp*log10(distance_m2m(index2,index3, index)/refDistance))/10);
              signalPowerReceived_shad(index2, index3, index) = 10^((refPower - 10*pathLossExp*log10(distance_m2m(index2,index3, index)/refDistance)+randn*shadowStdDev)/10);     
           end           
        end
    end
    
    hold off;
    movieFrames(:, index) = getframe( fig1, winSize );
    
end
 
%  timeStamp(mS)   numTX   numRx  Gain(dB)  Phi(radians) Delay(microsecs)
%  Doppler(Hz)  multipath1Gain(dB) multipath1Delay(microsecs)
%  multipath2Gain(dB) multipath2Delay(microseconds)
%  
numSeconds=numFrames;
v = 30 * 0.44704; % mph to m/s

fileID = fopen('m2mScenario-5users-noShad.txt','w');
fileID2 = fopen('m2mScenario-5users-Shad.txt','w');

for index = 1:numSeconds
   for index2 = 1:numUsers
       for index3 = 1:numUsers
           if index2 ~= index3
               % No shadowing
               fprintf(fileID, '%d %d %d %6.4f %6.4f %6.4f %6.4f %6.4f %6.4f %6.4f %6.4f\n', ... 
                  index*1000, ... % Time in milliseconds
                  index2-1, ... % numTX
                  index3-1, ... % numRX 
                  10*log10(signalPowerReceived(index2,index3,index)), ... % Gain (dB)
                  0.0, ... % Phi (assumption)
                  distance_m2m(index2,index3,index)./3e8*10e6, ... % Delay (usec)
                  0.0, ... % Assume 0 doppler
                  -1000.0, 0.0, -1000.0, 0.0 ); % Assume no other multipath 
              
                % Shadowing
                fprintf(fileID2, '%d %d %d %6.4f %6.4f %6.4f %6.4f %6.4f %6.4f %6.4f %6.4f\n', ... 
                  index*1000, ... % Time in milliseconds
                  index2-1, ... % numTX
                  index3-1, ... % numRX 
                  10*log10(signalPowerReceived_shad(index2,index3,index)), ... % Gain (dB)
                  0.0, ... % Phi (assumption)
                  distance_m2m(index2,index3,index)./3e8*10e6, ... % Delay (usec)
                  0.0, ... % Assume 0 doppler
                  -1000.0, 0.0, -1000.0, 0.0 ); % Assume no other multipath 
           end
       end
   end
end
fclose(fileID);
fclose(fileID2);