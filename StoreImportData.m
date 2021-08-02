classdef StoreImportData
    properties
        FileName = ""
        RawData
        RawMzValues %M/Z
        RawSpectraIntensities
        MinIntensity = 0
        MaxIntensity = 0
        NumberOfSpectra = 0
        RowNumber = 0
        ColumnNumber = 0
        DataType %1D or 2D test
        ClassName
    end
    
    methods
        function obj = StoreImportData(ClassNum)
            % constructor
            obj.FileName(1:ClassNum) = "";
            obj.RawData = cell(1,ClassNum);
            obj.RawMzValues = cell(1,ClassNum);
            obj.RawSpectraIntensities = cell(1,ClassNum);
            obj.MinIntensity(1:ClassNum) = 0;
            obj.MaxIntensity(1:ClassNum) = 0;
            obj.NumberOfSpectra(1:ClassNum) = 0;
            obj.RowNumber(1:ClassNum) = 0;
            obj.ColumnNumber(1:ClassNum) = 0;
            %obj.ClassName = "";
        end
    end
end

