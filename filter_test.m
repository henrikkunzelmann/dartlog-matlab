t = data.time;
x = data.SensorFusion_GyroZ;

Fs = 1000;
Hd = designfilt('lowpassfir','FilterOrder',20,'CutoffFrequency',20, ...
       'DesignMethod','window','Window',{@kaiser,3},'SampleRate',Fs);


y1 = filter(Hd,x);

plot(t,x,t,y1)


xlabel('Time (s)')
ylabel('Amplitude')
legend('Original Signal','Filtered Data')