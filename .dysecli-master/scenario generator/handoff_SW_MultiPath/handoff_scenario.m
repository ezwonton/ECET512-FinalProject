frequency = 900*10^6;      % 900 MHz 
lambda = 3*10^8 / frequency; % Wavelength

cellRadius = 2000 / sqrt(3); % 2000 meters between adjacent cell centers

iValue = 2;
jValue = 1;
N = iValue^2 + iValue*jValue + jValue^2
gainOffset = 25; % dB shift to show things better on DYSE
decimationFactor = 3;

% Reference distance for extended shadowing-based path loss model
shadowStdDev =  4;% typical outdoor shadow standard deviation
refDistance = 1; % reference distance of 1 meter
refPower = 10^(0/10)*10e-3;  % 0 dBm = 1mW = 0.001W
%refDistance = 10; % 10 meter reference distance
%refPower = transmitPower * transmitGain * receiveGain / systemLoss * (lambda / (4*pi*refDistance))^2;
     % Reference power by Friis Free Space equation -- ideally would use measurement
     % data
pathLossExp = 2.9;  % path loss exponent 

outageProb = 0.10;

colors = [ [1 0 0] ; [0 0 1] ; [0 1 0] ; [1 0 0] ; [0 0 1] ; [0 1 0] ];
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
cellCenters = drawCluster( 0, iValue, jValue, cellRadius );

% Start mobile user in cell A, and move to cell B
mobilePos(1,:) = linspace( cellCenters(1,1) + 10*exp(j*pi/6) , cellCenters(2,1) - 10*exp(j*pi/6),  numFrames );

[cell, tier, center1] = findServingCell( mobilePos(1,1), cellCenters );    
[cell, tier, center2] = findServingCell( mobilePos(1,numFrames), cellCenters );    


for index = 1:numFrames    
    figure(1);
    clf;
    hold on;
    drawCluster( 0, iValue, jValue, cellRadius );
    axis off;

    plot( real(mobilePos(1,index)), imag(mobilePos(1,index)), 'bx' );

    h = line( [real(center1) real(mobilePos(1,index))], [imag(center1) imag(mobilePos(1,index))] );
    set(h, 'Color', colors(1,:));
    set(h, 'LineStyle', lines(1,:));

    h = line( [real(center2) real(mobilePos(1,index))], [imag(center2) imag(mobilePos(1,index))] );
    set(h, 'Color', colors(2,:));
    set(h, 'LineStyle', lines(2,:));
   
    hold off;
    movieFrames(:, index) = getframe( fig1, winSize );
    
    distanceBS1(index) = abs(mobilePos(1,index)-center1);
    signalPowerReceived1_PL(index) = 10^((refPower - 10*pathLossExp*log10(distanceBS1(index)/refDistance))/10);
    signalPowerReceived1_PL_shad(index) = 10^((refPower - 10*pathLossExp*log10(distanceBS1(index)/refDistance)+randn*shadowStdDev)/10);

    distanceBS2(index) = abs(mobilePos(1,index)-center2);
    signalPowerReceived2_PL(index) = 10^((refPower - 10*pathLossExp*log10(distanceBS2(index)/refDistance))/10);
    signalPowerReceived2_PL_shad(index) = 10^((refPower - 10*pathLossExp*log10(distanceBS2(index)/refDistance)+randn*shadowStdDev)/10);

end

handoffInterval = zeros( size(distanceBS1) );
handoffInterval( find(distanceBS1>982 & distanceBS1<1082) ) = -100;
 
%Commented for student version of matlab
%mpgwrite( movieFrames, jet, 'hw3a.mpg' );

figure(2);
clf;
hold off;
h(1) = plot( distanceBS1, 10*log10(signalPowerReceived1_PL), 'r-' );
hold on;
h(2) = plot( distanceBS1, 10*log10(signalPowerReceived1_PL_shad), 'r-.' );
h(3) = plot( distanceBS1, 10*log10(signalPowerReceived2_PL), 'b-' );
h(4) = plot( distanceBS1, 10*log10(signalPowerReceived2_PL_shad), 'b-.' );
harray = plot( distanceBS1, -86.7, 'm--' );
h(5) = harray(1);
harray = plot( distanceBS1, -88, 'k--' );
h(6) = harray(1);
tmp = line( [982 1082], [-100 -100]);
set(tmp, 'Color', [0 1 0]);
h(7) = tmp;



%plot( distanceBS1, handoffInterval, 'gx' );

