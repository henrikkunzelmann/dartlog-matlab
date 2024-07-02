% DO NOT CALL THIS SCRIPT DIRECTLY, USE convert_file.m INSTEAD!

function dartlog_convert_raw(source, dest, progress_full)
%dartlog_convert_raw Converts a raw .dat file saved on the sd card by the DART logger

disp("");
disp("Converting raw to MATLAB");
fprintf("source = %s\n", source);
fprintf("dest = %s\n", dest);
disp("");

fid = fopen(source, 'r');

% Find file size
fileInfo = dir(source);

% Read and check header
header = fread(fid, 8);

isDARTLOG1 = isequal(header, [68;65;82;84;76;79;71;0]);
isDARTLOG2 = false;


if ~isDARTLOG1
    isDARTLOG2 = isequal(header, [68;65;82;84;76;79;71;50]);
    if ~isDARTLOG2
        error("Not a DARTLOG file")
    end
    fread(fid, 1); % read 0 ending
end

if isDARTLOG1
    disp("Is DARTLOG1 file");
elseif isDARTLOG2
    disp("Is DARTLOG2 file");
end
    
% Read tags
timeIndex = 0;
tags = [""];
tagDataIndex = zeros(1, 4096);
tagTypes = zeros(1, 4096);
maxTagID = 0;
lastID = 0;

maxTagNameLength = 58;

tagTypeMap = [ "uint8", "uint16", "uint32", "int8", "int16", "int32", "single", "double", "uint64", "int64" ];

% Data
data.("converter") = "MATLAB";

lastPercentage = -1;
disp("....");

while ~feof(fid)
    percentage = floor((ftell(fid) / fileInfo.bytes) * 100);
    if percentage ~= lastPercentage
        fprintf("%s%d%%...\n", progress_full, percentage);
        lastPercentage = percentage;
    end

    if isDARTLOG2
        % DARTLOG2 path
        buf = fread(fid, 1);
        idPart = buf(1);
        
        if isempty(buf) || length(buf) < 1 
            break;
        end
        
        if idPart < 254
            id = idPart;
        elseif idPart == 254
            id = lastID + 1;
        else % idPart == 255
            buf = fread(fid, 2);
        
            if isempty(buf) || length(buf) < 2 
                break;
            end
            id = buf(1) + buf(2) * 256;
        end
    else
        % DARTLOG1 path
        buf = fread(fid, 2);
        
        if isempty(buf) || length(buf) < 2 
            break;
        end
        id = buf(1) + buf(2) * 256;
    end
   
    lastID = id;
    
    if id == 0 % create new tag
        % Read the tag id
        buf = fread(fid, 2);
        tagIndex = buf(1) + buf(2) * 256;
        
        if tagIndex <= 0
            disp("");
            disp("[Errror]");
            disp("Invalid tag index read");
            fprintf("At byte: %d\n", ftell(fid));
            break;
        end
        
        % Read the tag type
        buf = fread(fid, 1);
        if (buf < 1) || (buf > 10)
            disp("");
            disp("[Errror]");
            disp("Invalid tag type read");
            fprintf("At byte: %d\n", ftell(fid));
            break;
        end
        
        tagTypes(tagIndex) = buf;
        
        % Read the tag name
        tagName = "";
        while 1
            buf = fread(fid, 1);
            if buf == 0
                break;
            end
            tagName = strcat(tagName, char(buf));
        end

        % Read attributes (if supported by format)
        if isDARTLOG2
            while 1
                type = fread(fid, 1);
                if type == 0 % end attribute list
                    break;
                end

                len = fread(fid, 1);
                buf = fread(fid, len); 
                % ignore data for now
            end
        end

        % Clean tagName
        tagName = strrep(tagName, '-', '_');
        tagName = strrep(tagName, '/', '_');
		tagName = strrep(tagName, ':', '');

        % Short tag name if too long
        tagNameUnshorted = tagName;
        if strlength(tagNameUnshorted) >= maxTagNameLength
            tagNameShorted = extractBetween(tagNameUnshorted, 1, maxTagNameLength);
            tagName = tagNameShorted;
            tagNameAddIndex = 0;
            while length(find(tags == tagName)) >= 1
                tagName = strcat(tagNameShorted, num2str(tagNameAddIndex));
                tagNameAddIndex = tagNameAddIndex + 1;
            end
        end

        if strlength(tagName) == 0
            disp("");
            disp("[Errror]");
            disp("Invalid empty tag name read");
            fprintf("At byte: %d\n", ftell(fid));
            break;
        end
        
        % Add to tags
        tags(tagIndex) = tagName;
        tagDataIndex(tagIndex) = 1;
        
        if tagIndex > maxTagID
            maxTagID = tagIndex;
        end
        
        if tagName ~= "time"
            data.(tagName) = zeros(1, 256000);
        end
    else
        if (id < 0) || (id > maxTagID)
            disp("");
            disp("[Errror]");
            disp("Invalid id read");
            fprintf("At byte: %d\n", ftell(fid));
            break;
        end

        try   
            buf = fread(fid, 1, tagTypeMap(tagTypes(id)));
            
            if length(buf) ~= 1
                disp("");
                disp("[Errror]");
                disp("Invalid data read");
                fprintf("At byte: %d\n", ftell(fid));
                break;
            end
        
            index = tagDataIndex(id);
            tagName = tags(id);
            
            % Time skew correction
            if index > 1
                % Use last value
                index = index - 1;

                lastData = data.(tagName)(index);

                index = index + 1;
                while index < timeIndex
                    data.(tagName)(index) = lastData;
                    index = index + 1;
                end
            end

            % Add newest value
            data.(tagName)(index) = buf;
            tagDataIndex(id) = index + 1;

            if tagName == "time"
                timeIndex = index;
            end
        catch
            disp("");
            disp("[Errror]");
            disp("Invalid data read (error while copying data)");
            fprintf("At byte: %d\n", ftell(fid));
        end
    end
end

fclose(fid);

% Ensure all arrays have the same length

% Time array length
timeLength = length(data.("time"));

% Match array lengths for easier plotting
fn = fieldnames(data);
for k=1:numel(fn)
    values = data.(fn{k});
    len = length(values);
    if (len == 1) % only metadata
        continue;
    end 
       
    if (len > timeLength) % trim array -> too long
        data.(fn{k}) = values(1:timeLength);
    elseif (len < timeLength) % end array -> too short
        for i=len+1:timeLength
            data.(fn{k})(i) = 0;
        end
    end
end

% Sort fields
data = orderfields(data);

disp("");
disp("Note: errors at the end may be OK, because the vehicle was turned off before the last data could be written correctly");
disp("");
disp("");
disp("Done...");
disp("Saving...");
save(dest, "data",  '-v7.3');
disp("");

end


