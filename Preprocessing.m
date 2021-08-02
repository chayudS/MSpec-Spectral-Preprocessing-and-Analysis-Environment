classdef Preprocessing
    properties
    end
    
    methods (Static)
        function plotButtonPushedHandler(app)
            
            windowSize = app.Preprocessing_WindowSizeEditField.Value;
            stepSize = app.Preprocessing_StepsizeEditField.Value;
            quantileValue = app.Preprocessing_QuantilevalueEditField.Value;

            referenceSpectrum = app.Preprocessing_ReferenceSpectrumEditField.Value;
            segmentSize = app.Preprocessing_MinimumsegementsizeallowedEditField.Value;
            shiftAllowance = app.Preprocessing_MaximumshiftallowedEditField.Value;
            
            app.CurrentProject.PreprocessedData.DisplayingSpectra = str2num(cell2mat(split(app.Preprocessing_SpectrumtodisplayEditField.Value,',')));
            app.CurrentProject.PreprocessedData.SectionStart = str2num(app.Preprocessing_StartingpointEditField.Value);
            app.CurrentProject.PreprocessedData.SectionEnd = str2num(app.Preprocessing_EndingpointEditField.Value);
            
            %Save User Inputs
            app.CurrentProject.PreprocessedData.setPreprocessInfo(windowSize,stepSize,quantileValue,referenceSpectrum,segmentSize,shiftAllowance);
            
            if isempty(app.Preprocessing_StartingpointEditField.Value)
                app.CurrentProject.PreprocessedData.SectionStart = app.CurrentProject.RawData.MinIntensity;
            end
            
            if isempty(app.Preprocessing_EndingpointEditField.Value)
                app.CurrentProject.PreprocessedData.SectionEnd = app.CurrentProject.RawData.MaxIntensity;
            end
            
            Preprocessing.alignment(app);
            Preprocessing.baselineCorrection(app);
        end
        
        function baselineCorrection(app)
            %alignment(app);
            baselined = msbackadj(app.CurrentProject.RawData.RawMzValues,transpose(app.CurrentProject.PreprocessedData.AlignedSpectra),'STEPSIZE', app.CurrentProject.PreprocessedData.StepSize, 'WINDOWSIZE', app.CurrentProject.PreprocessedData.WindowSize,'QuantileValue',app.CurrentProject.PreprocessedData.QuantileValue,'SmoothMethod','lowess');        
            baselined = max(baselined,0);
            app.CurrentProject.PreprocessedData.BaselinedSpectra = mslowess(app.CurrentProject.RawData.RawMzValues,baselined);
        end
        
        function alignment(app)
            sample = app.CurrentProject.RawData.RawSpectraIntensities;
            spectra = transpose(sample);
            reference = spectra(app.CurrentProject.PreprocessedData.ReferenceSpectrum,:);
            segSize = app.CurrentProject.PreprocessedData.SegmentSize;
            shift = app.CurrentProject.PreprocessedData.ShiftAllowance;
            
            if length(reference)~=length(spectra)
                error('Reference and spectra of unequal lengths');
            elseif length(reference)== 1
                error('Reference cannot be of length 1');
            end
            if nargin==3
                shift = length(reference);
            end
            for i=1:size(spectra,1)
                startpos = 1;
                aligned =[];
                while startpos <= length(spectra)
                    endpos=startpos+(segSize*2);
                    if endpos >=length(spectra)
                        samseg= spectra(i,startpos:length(spectra));
                        refseg= reference(1,startpos:length(spectra));
                    else
                        samseg = spectra(i,startpos+segSize:endpos-1);
                        refseg = reference(1,startpos+segSize:endpos-1);
                        Preprocessing.findMin(app,samseg,refseg);
                        minpos = app.CurrentProject.PreprocessedData.MinPosition;
                        endpos = startpos+minpos+segSize;
                        samseg = spectra(i,startpos:endpos);
                        refseg = reference(1,startpos:endpos);
                    end
                    Preprocessing.FFTcorr(app,samseg,refseg,shift);
                    lag = app.CurrentProject.PreprocessedData.SegmentLag;
                    Preprocessing.move(app,samseg,lag);
                    aligned = [aligned app.CurrentProject.PreprocessedData.ShiftedSegment];
                    startpos=endpos+1;
                end
                app.CurrentProject.PreprocessedData.AlignedSpectra(i,:) = aligned;
            end
        end
        
        function FFTcorr(app,spectrum, target, shift)
            %padding
            M=size(target,2);
            diff = 1000000;
            for i=1:20
                curdiff=((2^i)-M);
                if (curdiff > 0 && curdiff<diff)
                    diff = curdiff;
                end
            end
            
            target(1,M+diff)=0;
            spectrum(1,M+diff)=0;
            M= M+diff;
            X=fft(target);
            Y=fft(spectrum);
            R=X.*conj(Y);
            R=R./(M);
            rev=ifft(R);
            vals=real(rev);
            maxpos = 1;
            maxi = -1;
            if M<shift
                shift = M;
            end
            
            for i = 1:shift
                if (vals(1,i) > maxi)
                    maxi = vals(1,i);
                    maxpos = i;
                end
                if (vals(1,length(vals)-i+1) > maxi)
                    maxi = vals(1,length(vals)-i+1);
                    maxpos = length(vals)-i+1;
                end
            end
        
            if maxi < 0.1
                lag =0;
            end
            if maxpos > length(vals)/2
               lag = maxpos-length(vals)-1;
            else
               lag =maxpos-1;
            end
            app.CurrentProject.PreprocessedData.SegmentLag = lag;
        end

        function move(app, seg, lag)
            
            if (lag == 0) || (lag >= length(seg))
                movedSeg = seg;
            end
            
            if lag > 0
                ins = ones(1,lag)*seg(1);
                movedSeg = [ins seg(1:(length(seg) - lag))];
            elseif lag < 0
                lag = abs(lag);
                ins = ones(1,lag)*seg(length(seg));
                movedSeg = [seg((lag+1):length(seg)) ins];
            end
            app.CurrentProject.PreprocessedData.ShiftedSegment = movedSeg;
        end
        
        function findMin(app, samseg,refseg)
        
            [Cs,Is]=sort(samseg);
            [Cr,Ir]=sort(refseg);
            minposA = [];
            minInt = [];
            for i=1:round(length(Cs)/20)
                for j=1:round(length(Cs)/20)
                    if Ir(j)==Is(i);
                        minpos = Is(i);
                    end
                end
            end
            app.CurrentProject.PreprocessedData.MinPosition = Is(1,1);
        end
        
        
        
        %================Data Normalization==========
        
        function updateNormalizedSpectra(app)
            % Data Normalization
                
            NormalizedSpectra = app.CurrentProject.PreprocessedData.BaselinedSpectra;
            numberOfSpectra = app.CurrentProject.RawData.NumberOfSpectra;
            
            switch app.CurrentProject.PreprocessedData.NormalizeMethod % Get Tag of selected object.
                case 'Sum'
                    for j = 1:numberOfSpectra
                        colj = NormalizedSpectra(:,j);
                        NormalizedSpectra(:, j) = NormalizedSpectra(:, j)./sum(colj);
                    end
                 case 'Area'
                    for j = 1:numberOfSpectra
                        colj = NormalizedSpectra(:,j);
                        NormalizedSpectra(:, j) = NormalizedSpectra(:, j)./trapz(app.CurrentProject.RawData.RawMzValues, colj);
                    end
                 case 'Norm'
                    for j = 1:numberOfSpectra
                        factor = norm(NormalizedSpectra(:,j),app.CurrentProject.PreprocessedData.NormalizationNormValue);
                        NormalizedSpectra(:, j) = NormalizedSpectra(:, j)./factor;
                    end
                 case 'Median'
                     for j = 1:numberOfSpectra
                        factor = median(NormalizedSpectra(:,j));
                        NormalizedSpectra(:, j) = NormalizedSpectra(:, j)./factor;
                     end
                 case 'Noise'
                    for j = 1:numberOfSpectra
                        % Noise Level
                        DifVector = diff(NormalizedSpectra(:,j));
                        % universal thresholding
                        MedOfDif = median(DifVector);
                        e = abs(DifVector-MedOfDif);
                        factor = median(e);
                        NormalizedSpectra(:, j) = NormalizedSpectra(:, j)./factor;
                    end
                case 'Max'
                    for j = 1:numberOfSpectra
                        factor = max(NormalizedSpectra(:,j));
                        NormalizedSpectra(:, j) = NormalizedSpectra(:, j)./factor;
                     end
                 otherwise %peak
                    idx = app.CurrentProject.PreprocessedData.ReferencePeakIndex;
                    for j = 1:numberOfSpectra
                        ref = NormalizedSpectra(idx,j);
                        NormalizedSpectra(:, j) = NormalizedSpectra(:, j)./ref;
                    end
            end
            NormalizedSpectra(isinf(NormalizedSpectra)|isnan(NormalizedSpectra)) = 0; % Replace NaNs and infinite values with zeros
            app.CurrentProject.PreprocessedData.NormalizedSpectra = NormalizedSpectra;
        end
        
        %===========Peak Detection=================
        
        function peakDetection(app)
            if (app.CurrentProject.PreprocessedData.IsAutoDetected)
                app.CurrentProject.PreprocessedData.DetectedPeak = mspeaks(app.CurrentProject.RawData.RawMzValues,app.CurrentProject.PreprocessedData.NormalizedSpectra);
            else
                app.CurrentProject.PreprocessedData.DetectedPeak = mspeaks(app.CurrentProject.RawData.RawMzValues,app.CurrentProject.PreprocessedData.NormalizedSpectra,'DENOISING',true,'BASE',app.CurrentProject.PreprocessedData.Base,'MULTIPLIER',app.CurrentProject.PreprocessedData.Multiplier,'HEIGHTFILTER',app.CurrentProject.PreprocessedData.HeightFilter);
            end
            app.CurrentProject.PreprocessedData.CutThresholdPeak = cellfun(@(p) p(p(:,1)>app.CurrentProject.PreprocessedData.PeakThreshold,:),app.CurrentProject.PreprocessedData.DetectedPeak,'Uniform',false);
        end
        
        %==========Binning==========================
        
        function peakBinning_Hierachical(app)
            %Put all the peaks into a single array and construct a vector with the spectrogram index for each peak.

            allPeaks = cell2mat(app.CurrentProject.PreprocessedData.CutThresholdPeak);
            numPeaks = cellfun(@(x) length(x),app.CurrentProject.PreprocessedData.CutThresholdPeak);
            Sidx = accumarray(cumsum(numPeaks),1);
            Sidx = cumsum(Sidx)-Sidx;
            
            %Create a custom distance function that penalizes clusters containing peaks from the same spectrogram, then perform hierarchical clustering.

            distfun = @(x,y) (x(:,1)-y(:,1)).^2 + (x(:,2)==y(:,2))*10^6;

            tree = linkage(pdist([allPeaks(:,1),Sidx],distfun));
            clusters = cluster(tree,'CUTOFF',app.CurrentProject.PreprocessedData.Cutoff,'CRITERION','Distance');
            
            %The common mass/charge reference vector (CMZ) is found by calculating the centroids for each cluster.
            CMZ = accumarray(clusters,prod(allPeaks,2))./accumarray(clusters,allPeaks(:,2));
            
            % Similarly, the maximum peak intensity of every cluster is also computed.

            PR = accumarray(clusters,allPeaks(:,2),[],@max);
            [CMZ,h] = sort(CMZ);
            PR = PR(h);
            
            cla(app.Binning_PeakBinningPlot);
            app.Binning_PeakBinningPlot.XLim = [app.CurrentProject.RawData.MinIntensity app.CurrentProject.RawData.MaxIntensity];
            
            if isempty(app.Detection_SpectrumtodisplayEditField.Value)
                hold(app.Binning_PeakBinningPlot,"on");
                box(app.Binning_PeakBinningPlot,"on");
                for i=1:length(CMZ)
                    xline(app.Binning_PeakBinningPlot,CMZ(i),'k');
                end
                plot(app.Binning_PeakBinningPlot,app.CurrentProject.RawData.RawMzValues,app.CurrentProject.PreprocessedData.NormalizedSpectra)
            else
                index = str2num(app.Detection_SpectrumtodisplayEditField.Value);
                hold(app.Binning_PeakBinningPlot,"on");
                box(app.Binning_PeakBinningPlot,"on");
                for i=1:length(CMZ)
                    xline(app.Binning_PeakBinningPlot,CMZ(i),'k');
                end
                plot(app.Binning_PeakBinningPlot,app.CurrentProject.RawData.RawMzValues,app.CurrentProject.PreprocessedData.NormalizedSpectra(:,index))
            end
            
            app.CurrentProject.PreprocessedData.CMZ = CMZ;
            app.CurrentProject.PreprocessedData.PR = PR;

        end
        
        
        function peakBinning_Dynamic(app)
            currentCMZ = app.CurrentProject.PreprocessedData.CMZ;
            num = app.CurrentProject.RawData.NumberOfSpectra;
            PA = nan(numel(currentCMZ),num);
            DetectedSpectra = app.CurrentProject.PreprocessedData.CutThresholdPeak;
            for i = 1:num
                %[j,k] = samplealign([currentCMZ app.CurrentProject.PreprocessedData.PR],DetectedSpectra{i},'BAND',30,'WEIGHTS',[1 1]);
                [j,k] = samplealign([currentCMZ app.CurrentProject.PreprocessedData.PR],DetectedSpectra{i});
                PA(j,i) = DetectedSpectra{i}(k,2);
            end

            cla(app.Binning_AlignedPeakBinningPlot);
            app.Binning_AlignedPeakBinningPlot.XLim = [app.CurrentProject.RawData.MinIntensity app.CurrentProject.RawData.MaxIntensity];
            
            if isempty(app.Detection_SpectrumtodisplayEditField.Value)
                hold (app.Binning_AlignedPeakBinningPlot, "on");
                box (app.Binning_AlignedPeakBinningPlot, "on");
                for i=1:length(currentCMZ)
                    xline(app.Binning_AlignedPeakBinningPlot,currentCMZ(i),'k');
                end
                plot(app.Binning_AlignedPeakBinningPlot,app.CurrentProject.RawData.RawMzValues,app.CurrentProject.PreprocessedData.NormalizedSpectra)
                plot(app.Binning_AlignedPeakBinningPlot,currentCMZ,PA,'o')
            else
                index = str2num(app.Detection_SpectrumtodisplayEditField.Value);
                hold (app.Binning_AlignedPeakBinningPlot, "on");
                box (app.Binning_AlignedPeakBinningPlot, "on");
                for i=1:length(currentCMZ)
                    xline(app.Binning_AlignedPeakBinningPlot,currentCMZ(i),'k');
                end
                plot(app.Binning_AlignedPeakBinningPlot,app.CurrentProject.RawData.RawMzValues,app.CurrentProject.PreprocessedData.NormalizedSpectra(:,index))
                plot(app.Binning_AlignedPeakBinningPlot,currentCMZ,PA(:,index),'o')
            end
            
            app.CurrentProject.PreprocessedData.AlignedDetectedPeak = PA;
        end
        
        function startPeakBinning(app)
            
            app.CurrentProject.PreprocessedData.BinningMethod = app.Binning_BinningMethod.Value;
            app.CurrentProject.PreprocessedData.BinningMaxPeaks = app.Binning_NumberofBinsSpinner.Value;
            app.CurrentProject.PreprocessedData.BinningTolerance = app.Binning_ToleranceEditField.Value;
            edgeList = generateBins(app.CurrentProject.PreprocessedData.CMZ, app.CurrentProject.PreprocessedData.BinningMaxPeaks,...
                app.CurrentProject.PreprocessedData.BinningTolerance, app.CurrentProject.PreprocessedData.BinningMethod);
            app.CurrentProject.PreprocessedData.EdgeList = edgeList;
            
            if isempty(edgeList)
                app.CurrentProject.PreprocessedData.BinIndexList = [];
                app.CurrentProject.PreprocessedData.BinnedSpectra = [];
            else
                binnedData = generateBinsFromEdges(edgeList, app.CurrentProject.RawData.RawMzValues, app.CurrentProject.PreprocessedData.NormalizedSpectra);
                app.CurrentProject.PreprocessedData.BinIndexList = binnedData(:,1);
                binnedData(:,1) = [];
                app.CurrentProject.PreprocessedData.BinnedSpectra = binnedData;
            end
        end
        
        function startPeakBinningFromEdges(app)
            
            edgeList = app.CurrentProject.PreprocessedData.ImportedEdgeList;
            binnedData = generateBinsFromEdges(edgeList, app.CurrentProject.RawData.RawMzValues, app.CurrentProject.PreprocessedData.NormalizedSpectra);
            
            app.CurrentProject.PreprocessedData.BinIndexList = binnedData(:,1);
            binnedData(:,1) = [];

            app.CurrentProject.PreprocessedData.BinnedSpectra = binnedData;

            
        end
        
        function PeakBinningNextButton(app)   
            OutputArray = [app.CurrentProject.PreprocessedData.BinIndexList app.CurrentProject.PreprocessedData.BinnedSpectra];
            TransArr = transpose(OutputArray(1:end,2:end)); 
            app.PrePreocessedML = TransArr;
            [~,y] = size(app.PrePreocessedML);
            app.FeatureNumberEditField.Value = string(y); 
            app.ClassNameListBox.Items = app.Class(1:app.ClassNum);

        end
        
        
        %====================ML Preprocessing==============================
        function MLPrePos(app)
        %PrePreocessedML is transposed
        [x,y] = size(app.PrePreocessedML);
                    myCell = cell(x, y); 
                    
                    for j = 1:x 
                        for k = 1:y
                            myCell{j,k} = app.PrePreocessedML(j,k);
                        end
                    end
                                        
                    d = uiprogressdlg(app.MSPECAppUIFigure,'Title','Processing your data','Message','Please wait . . .','Indeterminate','on');
                    pause(0.2);
                    
           %New version of class label
           disp(app.Class)
           init = 1;
           final = 0;
           for i  = 1:app.ClassNum
                if app.Status(i) == "imported"
                    %disp("Test");
                    final = final + app.importedData.NumberOfSpectra(i);
                    for j = init:final
                    myCell{j,y+1} = app.Class(i);
                    end
                    init = final + 1;
                end
           end
           
           
           %{
                    %Label every class in one mixed file
                    if app.Status(1) == "Imported"
                       for i = 1:app.importedData1.NumberOfSpectra  
                         myCell{i,y+1} = app.Class(1);
                       end
                    end
                    
                    if app.Status(2) == "Imported" 
                        %disp("meow");
                        init = app.importedData1.NumberOfSpectra+1;
                        fin = app.importedData1.NumberOfSpectra + app.importedData2.NumberOfSpectra;
                        for i = init:fin 
                            myCell{i,y+1} = app.Class(2);
                        end
                    end
           
                    if app.Status(3) == "Imported"
                        init = fin+1;
                        fin = fin + app.importedData3.NumberOfSpectra;
                       for i = init:fin 
                            myCell{i,y+1} = app.Class(3);
                        end
                    end
                    if app.Status(4) == "Imported"
                        init = fin+1;
                        fin = fin + app.importedData4.NumberOfSpectra;
                       for i = init:fin 
                            myCell{i,y+1} = app.Class(4);
                        end
                    end
                    if app.Status(5) == "Imported"
                        init = fin+1;
                        fin = fin + app.importedData5.NumberOfSpectra;
                       for i = init:fin 
                            myCell{i,y+1} = app.Class(5);
                        end
                    end
                    if app.Status(6) == "Imported"
                        init = fin+1;
                        fin = fin + app.importedData6.NumberOfSpectra;
                       for i = init:fin 
                            myCell{i,y+1} = app.Class(6);
                        end
                    end
                    if app.Status(7) == "Imported"
                         init = fin+1;
                        fin = fin + app.importedData7.NumberOfSpectra;
                       for i = init:fin 
                            myCell{i,y+1} = app.Class(7);
                        end
                    end
                    if app.Status(8) == "Imported"
                        init = fin+1;
                        fin = fin + app.importedData8.NumberOfSpectra;
                       for i = init:fin 
                            myCell{i,y+1} = app.Class(8);
                        end
                    end
                    if app.Status(9) == "Imported"
                        init = fin+1;
                        fin = fin + app.importedData9.NumberOfSpectra;
                       for i = init:fin 
                            myCell{i,y+1} = app.Class(9);
                        end
                    end
                    if app.Status(10) == "Imported"
                        init = fin+1;
                        fin = fin + app.importedData10.NumberOfSpectra;
                       for i = init:fin 
                            myCell{i,y+1} = app.Class(10);
                        end
                    end
           %}

         app.DoneLabel.Visible = "on";
         
         %[~,y] = size(myCell);
         app.CellMLExport = myCell;
         ExportTable = cell2table(myCell);
         
         app.TableMLExport = ExportTable;
         disp(app.TableMLExport(1,:));
        end
        
        %=====================Split Data======================
        function SplitData(app)
            
            d = uiprogressdlg(app.MSPECAppUIFigure,'Title','Spliting your data','Message','Please wait . . .','Indeterminate','on');
                    pause(0.2);
            %Change to percentage
            app.TrainSetPer = app.TrainSetEditField.Value/100;
            app.TestSetPer = app.TestSetEditField.Value/100;
           %[x,y] = size(app.TableMLExport);
           [~,y] = size(app.CellMLExport);
           
           %init variable
           trainSpec = 0;
           testSpec = 0;

           %Sum up the spectrum number of trainset and testset
           %This new version works fine
           
           ClassTrain(1:app.ClassNum) = 0;
           ClassTest(1:app.ClassNum) = 0;
           
            for i  = 1:app.ClassNum
                if app.Status(i) == "imported"
                    %disp("Test");
                    ClassTrain(i) = ceil(app.importedData.NumberOfSpectra(i)*app.TrainSetPer);
                    ClassTest(i) = floor(app.importedData.NumberOfSpectra(i)*app.TestSetPer);
                    
                    trainSpec = trainSpec + ceil(app.importedData.NumberOfSpectra(i)*app.TrainSetPer);
                    testSpec = testSpec + floor(app.importedData.NumberOfSpectra(i)*app.TestSetPer);
                end
            end
           
           
           
          %{
                    if app.Status(1) == "Imported"
                       Class1Train = ceil(app.importedData1.NumberOfSpectra*app.TrainSetPer);
                       Class1Test = floor(app.importedData1.NumberOfSpectra*app.TestSetPer);
                       
                       trainSpec = ceil(app.importedData1.NumberOfSpectra*app.TrainSetPer);
                       testSpec =  floor(app.importedData1.NumberOfSpectra*app.TestSetPer);                     
                    end
                    if app.Status(2) == "Imported" 
                       Class2Train = ceil(app.importedData2.NumberOfSpectra*app.TrainSetPer);
                       Class2Test = floor(app.importedData2.NumberOfSpectra*app.TestSetPer);
                       
                       trainSpec = trainSpec + ceil(app.importedData2.NumberOfSpectra*app.TrainSetPer);
                       testSpec = testSpec + floor(app.importedData2.NumberOfSpectra*app.TestSetPer);
                    end
                    if app.Status(3) == "Imported"
                       Class3Train = ceil(app.importedData3.NumberOfSpectra*app.TrainSetPer);
                       Class3Test = floor(app.importedData3.NumberOfSpectra*app.TestSetPer);
                       
                       trainSpec = trainSpec + ceil(app.importedData3.NumberOfSpectra*app.TrainSetPer);
                       testSpec = testSpec + floor(app.importedData3.NumberOfSpectra*app.TestSetPer);
                    end
                    if app.Status(4) == "Imported"
                       Class4Train = ceil(app.importedData4.NumberOfSpectra*app.TrainSetPer);
                       Class4Test = floor(app.importedData4.NumberOfSpectra*app.TestSetPer);
                       
                       trainSpec = trainSpec + ceil(app.importedData4.NumberOfSpectra*app.TrainSetPer);
                       testSpec = testSpec + floor(app.importedData4.NumberOfSpectra*app.TestSetPer);
                    end
                    if app.Status(5) == "Imported"
                       Class5Train = ceil(app.importedData5.NumberOfSpectra*app.TrainSetPer);
                       Class5Test = floor(app.importedData5.NumberOfSpectra*app.TestSetPer);
                       
                       trainSpec = trainSpec + ceil(app.importedData5.NumberOfSpectra*app.TrainSetPer);
                       testSpec = testSpec + floor(app.importedData5.NumberOfSpectra*app.TestSetPer);
                    end
                    if app.Status(6) == "Imported"
                       Class6Train = ceil(app.importedData6.NumberOfSpectra*app.TrainSetPer);
                       Class6Test = floor(app.importedData6.NumberOfSpectra*app.TestSetPer);
                       
                       trainSpec = trainSpec + ceil(app.importedData6.NumberOfSpectra*app.TrainSetPer);
                       testSpec = testSpec + floor(app.importedData6.NumberOfSpectra*app.TestSetPer);
                    end
                    if app.Status(7) == "Imported"
                       Class7Train = ceil(app.importedData7.NumberOfSpectra*app.TrainSetPer);
                       Class7Test = floor(app.importedData7.NumberOfSpectra*app.TestSetPer);
                       
                       trainSpec = trainSpec + ceil(app.importedData7.NumberOfSpectra*app.TrainSetPer);
                       testSpec = testSpec + floor(app.importedData7.NumberOfSpectra*app.TestSetPer);  
                    end
                    if app.Status(8) == "Imported"
                       Class8Train = ceil(app.importedData8.NumberOfSpectra*app.TrainSetPer);
                       Class8Test = floor(app.importedData8.NumberOfSpectra*app.TestSetPer);
                       
                       trainSpec = trainSpec + ceil(app.importedData8.NumberOfSpectra*app.TrainSetPer);
                       testSpec = testSpec + floor(app.importedData8.NumberOfSpectra*app.TestSetPer);
                    end
                    if app.Status(9) == "Imported"
                        Class9Train = ceil(app.importedData9.NumberOfSpectra*app.TrainSetPer);
                       Class9Test = floor(app.importedData9.NumberOfSpectra*app.TestSetPer);
                       
                       trainSpec = trainSpec + ceil(app.importedData9.NumberOfSpectra*app.TrainSetPer);
                       testSpec = testSpec + floor(app.importedData9.NumberOfSpectra*app.TestSetPer);
                    end
                    if app.Status(10) == "Imported"
                       Class10Train = ceil(app.importedData10.NumberOfSpectra*app.TrainSetPer);
                       Class10Test = floor(app.importedData10.NumberOfSpectra*app.TestSetPer);
                       
                       trainSpec = trainSpec + ceil(app.importedData10.NumberOfSpectra*app.TrainSetPer);
                       testSpec = testSpec + floor(app.importedData10.NumberOfSpectra*app.TestSetPer);
                       
                    end
                    %}
                       %debug
                       TrainSet = cell(trainSpec,y);
                       TestSet = cell(testSpec,y);
                       disp("=========Data Dimension============");
                       disp("TeainSet:");
                       disp(size(TrainSet));
                       disp("TestSet");
                       disp(size(TestSet));
              TrainlastRow = 0;
              TestlastRow = 0;
              total = 0;
               %New version is find up until here
                for i  = 1:app.ClassNum
                    if app.Status(i) == "imported"
                       %disp("Test");
                       %Define last Row to split(Added with previous class)
                       TrainInit = TrainlastRow+1;
                       TestInit = TestlastRow+1;
                       TrainlastRow = TrainlastRow + ClassTrain(i);
                       TestlastRow = TestlastRow + ClassTest(i);
                       
                       temp = 0;
                       %TrainSet
                       for k = TrainInit:TrainlastRow
                           temp = temp +1;
                           for j = 1:y
                           %LastRowofClass:TrainlastRow = total++
                           TrainSet{k,j} = app.CellMLExport{total+temp,j};
                           end
                       end
                       temp = ClassTrain(i);
                       %TestSet
                       for k = TestInit:TestlastRow
                          temp = temp +1;
                          for j = 1:y
                          %Row TestInit:TestlastRow = (total+Class2Train)++
                          TestSet{k,j} = app.CellMLExport{total+temp,j};
                          end
                       end
                       %Update total spectra transferred
                       total = total + ClassTrain(i) + ClassTest(i);
                       
                     end
                end
               
               
               
               
               
               %{
                    %Split data from MLpreprocessed to TrainSet and TestSet
                    if app.Status(1) == "Imported"
                        %Define last Row to split
                        TrainlastRow = Class1Train;
                        TestlastRow = Class1Test;
                       %TainSet
                       for i = 1:TrainlastRow
                          for j = 1:y
                           TrainSet{i,j} = app.CellMLExport{i,j}; 
                          end
                       end
                       %TestSet
                       for i = 1:TestlastRow
                           for j = 1:y
                           TestSet{i,j} = app.CellMLExport{TrainlastRow+i,j};
                           end
                       end
                       %Update total spectra transferred
                       total = Class1Train+Class1Test;
                    end
                    
                    if app.Status(2) == "Imported" 
                       %Define last Row to split(Added with previous class)
                       TrainInit = TrainlastRow+1;
                       TestInit = TestlastRow+1;
                       TrainlastRow = TrainlastRow + Class2Train;
                       TestlastRow = TestlastRow + Class2Test;
                       %temp define to increase row number by 1
                       temp = 0;
                       %TrainSet
                       for i = TrainInit:TrainlastRow
                           temp = temp +1;
                           for j = 1:y
                           %LastRowofClass:TrainlastRow = total++
                           TrainSet{i,j} = app.CellMLExport{total+temp,j};
                           end
                       end
                       temp = Class2Train;
                       %TestSet
                       for i = TestInit:TestlastRow
                          temp = temp +1;
                          for j = 1:y
                          %Row TestInit:TestlastRow = (total+Class2Train)++
                          TestSet{i,j} = app.CellMLExport{total+temp,j};
                          end
                       end
                       %Update total spectra transferred
                       total = total + Class2Train + Class2Test;
                    end
                    %Check point: Correct check and No error upuntil here 
                    
                    
                    if app.Status(3) == "Imported"
                       %Define last Row to split(Added with previous class)
                       TrainInit = TrainlastRow+1;
                       TestInit = TestlastRow+1;
                       TrainlastRow = TrainlastRow + Class3Train;
                       TestlastRow = TestlastRow + Class3Test;
                       
                       %temp define to increase row number by 1
                       temp = 0;
                       %TrainSet
                       for i = TrainInit:TrainlastRow
                           temp = temp+1;
                           for j = 1:y
                           %LastRowofClass:TrainlastRow = total++
                           TrainSet{i,j} = app.CellMLExport{total+temp,j};
                           end
                       end
                       temp = Class3Train;
                       %TestSet
                       for i = TestInit:TestlastRow
                          temp = temp +1;
                          for j = 1:y
                          %Row TestInit:TestlastRow = (total+Class2Train)++
                          TestSet{i,j} = app.CellMLExport{total+temp,j};
                          end
                       end
                       %Update total spectra transferred
                       total = total + Class3Train + Class3Test;
                    end
                    if app.Status(4) == "Imported"
                       %Define last Row to split(Added with previous class)
                       TrainInit = TrainlastRow+1;
                       TestInit = TestlastRow+1;
                       TrainlastRow = TrainlastRow + Class4Train;
                       TestlastRow = TestlastRow + Class4Test;
                       
                       %temp define to increase row number by 1
                       temp = 0;
                       %TrainSet
                       for i = TrainInit:TrainlastRow
                           temp = temp+1;
                           for j = 1:y
                           %LastRowofClass:TrainlastRow = total++ 
                           TrainSet{i,j} = app.CellMLExport{total+temp,j};
                           end
                       end
                       temp = Class4Train;
                       %TestSet
                       for i = TestInit:TestlastRow
                          temp = temp +1;
                          for j = 1:y
                          %Row TestInit:TestlastRow = (total+Class2Train)++
                          TestSet{i,j} = app.CellMLExport{total+temp,j};
                          end
                       end
                       %Update total spectra transferred
                       total = total + Class4Train + Class4Test;
                    end
                    if app.Status(5) == "Imported"
                       %Define last Row to split(Added with previous class)
                       TrainInit = TrainlastRow+1;
                       TestInit = TestlastRow+1;
                       TrainlastRow = TrainlastRow + Class5Train;
                       TestlastRow = TestlastRow + Class5Test;
                       
                       %temp define to increase row number by 1
                       temp = 0;
                       %TrainSet
                       for i = TrainInit:TrainlastRow
                           temp = temp+1;
                           for j = 1:y
                           %LastRowofClass:TrainlastRow = total++ 
                           TrainSet{i,j} = app.CellMLExport{total+temp,j};
                           end
                       end
                       temp = Class5Train;
                       %TestSet
                       for i = TestInit:TestlastRow
                          temp = temp +1;
                          for j = 1:y
                          %Row TestInit:TestlastRow = (total+Class2Train)++
                          TestSet{i,j} = app.CellMLExport{total+temp,j};
                          end
                       end
                       %Update total spectra transferred
                       total = total + Class5Train + Class5Test;
                    end
                    if app.Status(6) == "Imported"
                        %Define last Row to split(Added with previous class)
                       TrainInit = TrainlastRow+1;
                       TestInit = TestlastRow+1;
                       TrainlastRow = TrainlastRow + Class6Train;
                       TestlastRow = TestlastRow + Class6Test;
                       
                       %temp define to increase row number by 1
                       temp = 0;
                       %TrainSet
                       for i = TrainInit:TrainlastRow
                           temp = temp+1;
                           for j = 1:y
                           %LastRowofClass:TrainlastRow = total++
                           TrainSet{i,j} = app.CellMLExport{total+temp,j};
                           end
                       end
                       temp = Class6Train;
                       %TestSet
                       for i = TestInit:TestlastRow
                          temp = temp +1;
                          for j = 1:y
                          %Row TestInit:TestlastRow = (total+Class2Train)++
                          TestSet{i,j} = app.CellMLExport{total+temp,j};
                          end
                       end
                       %Update total spectra transferred
                       total = total + Class6Train + Class6Test;
                       
                    end
                    if app.Status(7) == "Imported"
                       %Define last Row to split(Added with previous class)
                       TrainInit = TrainlastRow+1;
                       TestInit = TestlastRow+1;
                       TrainlastRow = TrainlastRow + Class7Train;
                       TestlastRow = TestlastRow + Class7Test;
                       
                       %temp define to increase row number by 1
                       temp = 0;
                       %TrainSet
                       for i = TrainInit:TrainlastRow
                           temp = temp+1;
                           for j = 1:y
                           %LastRowofClass:TrainlastRow = total++
                           TrainSet{i,j} = app.CellMLExport{total+temp,j};
                           end
                       end
                       temp = Class7Train;
                       %TestSet
                       for i = TestInit:TestlastRow
                          temp = temp +1;
                          for j = 1:y
                          %Row TestInit:TestlastRow = (total+Class2Train)++
                          TestSet{i,j} = app.CellMLExport{total+temp,j};
                          end
                       end
                       %Update total spectra transferred
                       total = total + Class6Train + Class7Test;
                      
                    end
                    if app.Status(8) == "Imported"
                     %Define last Row to split(Added with previous class)
                       TrainInit = TrainlastRow+1;
                       TestInit = TestlastRow+1;
                       TrainlastRow = TrainlastRow + Class8Train;
                       TestlastRow = TestlastRow + Class8Test;
                       
                       %temp define to increase row number by 1
                       temp = 0;
                       %TrainSet
                       for i = TrainInit:TrainlastRow
                           temp = temp+1;
                           for j = 1:y
                           %LastRowofClass:TrainlastRow = total++
                           TrainSet{i,j} = app.CellMLExport{total+temp,j};
                           end
                       end
                       temp = Class8Train;
                       %TestSet
                       for i = TestInit:TestlastRow
                          temp = temp +1;
                          for j = 1:y
                          %Row TestInit:TestlastRow = (total+Class2Train)++
                          TestSet{i,j} = app.CellMLExport{total+temp,j};
                          end
                       end
                       %Update total spectra transferred
                       total = total + Class8Train + Class8Test;
                      
                    end
                    if app.Status(9) == "Imported"
                        
                         %Define last Row to split(Added with previous class)
                       TrainInit = TrainlastRow+1;
                       TestInit = TestlastRow+1;
                       TrainlastRow = TrainlastRow + Class9Train;
                       TestlastRow = TestlastRow + Class9Test;
                       
                       %temp define to increase row number by 1
                       temp = 0;
                       %TrainSet
                       for i = TrainInit:TrainlastRow
                           temp = temp+1;
                           for j = 1:y
                           %LastRowofClass:TrainlastRow = total++
                           TrainSet{i,j} = app.CellMLExport{total+temp,j};
                           end
                       end
                       temp = Class9Train;
                       %TestSet
                       for i = TestInit:TestlastRow
                          temp = temp +1;
                          for j = 1:y
                          %Row TestInit:TestlastRow = (total+Class2Train)++
                          TestSet{i,j} = app.CellMLExport{total+temp,j};
                          end
                       end
                       %Update total spectra transferred
                       total = total + Class9Train + Class9Test;
                        
                    end
                    if app.Status(10) == "Imported"
                       %Define last Row to split(Added with previous class)
                       TrainInit = TrainlastRow+1;
                       TestInit = TestlastRow+1;
                       TrainlastRow = TrainlastRow + Class10Train;
                       TestlastRow = TestlastRow + Class10Test;
                       
                       %temp define to increase row number by 1
                       temp = 0;
                       %TrainSet
                       for i = TrainInit:TrainlastRow
                           temp = temp+1;
                           for j = 1:y
                           %LastRowofClass:TrainlastRow = total++
                           TrainSet{i,j} = app.CellMLExport{total+temp,j};
                           end
                       end
                       temp = Class10Train;
                       %TestSet
                       for i = TestInit:TestlastRow
                          temp = temp +1;
                          for j = 1:y
                          %Row TestInit:TestlastRow = (total+Class2Train)++
                          TestSet{i,j} = app.CellMLExport{total+temp,j};
                          end
                       end
                       %Update total spectra transferred
                       total = total + Class10Train + Class10Test;
                    end
                    %}
            %debug
            disp(total)
            %Transform cell to table
            train = cell2table(TrainSet);
            test = cell2table(TestSet);
            % disp("==========================")
           
            [x,~] = size(train); % save to work space and check the output
            [x1,~] = size(test); % save to work space and check the output
   
            app.TrainSetNumberofSpectraEditField.Value = x;
            app.TestSetNumberofSpectraEditField.Value = x1;
            %disp("test")
            app.Normalization_DataTable_2.Data = train;
            app.Normalization_DataTable_3.Data = test;
            
            %Store data to app
            app.TrainSet = train;
            app.TestSet = test;
 
        end
        
            
    end
end

