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
        dartlog_convert_raw(fileName, get_target_file_name(fileName), progress_full);
        disp("==============");
    end
else
    fileName = char(fullfile(path, file));
    dartlog_convert_raw(fileName, get_target_file_name(fileName), "");
    disp("==============");
end

disp("Done with converting all files");

function target = get_target_file_name(file)
    [folder, baseFileName, ~] = fileparts(file);

    newBaseFileName = sprintf('%s.mat', baseFileName);
    target = fullfile(folder, newBaseFileName);
end