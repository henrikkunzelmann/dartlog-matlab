function dartlog_convert_raw(source, dest)
%dartlog_convert_raw Converts a raw .dat file saved on the sd card by the DART logger

disp("Converting raw to MATLAB");
fprintf("source = %s\n", source);
fprintf("dest = %s\n", dest);

fid = fopen(source, 'r');

% Find file size
fileInfo = dir(source);

% Read and check header
header = fread(fid, 8);
exceptedHeader = [68;65;82;84;76;79;71;0];
if ~isequal(header, exceptedHeader)
    error("Not a DARTLOG file")
end
    
% Read tags
timeIndex = 0;
tagDataIndex = zeros(4096);
tagTypes = zeros(4096);
maxTagID = 0;

tagTypeMap = [ "uint8", "uint16", "uint32", "int8", "int16", "int32", "single" ];

% Data
data.("converter") = "MATLAB";

lastPercentage = 0;
disp("....");

while ~feof(fid)
    percentage = floor((ftell(fid) / fileInfo.bytes) * 100);
    if percentage ~= lastPercentage
        fprintf("%d%%...\n", percentage);
        lastPercentage = percentage;
    end
    
    buf = fread(fid, 1);
    if isempty(buf) 
        break;
    end
    
    if buf == 0 % create new tag
        % Read the tag type
        buf = fread(fid, 1);
        tagIndex = buf;
        
        if tagIndex <= 0
            disp("Invalid tag index read");
            break;
        end
        
        % Read the tag type
        buf = fread(fid, 1);
        if (buf < 1) || (buf > 7)
            disp("Invalid tag type read");
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
        
        % Add to tags
        tags(tagIndex) = tagName;
        tagDataIndex(tagIndex) = 1;
        
        if tagIndex > maxTagID
            maxTagID = tagIndex;
        end
    else
        id = buf;
        if (id < 0) || (id > maxTagID)
            disp("Invalid id read");
            break;
        end
            
        buf = fread(fid, 1, tagTypeMap(tagTypes(id)));
        
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
    end
end

fclose(fid);
disp("Done...");
disp("Saving...");
save(dest, "data");

end


