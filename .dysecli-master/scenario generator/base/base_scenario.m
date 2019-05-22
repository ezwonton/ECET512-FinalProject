% Export DYSE coefficients for a base scenario given variable number of TX
% and RX
%
%  "Base scenario" will take a variable number of DYSE channels, and fully 
%  attenuate (MAX_ATTEN) all channels reciprocally starting at time
%  (START_TIME).  Scenario duration determined by configuration file
%  This can be used as a basis for more complex scenarios by inserting
%  additional code / data after these coefficients to build more
%  sophisticated scenarios.



%  DYSE RF batch scenario data format:

%  timeStamp(mS)   numTX   numRx  Gain(dB)  Phi(radians) Delay(microsecs)
%  Doppler(Hz)  multipath1Gain(dB) multipath1Delay(microsecs)
%  multipath2Gain(dB) multipath2Delay(microseconds)
%  

frequency = 900*10^6;      % 900 MHz 
lambda = 3*10^8 / frequency; % Wavelength
v = 0 * 0.44704; % mph to m/s
dyseChannelActive = 20; % (maximum numTx and numRx; make sure configuration file agrees)
START_TIME = 1.0;
MAX_ATTEN = -80.0; % Effectively zero out the signal to start 
numFrames = 1; % Probably always one for base scenario, but could use this to scale up code to more complex scenarios

% Create RF scenario file 
dyseData = zeros(numFrames, 11, 'double');
dyseData(:,1) = START_TIME * 1000; % Time in milliseconds
%dyseData(:,2) = -> numTX
%dyseData(:,3) = -> numRX
dyseData(:,4) = MAX_ATTEN; % Gain(dB)
dyseData(:,5) = 0.0; % Phi (radians)
dyseData(:,6) = 0.0; % Delay (usec)
dyseData(:,7) = -v / lambda; % Doppler (Hz)
dyseData(:,8) = -1000.0; % Multipath 1 Gain - Make it something small since there isn't any 
dyseData(:,9) =  0.0; % Multipath 1 Delay
dyseData(:,10) = -1000.0; % Multipath 2 Gain - Make it something small since there isn't any 
dyseData(:,11) = 0.0; % Multipath 2 Delay

fileID = fopen(strcat('baseScenario-', num2str(dyseChannelActive), '.txt'),'w');

for numTx = 1:dyseChannelActive
    for numRx = 1:dyseChannelActive
        dyseData(:,2) = numTx;
        dyseData(:,3) = numRx;
        for index = 1:numFrames
            fprintf(fileID, '%d %d %d %6.4f %6.4f %6.4f %6.4f %6.4f %6.4f %6.4f %6.4f\n', ... 
                dyseData(index,1),dyseData(index,2),dyseData(index,3), ...
                dyseData(index,4),dyseData(index,5),dyseData(index,6), ...
                dyseData(index,7),dyseData(index,8),dyseData(index,9), ...
                dyseData(index,10),dyseData(index,11) );
        end
    end
end
fclose(fileID);