xlabel( 'Distance d_1 (meters) = 2000 - Distance d_2 (meters)' ), ylabel( 'Uplink Signal Power Received (dBm)' );
legend( h, sprintf('at BS_1 - w/o Shadowing'), ...
        sprintf('at BS_1 - w/ Shadowing'), ...
        sprintf('at BS_2 - w/o Shadowing'), ...
        sprintf('at BS_2 - w/ Shadowing'), ...
        sprintf('P_{r,HO} w/o Shadow Margin'), ...
        sprintf('P_{r,min} w/o Shadow Margin'), ...
        sprintf('Handoff Interval w/o Shadow Margin'));

clear h;
     
figure(3);
clf;
hold off;
%2005 - I didn't finish this - would be nice to get a shadow margin problem out of this.
%qinv = sqrt(2)*erfinv(1-2*outageProb);
%M_Shad = qinv * shadowStdDev;
%d1_min = (M_Shad - 88)

h(1) = plot( distanceBS1, 10*log10(signalPowerReceived1_PL), 'r-' );
hold on;
h(2) = plot( distanceBS1, 10*log10(signalPowerReceived1_PL_shad), 'r-.' );
h(3) = plot( distanceBS1, 10*log10(signalPowerReceived2_PL), 'b-' );
h(4) = plot( distanceBS1, 10*log10(signalPowerReceived2_PL_shad), 'b-.' );
harray = plot( distanceBS1, -80.98, 'm--' );
h(5) = harray(1);
%harray = plot( distanceBS1, M_Shad-88, 'k--' );
h(6) = harray(1);

tmp = line( [620 720], [-100 -100]);
set(tmp, 'Color', [0 1 0]);
h(7) = tmp;



%plot( distanceBS1, handoffInterval, 'gx' );

xlabel( 'Distance d_1 (meters) = 2000 - Distance d_2 (meters)' ), ylabel( 'Uplink Signal Power Received (dBm)' );
legend( h, sprintf('at BS_1 - w/o Shadowing'), ...
        sprintf('at BS_1 - w/ Shadowing'), ...
        sprintf('at BS_2 - w/o Shadowing'), ...
        sprintf('at BS_2 - w/ Shadowing'), ...
        sprintf('P_{r,HO} w Shadow Margin'), ...
        sprintf('P_{r,min} w Shadow Margin'), ...
        sprintf('Handoff Interval w Shadow Margin'));
    
% Export DYSE coefficients for this scenario
% 2000 m in 150 steps --> approximately 13 m per step
% 30 mph --> approximately 13 m per second
% ... thus assume mobile moves one 13 meter step every second
%    DYSE assumptions: (downlink) --- incorrect
%        BS_1 -> numRX=0, BS_2 -> numRX=1, Mobile -> numTX= 2
%    Real assumptions: (downlink) - BS transmit to movile
%        Mobile -> numTX=0, BS_1 -> numRX=1, BS_2 -> numRX=2
%  DYSE RF batch scenario data format:

%  timeStamp(mS)   numTX   numRx  Gain(dB)  Phi(radians) Delay(microsecs)
%  Doppler(Hz)  multipath1Gain(dB) multipath1Delay(microsecs)
%  multipath2Gain(dB) multipath2Delay(microseconds)
%  
numSeconds=numFrames;
v = 30 * 0.44704; % mph to m/s


% Create RF scenario file with shadowing

% BS_1->Mobile link
bs1Mobile = zeros(numSeconds, 11, 'like',signalPowerReceived1_PL_shad);
bs1Mobile(:,1) = (1:numSeconds)'* 1000; % Time in milliseconds
bs1Mobile(:,2) = 0; %numTX
bs1Mobile(:,3) = 1; %numRX
bs1Mobile(:,4) = 10*log10(signalPowerReceived1_PL_shad).'+gainOffset; % Gain(dB)
bs1Mobile(:,5) = 0.0; % Phi (radians)
bs1Mobile(:,6) = distanceBS1.'/3e8 * 10e6; % Delay (usec)
bs1Mobile(:,7) = -v / lambda; % Doppler (Hz)
bs1Mobile(:,8) = normrnd(0.05*mean(10*log10(signalPowerReceived1_PL_shad)),abs(0.005*mean(10*log10(signalPowerReceived1_PL_shad))),size(signalPowerReceived1_PL)) ; % Multipath 1 Gain - Make it something small since there isn't any 
bs1Mobile(:,9) =  0.0; % Multipath 1 Delay
bs1Mobile(:,10) = normrnd(0.05*mean(10*log10(signalPowerReceived1_PL_shad)),abs(0.005*mean(10*log10(signalPowerReceived1_PL_shad))),size(signalPowerReceived1_PL)) ; % Multipath 2 Gain - Make it something small since there isn't any 
bs1Mobile(:,11) = 0.0; % Multipath 2 Delay

