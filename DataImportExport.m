classdef DataImportExport
    
    properties
    end
    
    methods (Static)
        %pick purpose of preprocessing app
        function PickDataPurpose(app,selectedButton)
            if selectedButton == app.DataPreprocessingButton
                app.CreateNewPreprocessingProjectPanel.Enable = 'on';  
                app.Panel_6.Enable = 'off'; 
                app.Panel_2.Enable = 'off'; 
            end
            if selectedButton == app.DataforMLModelingButton
                  app.CreateNewPreprocessingProjectPanel.Enable = 'off';  
                  app.Panel_6.Enable = 'on'; 
                  app.Panel_2.Enable = 'off'; 
            end
        end
        
        function importData(app)
            try
            if isempty(app.CurrentProject)
                d = uiprogressdlg(app.MSPECAppUIFigure,'Title','Please Wait',...
                    'Message','Opening the import window');
                pause(.5)
                [file,path] = uigetfile('*.csv*');
                [~, ~, fExt] = fileparts(file);
                fileName = fullfile(path,file);
                switch lower(fExt)
                  case '.ods'
                    d.Value = .33; 
                    d.Message = 'Loading your data';
                    pause(1)
                    RawImportData=xlsread(fileName);
                  case '.csv'	
                    d.Value = .33; 
                    d.Message = 'Loading your data';
                    pause(1)
                    RawImportData=readmatrix(fileName);
                  otherwise  % Under all circumstances SWITCH gets an OTHERWISE!
                    %error('Unexpected file extension: %s', fExt);
                    % display error message
                    msgbox('Please input CSV files')
                    app.ImportStatusLabel.FontColor = [0.6902 0.2549 0.2549];
                    app.ImportStatusLabel.Text = 'The file must be in .csv format';
                    close(d)
                end
                app.ImportStatusLabel.FontColor = [0.1333 0.4588 0.1137];
                app.ImportStatusLabel.Text = [file,' has been imported successfully !'];
                %end

                % Perform calculations
                % ...
                d.Value = .67;
                d.Message = 'Processing the data';
                pause(1)

                %RawImportData(1,:)=[];
                RawMzValues=RawImportData(:,1);
                [x,y] = size(RawImportData);
                RawSpectraIntensities=zeros(x,y);
                for i = 2:y
                    RawSpectraIntensities(:,i)  = RawImportData(:,i);
                end
                RawSpectraIntensities(:,1)=[];
                % MinIntensity = min(RawMzValues);
                % MaxIntensity = max(RawMzValues);
                [m,n] = size(RawSpectraIntensities);
                NumberOfSpectra = n;

                % Finish calculations
                % ...
                d.Value = 1;
                d.Message = 'Finishing';
                pause(1)

                importedMSData = MSData(fileName,RawImportData,RawMzValues,RawSpectraIntensities,NumberOfSpectra, m , n);
                DataImportExport.initProjectInfo(app,importedMSData);
                app.CurrentProject = MSProject(importedMSData);
           
                
                % Close dialog box
                close(d)
            else
                % Make current instance of app invisible
                % app.MSPECAppUIFigure.Visible = 'off';
                % Open 2nd instance of app
                
                % Delete old instance
                status = close(app.MSPECAppUIFigure); %Thanks to Guillaume for suggesting to use close() rather than delete()
                
                if status ~= 0
                    newapp = MSpecMainApp();  % <--------------The name of your app
                    DataImportExport.importData(newapp);
                end
            end
            catch
            end
        end
        
        function initProjectInfo(app, MSData)
            %Check the purpose of the data
            [~, fName, ~] = fileparts(MSData.FileName);
            app.ProjectNameEditField.Value = fName;
            app.NumberofMassSpectraEditField.Value = MSData.NumberOfSpectra;
            app.WidthField.Value = 1;
            app.HeightField.Value = MSData.NumberOfSpectra;
            app.Normalization_SamplePointSpinner.Limits = [1 MSData.NumberOfSpectra];
            app.Binning_SamplePointSpinner.Limits = [1 MSData.NumberOfSpectra];
            app.WidthField.Editable = 'off';
            app.HeightField.Editable = 'off';
            app.Import_CreateProjectButton.Enable = true;
            
            
        end
        
        function width = calculateWidth (numberOfSpectra, height)
            width = numberOfSpectra/height;
        end
        
        function createProject (app)
            d = uiprogressdlg(app.MSPECAppUIFigure,'Title','Creating Your Project','Message','Please wait . . .','Indeterminate','on');
            app.CurrentProject.setProjectInfo(app.ProjectNameEditField.Value,app.DescriptionEditField.Value);
            app.CurrentProject.RawData.RowNumber = app.WidthField.Value;
            app.CurrentProject.RawData.ColumnNumber = app.HeightField.Value;
            app.TabGroup.SelectedTab = app.PreprocessingTab;
            
            %Init Raw Data Plot
            Visualization.plotRawMSData(app);
            MSpecController.initProjectInfo(app);
        end
        
        function calculateCol(app)
            userinput = app.WidthField.Value;
            numspec = app.CurrentProject.RawData.NumberOfSpectra;
            if mod(numspec,userinput) ==0
            	colnumber = numspec/userinput;
                app.HeightField.Value = colnumber;
            else
                app.WidthField.Value = 1;
                app.HeightField.Value = numspec;
            end
        end
        
        function calculateRow(app)
            userinput = app.HeightField.Value;
            numspec = app.CurrentProject.RawData.NumberOfSpectra;
            if mod(numspec,userinput) ==0
            	rownumber = numspec/userinput;
                app.WidthField.Value = rownumber;
            else
                app.WidthField.Value = 1;
                app.HeightField.Value = numspec;
            end
        end
        
        function exportPreprocessedData(app)
            exportFileName = strcat(app.ProjectName,'_Preprocessed.csv');
            [file,path] = uiputfile(exportFileName);
            filename = fullfile(path,file);
            %Arr = transpose(0:app.RowNumber-1);
            OutputArray = [app.CurrentProject.RawData.RawMzValues app.CurrentProject.PreprocessedData.BaselinedSpectra];
            csvwrite(filename,OutputArray);
        end
        
        function exportNormalizedData(app)
            exportFileName = strcat(app.ProjectName,'_Normalized.csv');
            [file,path] = uiputfile(exportFileName);
            filename = fullfile(path,file);
            %Arr = transpose(0:app.RowNumber-1);
            OutputArray = [app.CurrentProject.RawData.RawMzValues app.CurrentProject.PreprocessedData.NormalizedSpectra];
            if file ~= 0
                csvwrite(filename,OutputArray);
            end
        end
        
        function exportDetectedPeak(app)
            exportFileName = strcat(app.ProjectName,'_Detected.xls');
            [file,path] = uiputfile(exportFileName);
            filename = fullfile(path,file);
            for i = 1:app.CurrentProject.RawData.NumberOfSpectra
                writematrix(app.CurrentProject.PreprocessedData.CutThresholdPeak{i},filename,'Sheet',i);
            end
            %writematrix(OutputArray, filename); 
        end
        
        function exportCMZ(app)
            exportFileName = strcat(app.ProjectName,'_CMZ.csv');
            [file,path] = uiputfile(exportFileName);
            filename = fullfile(path,file);
            OutputArray = [app.CurrentProject.PreprocessedData.CMZ];
            csvwrite(filename,OutputArray);
        end
        
        function exportBinnedData(app)
            exportFileName = strcat(app.ProjectName,'_Binned.csv');
            [file,path] = uiputfile(exportFileName);
            filename = fullfile(path,file);
            OutputArray = [app.CurrentProject.PreprocessedData.BinIndexList app.CurrentProject.PreprocessedData.BinnedSpectra];
            csvwrite(filename,OutputArray);
        end

        function exportBinEdges(app)
            exportFileName = strcat(app.ProjectName,'_BinEdges.csv');
            [file,path] = uiputfile(exportFileName);
            fileName=fullfile(path,file);
            OutputArray = [app.CurrentProject.PreprocessedData.EdgeList];
            csvwrite(fileName,OutputArray);
        end
        
        function importBinEdges(app)
            [file,path] = uigetfile('*.csv*');
            fileName=fullfile(path,file);
            edgeList=readmatrix(fileName);
            app.Binning_FileLabel.Text = fileName;
            app.CurrentProject.PreprocessedData.ImportedEdgeList = edgeList;
        end
        
        function exportAllData(app)
            
            
            d = uiprogressdlg(app.MSPECAppUIFigure,'Title','Exporting your data','Message','Please wait . . .','Indeterminate','on');
            pause(0.2);
            
            exportFileName = strcat(app.ProjectName,'.zip');
            [file,path] = uiputfile(exportFileName);
            exportfilename = fullfile(path,file);
            mkdir tempFolder
            tempPath = './tempFolder/';

            exportFileList = {};
            % check if the checkbox is checked
            if app.Export_PreprocessingCheckBox.Value
                OutputArray = [app.CurrentProject.RawData.RawMzValues app.CurrentProject.PreprocessedData.BaselinedSpectra];
                fileName = strcat(tempPath,'Preprocessed.csv');
                writematrix(OutputArray, fileName); 
                exportFileList{end+1} = 'Preprocessed.csv';
            end
            
            if app.Export_NormalizationCheckBox.Value
                OutputArray = [app.CurrentProject.RawData.RawMzValues app.CurrentProject.PreprocessedData.NormalizedSpectra];
                fileName = strcat(tempPath,'Normalized.csv');
                writematrix(OutputArray, fileName); 
                exportFileList{end+1} = 'Normalized.csv';
            end
            
            %optimize this!!!
            if app.Export_PeakDetectionCheckBox.Value
                d.Message = 'Exporting Might Take a While...';
                fileName = strcat(tempPath,'DetectedPeak.xls');
                for i = 1:app.CurrentProject.RawData.NumberOfSpectra
                    writematrix(app.CurrentProject.PreprocessedData.CutThresholdPeak{i},fileName,'Sheet',i);
                end
                exportFileList{end+1} = 'DetectedPeak.xls';
                
                fileName = strcat(tempPath,'CMZ.csv');
                OutputArray = [app.CurrentProject.PreprocessedData.CMZ];
                writematrix(OutputArray, fileName); 
                exportFileList{end+1} = 'Normalized.csv';
            
            end

            
            if app.Export_PeakBinningCheckBox.Value
                OutputArray = [app.CurrentProject.PreprocessedData.BinIndexList app.CurrentProject.PreprocessedData.BinnedSpectra];
                fileName = strcat(tempPath,'BinnedData.csv');
                writematrix(OutputArray, fileName); 
                exportFileList{end+1} = 'BinnedData.csv';
                
                OutputArray = [app.CurrentProject.PreprocessedData.EdgeList];
                fileName = strcat(tempPath,'BinEdges.csv');
                writematrix(OutputArray, fileName); 
                exportFileList{end+1} = 'BinEdges.csv';
            end
            
            %new version edit here
            
            if app.Export_MLPreprocessingCheckBox_2.Value
                exportFileName = strcat(tempPath,'MLPreprocessed_Mixed.csv');
                OutputArray = app.TableMLExport;
                writetable(OutputArray,exportFileName,WriteVariableNames = false);
                exportFileList{end+1} = 'MLPreprocessed_Mixed.csv';
            end
            
            
            if app.Export_PreprocessingCheckBox_3.Value
                OutputArray1 = app.TrainSet;
                fileName = strcat(tempPath,'TrainSet.csv');
                writetable(OutputArray1, fileName,WriteVariableNames = false); 
                exportFileList{end+1} = 'TrainSet.csv';
                
                OutputArray2 = app.TestSet;
                fileName = strcat(tempPath,'TestSet.csv');
                writetable(OutputArray2, fileName,WriteVariableNames = false); 
                exportFileList{end+1} = 'TestSet.csv';
            end
            
            
            if isempty(exportFileList)
            	errordlg('Please select files to export.','Nothing Selected');
            else
                zip(exportfilename,exportFileList,tempPath);
            end
            %remove createdFolder
            rmdir tempFolder s
                
        end
        
        function exportPreprocessingSettings(app)
            exportFileName = strcat(app.CurrentProject.ProjectName,'_Settings.mat');
            [file,path] = uiputfile(exportFileName);
            
            startpt = app.Preprocessing_StartingpointEditField.Value;
            endpt = app.Preprocessing_EndingpointEditField.Value;
            
            %baseline
            
            winsize = app.Preprocessing_WindowSizeEditField.Value;
            stepsize = app.Preprocessing_StepsizeEditField.Value;
            quantile = app.Preprocessing_QuantilevalueEditField.Value;
            
            %align
            refspec = app.Preprocessing_ReferenceSpectrumEditField.Value;
            minseg = app.Preprocessing_MinimumsegementsizeallowedEditField.Value;
            maxshift = app.Preprocessing_MaximumshiftallowedEditField.Value;
            
            %Norm
            
            selectedButton = app.NormalizationMethodsButtonGroup.SelectedObject;
            app.Normalization_pvalueSpinner.Enable = false;
            switch selectedButton % Get Tag of selected object.
                case app.Normalization_ioncountsButton
                    norm='Sum';
                case app.Normalization_pnormButton
                    norm='Norm';
                case app.Normalization_MedianButton
                    norm='Median';
                case app.Normalization_NoiseLevelButton
                    norm='Noise';
                case app.Normalization_MaxIntensityButton
                    norm='Max';
                otherwise
                    norm='Peak';
            end
            normrefMZ = app.Normalization_ReferenceMZEditField.Value;
            normpvalue = app.Normalization_pvalueSpinner.Value;
             
            edgeList = app.CurrentProject.PreprocessedData.EdgeList;
            edgeListFileName =  strcat('Created by MSpec Preprocessing: ',app.CurrentProject.ProjectName);
             
            preprocessingSetting = PreprocessingParameters(startpt,endpt,winsize,stepsize,quantile,...
                 refspec,minseg,maxshift,norm,normrefMZ,normpvalue,edgeList,edgeListFileName);
                        
            save(fullfile(path,file),'preprocessingSetting');

        end
      
    end
end