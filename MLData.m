classdef MLData
    properties
        FileName
        RawData
        RawMzValues %M/Z
        RawSpectraIntensities
        MinIntensity
        MaxIntensity
        NumberOfSpectra
        RowNumber
        ColumnNumber
        DataType %1D or 2D test
    end
    
    methods
        function obj = MLData(fileName,rawData,mzValues,intensityMatrix,numOfSpectra, rowNumber, colNumber)
            % constructor
            obj.FileName = fileName;
            obj.RawData = rawData;
            obj.RawMzValues = mzValues;
            obj.RawSpectraIntensities = intensityMatrix;
            obj.MinIntensity = min(mzValues);
            obj.MaxIntensity = max(mzValues);
            obj.NumberOfSpectra = numOfSpectra;
            obj.RowNumber = rowNumber;
            obj.ColumnNumber = colNumber;
        end
    end
end

