%
% Convert a raw logging file using dartlog_convert_raw.
%

[file, path] = uigetfile('*.dat', 'Select File','MultiSelect','on');

if isnumeric(file)
    error("No file selected")
end

fprintf("Got %d files", length(file));
disp("==============");

if iscell(file)
    for k=1:length(file)
        fileName = char(fullfile(path, file(k)));
        dartlog_convert_raw(fileName, strrep(fileName, '.dat','.mat'));
        disp("==============");
    end
else
    fileName = char(fullfile(path, file));
    dartlog_convert_raw(fileName, strrep(fileName, '.dat','.mat'));
    disp("==============");
end

disp("Done with converting all files");