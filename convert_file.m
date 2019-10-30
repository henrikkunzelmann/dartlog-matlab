%
% Convert a raw logging file using dartlog_convert_raw.
%

[file, path] = uigetfile('*.dat', 'Select File');

if file == 0
    error("No file selected")
end

disp("==============");
fileName = fullfile(path, file);
dartlog_convert_raw(fileName, strrep(fileName, '.dat','.mat'));
disp("==============");

disp("Done with converting all files");