% Mobile->BS_1 link -- make it perfectly reciprocal
mobileBs1 = bs1Mobile;
mobileBs1(:,2) = 1; %numTX
mobileBs1(:,3) = 0; %numRX

% BS_2->Mobile link
bs2Mobile = zeros(numSeconds, 11, 'like',signalPowerReceived2_PL_shad);
bs2Mobile(:,1) = (1:numSeconds)'* 1000; % Time in milliseconds
bs2Mobile(:,2) = 0; %numTX
bs2Mobile(:,3) = 2; %numRX
bs2Mobile(:,4) = 10*log10(signalPowerReceived2_PL_shad).'+gainOffset; % Gain(dB)
bs2Mobile(:,5) = 0.0; % Phi (radians)
bs2Mobile(:,6) = distanceBS2.'/3e8 * 10e6; % Delay (usec)
bs2Mobile(:,7) = v / lambda; % Doppler (Hz)
bs2Mobile(:,8) = normrnd(0.05*mean(10*log10(signalPowerReceived1_PL_shad)),abs(0.005*mean(10*log10(signalPowerReceived1_PL_shad))),size(signalPowerReceived1_PL)) ; % Multipath 1 Gain - Make it something small since there isn't any 
bs2Mobile(:,9) =  0.0; % Multipath 1 Delay
bs2Mobile(:,10) = normrnd(0.05*mean(10*log10(signalPowerReceived1_PL_shad)),abs(0.005*mean(10*log10(signalPowerReceived1_PL_shad))),size(signalPowerReceived1_PL)) ; % Multipath 2 Gain - Make it something small since there isn't any 
bs2Mobile(:,11) = 0.0; % Multipath 2 Delay

% Mobile->BS_2 link -- make it perfectly reciprocal
mobileBs2 = bs2Mobile;
mobileBs2(:,2) = 2; %numTX
mobileBs2(:,3) = 0; %numRX


fileID = fopen('handoffScenario-2bs-1ms-Shad.txt','w');
for index = 1:decimationFactor:numFrames
   fprintf(fileID, '%d %d %d %6.4f %6.4f %6.4f %6.4f %6.4f %6.4f %6.4f %6.4f\n', ... 
       bs1Mobile(index,1),bs1Mobile(index,2),bs1Mobile(index,3), ...
       bs1Mobile(index,4),bs1Mobile(index,5),bs1Mobile(index,6), ...
       bs1Mobile(index,7),bs1Mobile(index,8),bs1Mobile(index,9), ...
       bs1Mobile(index,10),bs1Mobile(index,11) ); 
  
   fprintf(fileID, '%d %d %d %6.4f %6.4f %6.4f %6.4f %6.4f %6.4f %6.4f %6.4f\n', ... 
       mobileBs1(index,1),mobileBs1(index,2),mobileBs1(index,3), ...
       mobileBs1(index,4),mobileBs1(index,5),mobileBs1(index,6), ...
       mobileBs1(index,7),mobileBs1(index,8),mobileBs1(index,9), ...
       mobileBs1(index,10),mobileBs1(index,11) );
   
    fprintf(fileID, '%d %d %d %6.4f %6.4f %6.4f %6.4f %6.4f %6.4f %6.4f %6.4f\n', ... 
       bs2Mobile(index,1),bs2Mobile(index,2),bs2Mobile(index,3), ...
       bs2Mobile(index,4),bs2Mobile(index,5),bs2Mobile(index,6), ...
       bs2Mobile(index,7),bs2Mobile(index,8),bs2Mobile(index,9), ...
       bs2Mobile(index,10),bs2Mobile(index,11) ); 
   
     fprintf(fileID, '%d %d %d %6.4f %6.4f %6.4f %6.4f %6.4f %6.4f %6.4f %6.4f\n', ... 
       mobileBs2(index,1),mobileBs2(index,2),mobileBs2(index,3), ...
       mobileBs2(index,4),mobileBs2(index,5),mobileBs2(index,6), ...
       mobileBs2(index,7),mobileBs2(index,8),mobileBs2(index,9), ...
       mobileBs2(index,10),mobileBs2(index,11) );
end
fclose(fileID);