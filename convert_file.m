%
% Convert a raw logging file using dartlog_convert_raw.
%

% You can select multiple .dat files.

[file, path] = uigetfile('*.dat', 'Select File','MultiSelect','on');

if isnumeric(file)
    error("No file selected")
end

if iscell(file)
    fprintf("Got %d files\n", length(file));
else
    fprintf("Got 1 file\n");
end
disp("==============");

if iscell(file)
    for k=1:length(file)
        fileName = char(fullfile(path, file(k)));
        progress_full = "(" + k + "/" + length(file) + " " + round(((k - 1) / length(file)) * 100) + "%) current file: ";
        dartlog_convert_raw(fileName, strrep(fileName, '.dat','.mat'), progress_full);
        disp("==============");
    end
else
    fileName = char(fullfile(path, file));
    dartlog_convert_raw(fileName, strrep(fileName, '.dat','.mat'), "");
    disp("==============");
end

disp("Done with converting all files");