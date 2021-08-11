% Input
x = data;

% Signals to convert
arraysToConvert = [ "APPS_Factor", "Steer_Factor", "Brakepressure_Rear", "BrakePressure_Front", "Voltage_Pack", "Cell_Min_Voltage", "Cell_Max_Voltage", "Bus_Voltage", "Bus_Current", "Cell_Average_Temper" ];

% Find longest signal (as time reference)
longestSignal = "";
longestSignalLength = 0;
for ii = 1:length(arraysToConvert)
    len = length(x.(arraysToConvert(ii))(:,1));
    if len > longestSignalLength
        longestSignal = arraysToConvert(ii);
        longestSignalLength = len;
    end
end

h = waitbar(0, 'Converting raw data to time uniform data...');

% Fix time
for ii = 1:length(arraysToConvert)
    lastT = 0;
    offsetT = 0;
    for jj = 1:length(x.(arraysToConvert(ii)))
        t = x.(arraysToConvert(ii))(jj,1);
        if t < lastT
            offsetT = offsetT + lastT;
        end
        lastT = t;
        
        x.(arraysToConvert(ii))(jj,1) = t + offsetT;
    end
end

% Time
timeTemp = transpose(x.(longestSignal)(:,1));


startIndex = 155551;

firstTime = timeTemp(startIndex);

for ii = startIndex+1:length(timeTemp)
    t = timeTemp(ii);
    
    o.time(ii - startIndex) = t - firstTime;
    for jj = 1:length(arraysToConvert)
        sname = arraysToConvert(jj);
        sx = x.(sname)(:,1);
        sy = x.(sname)(:,2);
        o.(sname)(ii - startIndex) = interp1(sx, sy, t, 'nearest');
    end
    
    progress = (ii - startIndex) / (length(timeTemp) - startIndex);
    waitbar(progress, h, sprintf('%.3f%% done...', progress * 100));
end
close(h);

o.P_battery = o.Bus_Current .* o.Bus_Voltage;

clear x arraysToConvert longestSignal longestSignalLength h lastT offsetT timeTemp progress t firstTime ii jj len sname startIndex sx sy

% Save result in a new file
output.data = o;
save('test_fixed','-struct','output','-v7.3');

clear o output;
    