function Record = AndorRecord(RecordName, RecordFormat)

AndorParamDir = dir('*.txt');
Record = [];
skip = 1;
if ~isempty(AndorParamDir)
    AndorParamFileName = AndorParamDir.name;
    fid = fopen(AndorParamFileName);
    while 1
        tline = fgetl(fid);
        if ~ischar(tline)
            if skip
                skip = 0;
            else
                break;
            end
        end
        Ind = strmatch(RecordName, tline);
        if ~isempty(Ind)
            Record = textscan(tline, [RecordName, RecordFormat]);
%             Record = Record{1};
            break;
        end
    end
    fclose(fid);
end
