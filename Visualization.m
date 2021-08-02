classdef Visualization
    
    properties
    end
    
    methods (Static)
        function plotRawMSData(app)
            %plot(app.Preprocessing_RawMSPlot,app.CurrentProject.RawData.RawMzValues, app.CurrentProject.RawData.RawSpectraIntensities(:, 3))
            %xlim(app.Preprocessing_RawMSPlot,[50000 60000])
            %hold(app.Preprocessing_RawMSPlot,"on");
            %for k = 1:app.CurrentProject.RawData.NumberOfSpectra
               %plot(app.Preprocessing_RawMSPlot,app.CurrentProject.RawData.RawMzValues, app.CurrentProject.RawData.RawSpectraIntensities(:, k))
            %end
            %hold(app.Preprocessing_RawMSPlot,"off");
            %fprintf('%d',app.CurrentProject.RawData.RawMzValues)
            app.Preprocessing_RawMSPlot.XLim = [app.CurrentProject.RawData.MinIntensity app.CurrentProject.RawData.MaxIntensity];
            plot(app.Preprocessing_RawMSPlot,app.CurrentProject.RawData.RawMzValues, app.CurrentProject.RawData.RawSpectraIntensities)
        end
        
        function plotPreprocessedMSData(app)
            app.Preprocessing_PreprocessedMSPlot.XLim = [app.CurrentProject.PreprocessedData.SectionStart app.CurrentProject.PreprocessedData.SectionEnd];
            app.Preprocessing_RawMSPlot.XLim = [app.CurrentProject.PreprocessedData.SectionStart app.CurrentProject.PreprocessedData.SectionEnd];
            if isempty(app.Preprocessing_SpectrumtodisplayEditField.Value)
                cla(app.Preprocessing_PreprocessedMSPlot)
                plot(app.Preprocessing_PreprocessedMSPlot,app.CurrentProject.RawData.RawMzValues,app.CurrentProject.PreprocessedData.BaselinedSpectra)
                    %plot(app.UIAxes,app.SectionOfInterest,app.AlignedSectionOfInterest)
            else
                cla(app.Preprocessing_PreprocessedMSPlot)
                plot(app.Preprocessing_PreprocessedMSPlot,app.CurrentProject.RawData.RawMzValues,app.CurrentProject.PreprocessedData.BaselinedSpectra(:,app.CurrentProject.PreprocessedData.DisplayingSpectra))                   
            end
        end
        
        function plotRawMSData_Normalization(app)
            app.Normalization_ProcessedMSPlot.XLim = [app.CurrentProject.RawData.MinIntensity app.CurrentProject.RawData.MaxIntensity];
            plot(app.Normalization_ProcessedMSPlot,app.CurrentProject.RawData.RawMzValues, app.CurrentProject.PreprocessedData.BaselinedSpectra)
        end
        
        function plotNormalizedSpectra(app)
            app.Normalization_NormalizedMSPlot.XLim = [app.CurrentProject.RawData.MinIntensity app.CurrentProject.RawData.MaxIntensity];
            cla(app.Normalization_NormalizedMSPlot)
            % Plotting Normalized Data
            
            switch app.CurrentProject.PreprocessedData.NormalizeDisplay
                case 'All'
                    plot(app.Normalization_NormalizedMSPlot, app.CurrentProject.RawData.RawMzValues, app.CurrentProject.PreprocessedData.NormalizedSpectra)
                case 'Single'
                    [x,y] = size(app.CurrentProject.RawData.RawMzValues);
                    sprintf('MZ x: %d, y: %d',x,y)
                    [x,y] = size(app.CurrentProject.PreprocessedData.NormalizedSpectra);
                    sprintf('Normalized x: %d, y: %d',x,y)
                    plot(app.Normalization_NormalizedMSPlot, app.CurrentProject.RawData.RawMzValues, app.CurrentProject.PreprocessedData.NormalizedSpectra(:, app.Normalization_SamplePointSpinner.Value));
                case 'Multiple'
                    retreivedata = get(app.Normalization_SelectDataTable,'data');
                    hold(app.Normalization_NormalizedMSPlot,"on");
                    for k = 1:length(retreivedata(:,2))
                        if retreivedata(k,2) == 1
                            plot(app.Normalization_NormalizedMSPlot, app.CurrentProject.RawData.RawMzValues, app.CurrentProject.PreprocessedData.NormalizedSpectra(:, k))
                        end
                    end
                    hold(app.Normalization_NormalizedMSPlot,"off");
            end     
        end
        
        function displayNormalizedDataTable(app)
            %NormData = app.CurrentProject.PreprocessedData.NormalizedSpectra;
            %SampleIndex = transpose(1:app.ColumnNumber);
            %DataToDisplay = cat(2,SampleIndex,NormData);
            %app.Normalization_DataTable.RowName = 'numbered';
            %app.Normalization_DataTable.ColumnName = 'numbered';

            app.Normalization_DataTable.Data = [app.CurrentProject.RawData.RawMzValues app.CurrentProject.PreprocessedData.NormalizedSpectra];
            s = uistyle('HorizontalAlignment','center');
            addStyle(app.Normalization_DataTable,s);
        end
        
        function plotPeakDetection(app)
            cla(app.Detection_PeakDetectionPlot)
            app.TotalnoofpeaksEditField.Value = my_numel(app.CurrentProject.PreprocessedData.CutThresholdPeak);
            app.Detection_PeakDetectionPlot.XLim = [app.CurrentProject.RawData.MinIntensity app.CurrentProject.RawData.MaxIntensity];

            if isempty(app.Detection_SpectrumtodisplayEditField.Value)
                hold(app.Detection_PeakDetectionPlot,"on");
                for i=1:app.CurrentProject.RawData.NumberOfSpectra
                    plot(app.Detection_PeakDetectionPlot,app.CurrentProject.RawData.RawMzValues,app.CurrentProject.PreprocessedData.NormalizedSpectra(:,i),app.CurrentProject.PreprocessedData.CutThresholdPeak{i}(:,1),app.CurrentProject.PreprocessedData.CutThresholdPeak{i}(:,2),'rx')
                end
                hold(app.Detection_PeakDetectionPlot,"off");

            else
                %app.UIAxes.Title.String = 'Selected spectra';
                index = str2num(app.Detection_SpectrumtodisplayEditField.Value);
                plot(app.Detection_PeakDetectionPlot,app.CurrentProject.RawData.RawMzValues,app.CurrentProject.PreprocessedData.NormalizedSpectra(:,index),'b',app.CurrentProject.PreprocessedData.CutThresholdPeak{index}(:,1),app.CurrentProject.PreprocessedData.CutThresholdPeak{index}(:,2),'rx')
            end
        end
        
        function plotPeakBinning_Hierachical(app)
            app.TotalnoofcommonpeaksEditField.Value = length(app.CurrentProject.PreprocessedData.CMZ);
            hold(app.Binning_PeakBinningPlot,"on");
            box(app.Binning_PeakBinningPlot,"on");
                for i=1:length(app.CurrentProject.PreprocessedData.CMZ)
                    xline(app.Binning_PeakBinningPlot,app.CurrentProject.PreprocessedData.CMZ(i),'k');
                end
            plot(app.Binning_PeakBinningPlot,app.CurrentProject.RawData.RawMzValues,app.CurrentProject.PreprocessedData.NormalizedSpectra)
        end
        
        function plotBinningEdgeList(app)
            edgeList = app.CurrentProject.PreprocessedData.EdgeList;
            commonMZ = app.CurrentProject.PreprocessedData.CMZ;
            
            cla(app.Binning_EdgeListPlot)

            %axes(app.Binning_EdgeListPlot,'NextPlot','add',...           %# Add subsequent plots to the axes,
            % 'DataAspectRatio',[1 1 1],...  %#   match the scaling of each axis,
            % 'YLim',[0 eps],...             %#   set the y axis limit (tiny!),
            % 'Color','none');               %#   and don't use a background color
            hold(app.Binning_EdgeListPlot,"on");
            plot(app.Binning_EdgeListPlot,commonMZ,0,'b.','MarkerSize',10);
            plot(app.Binning_EdgeListPlot,edgeList,0,'r*','MarkerSize',10);
            hold(app.Binning_EdgeListPlot,"off");

        end
        
        function plotBinningSpectra(app)
            cla(app.PeakBinningFinalPlot)
            app.PeakBinningFinalPlot.XLim = [app.CurrentProject.RawData.MinIntensity app.CurrentProject.RawData.MaxIntensity];
            
            switch app.CurrentProject.PreprocessedData.BinningDisplay
                case 'All'
                    bar(app.PeakBinningFinalPlot,app.CurrentProject.PreprocessedData.BinIndexList, app.CurrentProject.PreprocessedData.BinnedSpectra);
                case 'Single'
                    bar(app.PeakBinningFinalPlot,app.CurrentProject.PreprocessedData.BinIndexList, app.CurrentProject.PreprocessedData.BinnedSpectra(:, app.Binning_SamplePointSpinner.Value));
                case 'Multiple'
                    retreivedata = get(app.Binning_SelectDataTable,'data');
                    hold(app.PeakBinningFinalPlot,"on");
                    for k = 1:length(retreivedata(:,2))
                        if retreivedata(k,2) == 1
                            bar(app.PeakBinningFinalPlot,app.CurrentProject.PreprocessedData.BinIndexList, app.CurrentProject.PreprocessedData.BinnedSpectra(:, k));
                        end
                    end
                    hold(app.PeakBinningFinalPlot,"off");
            end     
        end
        
        function plotAlignedPeak(app)
            hold (app.Binning_AlignedPeakBinningPlot, "on");
            box (app.Binning_AlignedPeakBinningPlot, "on");
            for i=1:length(app.CurrentProject.PreprocessedData.CMZ)
                xline(app.Binning_AlignedPeakBinningPlot,app.CurrentProject.PreprocessedData.CMZ(i),'k');
            end
            plot(app.Binning_AlignedPeakBinningPlot,app.CurrentProject.RawData.RawMzValues,app.CurrentProject.PreprocessedData.NormalizedSpectra)
            plot(app.Binning_AlignedPeakBinningPlot,app.CurrentProject.PreprocessedData.CMZ,app.CurrentProject.PreprocessedData.AlignedDetectedPeak,'o')
        end
        
        function displayBinDataTable(app)
            %app.UITable.RowName = 'numbered';
            %app.UITable.ColumnName = 'numbered';

            app.Binning_Table.Data = [app.CurrentProject.PreprocessedData.BinIndexList app.CurrentProject.PreprocessedData.BinnedSpectra];
            s = uistyle('HorizontalAlignment','center');
            addStyle(app.Binning_Table,s);
        end
        
    end
end

