function out = jsondecode2(json)
json = regexprep(json,["\t","\r","\n","\v"],'');

out = struct();

out = buildStruct(json,out);

end

function out = buildStruct(json,parent)
    KeyValue = extractKeyValue(json);
    if isempty(KeyValue)
        out = parent;
        return
    end
    for i = 1:size(KeyValue,1)
        key = KeyValue{i,1};
        obj = KeyValue{i,2};
        type = obj(1);
        switch type
            case '{'
                obj = buildStruct(obj,struct());
            case '['
                obj = buildArray(obj,{});
            case '"'
                obj = obj(2:end-1);
            case {'t','f'}
                obj = strcmp(obj,'true');
            otherwise
                obj = str2double(obj);
        end
        parent.(key) =  obj;
    end
    out = parent; 
end

function out = buildArray(json,parent)
objects = extractArrayObjects(json);
for i = 1:length(objects)
        obj = objects{i};
        type = obj(1);
        switch type
            case '{'
                obj = buildStruct(obj,struct());
            case '['
                obj = buildArray(obj,{});
            case '"'
                obj = obj(2:end-1);
            case {'t','f'}
                obj = strcmp(obj,'true');
            otherwise
                obj = str2double(obj);
        end
        parent{i} =  obj;
 end
 out = parent;
end

function pairs = extractKeyValue(json)
    json = strtrim(json);

    % Only outer {...}
    if startsWith(json, "{")
        json = strtrim(json(2:end-1));
    end

    % Prepare output
    pairs = {};

    % Position tracker
    i = 1;
    N = strlength(json);

    while i <= N
        % --- Extract key ---
        [startInd, endInd] = regexp(json(i:end), '"([^"]+)"\s*:', 'once');
        if isempty(startInd), break; end
        key = extractBetween(json, i+startInd, i+endInd-3); % -2 to drop trailing "
        i = i + endInd; % move cursor after :

        % --- Detect value type ---
        % Skip commas and whitespace
        while i <= N && ismember(json(i), [","," ",newline])
            i = i + 1;
        end

        switch json(i)
            case '"'   % string value
                [startInd, endInd] = regexp(json(i:end), '"([^"]*?)"', 'once');
                value = extractBetween(json, i+startInd-1, i+endInd-1);
                i = i + endInd;
            case "{"  % object
                [value, consumed] = extractBlock(json(i:end), "{", "}");
                i = i + consumed - 1;
            case "["  % array
                [value, consumed] = extractBlock(json(i:end), "[", "]");
                i = i + consumed - 1;
            otherwise % number, true, false, null
                [startInd, endInd] = regexp(json(i:end), '^[^,}]+', 'once');
                value = strtrim(extractBetween(json, i+startInd-1, i+endInd-1));
                i = i + endInd - 1;
        end

        % Store key-value
        pairs(end+1,:) = {char(key), char(value)};

        % Skip commas and whitespace
        while i <= N && ismember(json(i), [","," ",newline])
            i = i + 1;
        end
    end
end

function objects = extractArrayObjects(json)
    json = strtrim(json);
    % Only outer [...]
    if startsWith(json, "[")
        json = strtrim(json(2:end-1));
    end

    % Prepare output
    objects = {};

    % Position tracker
    i = 1;
    N = strlength(json);

    while i <= N
        % --- Detect value type ---
        switch json(i)
            case '"'   % string value
                [startInd, endInd] = regexp(json(i:end), '"([^"]*?)"', 'once');
                value = extractBetween(json, i+startInd-1, i+endInd-1);
                i = i + endInd;
            case "{"  % object
                [value, consumed] = extractBlock(json(i:end), "{", "}");
                i = i + consumed;
            case "["  % array
                [value, consumed] = extractBlock(json(i:end), "[", "]");
                i = i + consumed;
            otherwise % number, true, false, null
                [startInd, endInd] = regexp(json(i:end), '^[^,}]+', 'once');
                value = strtrim(extractBetween(json, i+startInd-1, i+endInd-1));
                i = i + endInd;
        end

        % Store key-value
        objects{end+1} = char(value);

        % Skip commas and whitespace
        while i <= N && ismember(json(i), [","," ",newline])
            i = i + 1;
        end
    end
end

function [block, consumed] = extractBlock(str, openChar, closeChar)
    % Find matching closing brace/bracket
    depth = 0;
    consumed = 0;
    for k = 1:strlength(str)
        ch = extractBetween(str,k,k);
        if ch == openChar
            depth = depth + 1;
        elseif ch == closeChar
            depth = depth - 1;
            if depth == 0
                consumed = k;
                break;
            end
        end
    end
    block = extractBetween(str, 1, consumed);
end