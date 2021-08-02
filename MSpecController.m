classdef MSpecController
    
    properties
    end
    
    methods (Static)
        
        function initAppFromFiles(app)
            d = uiprogressdlg(app.MSPECAppUIFigure,'Title','Loading your project information','Message','Please wait . . .','Indeterminate','on');
            drawnow
            
            prj = app.CurrentProject;
            tempTab = app.ImportTab;

            
            if ~isempty(prj.PreprocessedData.AlignedSpectra)
                % PreProcessing Part
                Visualization.plotRawMSData(app);
                % set UI parameters
                app.Preprocessing_WindowSizeEditField.Value = prj.PreprocessedData.WindowSize; %window size
                app.Preprocessing_StepsizeEditField.Value = prj.PreprocessedData.StepSize; %step size
                app.Preprocessing_QuantilevalueEditField.Value = prj.PreprocessedData.QuantileValue; %quantile value

                app.Preprocessing_ReferenceSpectrumEditField.Value = prj.PreprocessedData.ReferenceSpectrum; %alignment refernce spectrum
                app.Preprocessing_MinimumsegementsizeallowedEditField.Value = prj.PreprocessedData.SegmentSize; %alignment segment size
                app.Preprocessing_MaximumshiftallowedEditField.Value = prj.PreprocessedData.ShiftAllowance; %alignment shift alowance

                app.Preprocessing_SpectrumtodisplayEditField.Value = num2str(prj.PreprocessedData.DisplayingSpectra); %spectra to display
                app.Preprocessing_StartingpointEditField.Value = num2str(prj.PreprocessedData.SectionStart); %starting point of section of interest
                app.Preprocessing_EndingpointEditField.Value = num2str(prj.PreprocessedData.SectionEnd); %ending point of section of interest

                % Plotpreprocessed
                Visualization.plotPreprocessedMSData(app);
                app.Export_PreprocessingCheckBox.Enable = 'on';
                app.Export_PreprocessingCheckBox.Value = true;
                app.PreprocessingCheckBox.Enable = 'on';
                app.PreprocessingCheckBox.Value = true;
                tempTab = app.PreprocessingTab;
            end
            
            % Normalization
            if ~isempty(prj.PreprocessedData.NormalizedSpectra)
                % load parameters to UI
                currentOption = prj.PreprocessedData.NormalizeMethod;
                app.Normalization_pvalueSpinner.Enable = false;
                switch currentOption
                    case 'Sum'
                        app.NormalizationMethodsButtonGroup.SelectedObject = app.Normalization_ioncountsButton;
                    case 'Norm'
                        app.NormalizationMethodsButtonGroup.SelectedObject = app.Normalization_pnormButton;
                        app.Normalization_pvalueSpinner.Enable = true;
                        app.Normalization_pvalueSpinner.Value = prj.PreprocessedData.NormalizationNormValue;
                    case 'Median'
                        app.NormalizationMethodsButtonGroup.SelectedObject = app.Normalization_MedianButton;
                    case 'Noise'
                        app.NormalizationMethodsButtonGroup.SelectedObject = app.Normalization_NoiseLevelButton;
                    otherwise
                        app.NormalizationMethodsButtonGroup.SelectedObject = app.Normalization_ReferencePeakButton;
                end
                
                option = prj.PreprocessedData.NormalizeDisplay;
                app.Normalization_SamplePointSpinner.Enable = false;
                app.Normalization_SelectDataTable.Enable = 'off';
                switch option
                    case 'All'
                        app.ViewOptionButtonGroup.SelectedObject = app.Normalization_AllSpectraButton;
                    case 'Single'
                        app.ViewOptionButtonGroup.SelectedObject = app.Normalization_SingleSpectrumButton;
                        app.Normalization_SamplePointSpinner.Enable = true;
                    otherwise
                        app.ViewOptionButtonGroup.SelectedObject = Normalization_MultipleSpectraButton;
                        app.Normalization_SelectDataTable.Enable = 'on';
                end
                         
                Visualization.plotRawMSData_Normalization(app);
                MSpecController.DisplaySamplePointOption(app);
                Preprocessing.updateNormalizedSpectra(app);
                Visualization.plotNormalizedSpectra(app);
                Visualization.displayNormalizedDataTable(app);
                app.Export_NormalizationCheckBox.Enable = 'on';
                app.Export_NormalizationCheckBox.Value = true;
                app.NormalizationCheckBox.Enable = 'on';
                app.NormalizationCheckBox.Value = true;
                tempTab = app.NormalizationTab;
            end
            
            % Peak Detect
            if ~isempty(prj.PreprocessedData.CutThresholdPeak)
                %UI
                if (prj.PreprocessedData.IsAutoDetected)
                    app.Detection_MethodDropDown.Value = 'Auto';
                else
                    app.Detection_MethodDropDown.Value = 'Self Adjustments';
                    app.Detection_BASEEditField.Value = prj.PreprocessedData.Base;
                    app.Detection_MULTIPLIEREditField.Value = prj.PreprocessedData.Multiplier;
                    app.Detection_HEIGHTFILTEREditField.Value = prj.PreprocessedData.HeightFilter;
                    app.Detection_PeakThresholdEditField.Value = prj.PreprocessedData.PeakThreshold;
                end
                Visualization.plotPeakDetection(app);
                tempTab = app.PeakDetectionTab;
            end
            
            % Peak Detect2
            if ~isempty(prj.PreprocessedData.CMZ)
                Visualization.plotPeakBinning_Hierachical(app);
                app.CUTOFFSpinner.Value = prj.PreprocessedData.Cutoff;
                app.Export_PeakDetectionCheckBox.Enable = 'on';
                app.Export_PeakDetectionCheckBox.Value = true;
                app.PeakDetectionCheckBox.Enable = 'on';
                app.PeakDetectionCheckBox.Value = true;
                tempTab = app.PeakDetectionTab;
            end
            
            if ~isempty(prj.PreprocessedData.AlignedDetectedPeak)
                Visualization.plotAlignedPeak(app);
                tempTab = app.PeakDetectionTab;
            end
            
            if ~isempty(prj.PreprocessedData.BinnedSpectra)
                app.Binning_BinningMethod.Value = app.CurrentProject.PreprocessedData.BinningMethod;
                app.Binning_NumberofBinsSpinner.Value = app.CurrentProject.PreprocessedData.BinningMaxPeaks;
                app.Binning_ToleranceEditField.Value = app.CurrentProject.PreprocessedData.BinningTolerance;
                
                switch app.CurrentProject.PreprocessedData.IsImportedEdge
                case true
                    app.Binning_ImportEdgeButton.Enable = true;
                    app.Binning_BinningMethod.Enable = false;
                    app.Binning_NumberofBinsSpinner.Enable = false;
                    app.Binning_ToleranceEditField.Enable = false;
                otherwise
                    app.Binning_ImportEdgeButton.Enable = false;
                    app.Binning_BinningMethod.Enable = true;
                    app.Binning_NumberofBinsSpinner.Enable = true;
                    app.Binning_ToleranceEditField.Enable = true;
                end
            
                option = prj.PreprocessedData.BinningDisplay;
                switch option
                    case 'All'
                        app.Binning_ViewOptionButtonGroup.SelectedObject = app.Binning_AllSpectraButton;
                    case 'Single'
                        app.Binning_ViewOptionButtonGroup.SelectedObject = app.Binning_SingleSpectrumButton;
                        app.Binning_SamplePointSpinner.Enable = true;
                    otherwise
                        app.Binning_ViewOptionButtonGroup.SelectedObject = app.Binning_MultipleSpectraButton;
                        app.Binning_SelectDataTable.Enable = 'on';
                end
                MSpecController.Binning_displaySamplePointOption(app)
                Visualization.plotBinningEdgeList(app);
                Visualization.displayBinDataTable(app);
                app.Export_PeakBinningCheckBox.Enable = 'on';
                app.Export_PeakBinningCheckBox.Value = true;
                app.PeakBinningCheckBox.Enable = 'on';
                app.PeakBinningCheckBox.Value = true;
                Visualization.plotBinningSpectra(app);
                tempTab = app.PeakBinningTab;
            end
            
            % Others UI Setting
            app.Normalization_SamplePointSpinner.Limits = [1 app.CurrentProject.RawData.NumberOfSpectra];
            app.Binning_SamplePointSpinner.Limits = [1 app.CurrentProject.RawData.NumberOfSpectra];
            app.ProjectInfo_ProjectNameEditField.Value = app.CurrentProject.ProjectName;
            app.ProjectInfo_ImportedFileEditField.Value = app.CurrentProject.RawData.FileName;
            app.ProjectInfo_CreatedDate.Value = datestr(app.CurrentProject.CreatedDate);
            app.ProjectInfo_DescriptionTextArea.Value = app.CurrentProject.Description;
            app.TabGroup.SelectedTab = tempTab;
            
            close(d);
        end
        
        function getRecentFiles(app)
            currentFolder = pwd;
            % where MS projects are stored
            directory = strcat(currentFolder,'.\projects');
            MyFolderInfo = dir(fullfile(directory,'*.mat'));
            [numFile,~] = size(MyFolderInfo);
            fileNameList = {};
            for i = 1:numFile
                fileNameList{end+1} = MyFolderInfo(i).name(1:end-4);
            end
            app.RecentFileListBox.Items = fileNameList;
        end
        
        function loadRecentFiles(app)
            selectedFile = app.RecentFileListBox.Value;
            Location = pwd;
            dir = '\projects';
            Location = strcat(Location,dir);
            FileName = strcat(selectedFile,'.mat');
            loadedData = load(fullfile(Location, FileName));
            app.CurrentProject = loadedData.ProjectData;
            
            %=========IMPORTANT================
            MSpecController.initAppFromFiles(app);
        end
        
        function initProjectInfo(app)
            app.ProjectInfo_ProjectNameEditField.Value = app.CurrentProject.ProjectName;
            app.ProjectInfo_ImportedFileEditField.Value = app.CurrentProject.RawData.FileName;
            app.ProjectInfo_CreatedDate.Value = datestr(app.CurrentProject.CreatedDate);
            app.ProjectInfo_DescriptionTextArea.Value = app.CurrentProject.Description;
        end
        
        function requestExit(app)
            projectName = app.CurrentProject.ProjectName;            
            Location = pwd; 
            ProjectData = app.CurrentProject;
            dir = '\projects';
            Location = strcat(Location,dir);
            FileName = strcat(projectName,'.mat');
            
            msg = ['Want to save your changes to "',FileName,'" ?'];
            title = 'MSpec';
            selection = uiconfirm(app.MSPECAppUIFigure,msg,title,...
                    'Options',{'Save and Exit','Exit without Saving','Cancel'},...
                    'DefaultOption',1,'CancelOption',3);
                if selection == "Save and Exit"
                    save(fullfile(Location, projectName), 'ProjectData');
                    delete(app);
                elseif selection == "Exit without Saving"
                    selection = uiconfirm(app.MSPECAppUIFigure,'Close document?','Confirm Close without saving',...
                        'Icon','warning');
                    if selection == "OK"
                        delete(app);
                    else
                        % do nothing
                    end
                else
                    % do nothing
                end
            
        end
        
        function saveProject(app)
            projectName = app.CurrentProject.ProjectName;            
            Location = pwd; 
            ProjectData = app.CurrentProject;
            dir = '\projects';
            Location = strcat(Location,dir);
            FileName = strcat(projectName,'.mat');

            % if the file already exists then just save
            if exist(fullfile(Location, FileName), 'file')
                % File exists.  Do stuff....
                msg = 'Saving these changes will overwrite previous changes.';
                title = 'Confirm Save';
                selection = uiconfirm(app.MSPECAppUIFigure,msg,title,...
                    'Options',{'Overwrite','Save as new','Cancel'},...
                    'DefaultOption',1,'CancelOption',3);
                if selection == "Overwrite"
                    save(fullfile(Location, projectName), 'ProjectData');
                elseif selection == "Save as new"
                    % create new project to be done later
                else
                    % do nothing
                    uiconfirm(app.MSPECAppUIFigure,'Your project is not saved.','Cancel','Options',{'OK'},'Icon','error');
                end
            else
                % File does not exist.
                save(fullfile(Location, projectName), 'ProjectData');
                msg = sprintf('Your project has been saved to %s',Location);
                selection = uiconfirm(app.MSPECAppUIFigure,msg,'Saved Sucessfully','Options',{'OK'},'Icon','success');
                if selection == "OK"
                    % do nothing
                end
            end 
        end
        
        function saveChanges(app)
            d = uiprogressdlg(app.MSPECAppUIFigure,'Title','Saving',...
            'Indeterminate','on');
            drawnow
            projectName = app.CurrentProject.ProjectName;            
            Location = pwd; 
            ProjectData = app.CurrentProject;
            dir = '\projects';
            Location = strcat(Location,dir);
            FileName = strcat(projectName,'.mat');
            save(fullfile(Location, FileName), 'ProjectData');
            close(d);
        end
        
        function saveAs(app)
            originalProjectName = app.CurrentProject.ProjectName;            
            prompt = {'Enter a new project name'};
            dlgtitle = 'New Project';
            definput = {originalProjectName};
            dims = [1 40];
            answer = inputdlg(prompt,dlgtitle,dims,definput);
            
            if ~isempty(answer)
                projectName = answer{1};
                Location = pwd;
                dir = '\projects';
                Location = strcat(Location,dir);
                FileName = strcat(projectName,'.mat');

                % if the file already exists then deny
                if exist(fullfile(Location, FileName), 'file')
                    msg = 'Saving these changes will overwrite previous files.';
                    title = 'Project already exists';
                    selection = uiconfirm(app.MSPECAppUIFigure,msg,title,...
                        'Options',{'Overwrite','Cancel'},...
                        'DefaultOption',1,'CancelOption',2);
                    if selection == "Overwrite"
                        app.CurrentProject.ProjectName = answer{1};
                        ProjectData = app.CurrentProject;
                        save(fullfile(Location, projectName), 'ProjectData');
                    else
                        % do nothing
                        uiconfirm(app.MSPECAppUIFigure,'Your project is not saved.','Cancel','Options',{'OK'},'Icon','error');
                    end
                else
                % File does not exist.
                    app.CurrentProject.ProjectName = answer{1};
                    ProjectData = app.CurrentProject;
                    save(fullfile(Location, projectName), 'ProjectData');
                    msg = sprintf('Your project has been saved to %s',Location);
                    selection = uiconfirm(app.MSPECAppUIFigure,msg,'Saved Sucessfully','Options',{'OK'},'Icon','success');
                    if selection == "OK"
                        % do nothing
                    end
                end 
            end
        end
        
        function plotButtonPushedHandler(app)
            
            d = uiprogressdlg(app.MSPECAppUIFigure,'Title','Processing your data','Message','Please wait . . .','Indeterminate','on');
            drawnow
            
            try
    
                % Do the SVD computation

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

                % close the dialog box

                Visualization.plotPreprocessedMSData(app);
                
                % for proj info part
                
                app.Export_PreprocessingCheckBox.Enable = 'on';
                app.Export_PreprocessingCheckBox.Value = true;
                app.PreprocessingCheckBox.Enable = 'on';
                app.PreprocessingCheckBox.Value = true;
                MSpecController.initNormalization(app);

            catch
            	errordlg('Please re-adjust the parameters','Something went wrong');
            end
            close(d)
        end
        
        function initNormalization(app)
            Visualization.plotRawMSData_Normalization(app);
            MSpecController.DisplaySamplePointOption(app);
            Preprocessing.updateNormalizedSpectra(app);
        end
        
        function updateNormalizedSpectra(app)
            d = uiprogressdlg(app.MSPECAppUIFigure,'Title','Processing your data','Message','Please wait . . .','Indeterminate','on');
            drawnow
            Preprocessing.updateNormalizedSpectra(app);
            Visualization.plotNormalizedSpectra(app);
            Visualization.displayNormalizedDataTable(app);
            % Info
            app.Export_NormalizationCheckBox.Enable = 'on';
            app.Export_NormalizationCheckBox.Value = true;
            app.NormalizationCheckBox.Enable = 'on';
            app.NormalizationCheckBox.Value = true;
            close(d)
        end
        
        
        function DisplaySamplePointOption(app)
            SampleIndex = transpose(1:app.CurrentProject.RawData.NumberOfSpectra);
            F = false(app.CurrentProject.RawData.NumberOfSpectra,1);
            F = [SampleIndex F];
            app.Normalization_SelectDataTable.Data = F;
            app.Normalization_SelectDataTable.ColumnFormat = {'char', 'logical'};
            s = uistyle('HorizontalAlignment','center');
            addStyle(app.Normalization_SelectDataTable,s);
        end
        
        function startPeakDetection(app)
            d = uiprogressdlg(app.MSPECAppUIFigure,'Title','Detecting Peaks',...
            'Indeterminate','on');
            
            CurrentPreprocessedData = app.CurrentProject.PreprocessedData;
            value = app.Detection_MethodDropDown.Value;
            switch value % Get Tag of selected object.
                case 'Auto'
                    CurrentPreprocessedData.IsAutoDetected = true;
                otherwise
                    CurrentPreprocessedData.IsAutoDetected = false;
                    CurrentPreprocessedData.Base = app.Detection_BASEEditField.Value;
                    CurrentPreprocessedData.Multiplier = app.Detection_MULTIPLIEREditField.Value;
                    CurrentPreprocessedData.HeightFilter = app.Detection_HEIGHTFILTEREditField.Value;
                    CurrentPreprocessedData.PeakThreshold = app.Detection_PeakThresholdEditField.Value;
            end
            
            Preprocessing.peakDetection(app);
            Visualization.plotPeakDetection(app);
            close(d);
        end
        
        function startPeakBinning(app)
            d = uiprogressdlg(app.MSPECAppUIFigure,'Title','Processing your data','Message','Please wait . . .','Indeterminate','on');
            app.CurrentProject.PreprocessedData.Cutoff = app.CUTOFFSpinner.Value;
            try
                %put here the code that might fail
                Preprocessing.peakBinning_Hierachical(app);
                app.TotalnoofcommonpeaksEditField.Value = length(app.CurrentProject.PreprocessedData.CMZ);
                % Info
                app.Export_PeakDetectionCheckBox.Enable = 'on';
                app.Export_PeakDetectionCheckBox.Value = true;
                app.PeakDetectionCheckBox.Enable = 'on';
                app.PeakDetectionCheckBox.Value = true;
            catch
                %do something if error occurs
                errordlg('Please re-adjust the parameters for peak detection.','Something went wrong');
            end
        end
        
        function startAlignPeakBinning(app)
           d = uiprogressdlg(app.MSPECAppUIFigure,'Title','Processing your data','Message','Please wait . . .','Indeterminate','on');
           Preprocessing.peakBinning_Dynamic(app); 
        end
        
        function startRealPeakBinning(app)
            
            switch app.Binning_ImportEdgesCheckBox.Value
                case true % use imported Edge
                    if app.Binning_FileLabel.Text == "Choose File . . ." % users not yet import the file
                        % error window
                        msg = 'No Edges Imported';
                        errordlg('Please import the file first',msg);
                    else
                        d = uiprogressdlg(app.MSPECAppUIFigure,'Title','Generating Peak Bins','Message','Please wait . . .','Indeterminate','on');
                        drawnow
            
                        Preprocessing.startPeakBinningFromEdges(app); % Find Edges and Bin data
                        %Visualization.plotBinningEdgeList(app);
                        Visualization.plotBinningSpectra(app);
                        MSpecController.Binning_displaySamplePointOption(app);
                        Visualization.displayBinDataTable(app);
                        %UI
                        app.Export_PeakBinningCheckBox.Enable = 'on';
                        app.Export_PeakBinningCheckBox.Value = true;
                        app.PeakBinningCheckBox.Enable = 'on';
                        app.PeakBinningCheckBox.Value = true;
                        
                        app.CurrentProject.PreprocessedData.IsImportedEdge = true;
                     
                        close(d);
                    end
                otherwise % use parameters
                    Preprocessing.startPeakBinning(app); % Find Edges and Bin data
                    if isempty(app.CurrentProject.PreprocessedData.EdgeList)
                        msg = 'No Edges found.';
                        errordlg('Please re-adjust the parameters and try again',msg);
                    else
                        d = uiprogressdlg(app.MSPECAppUIFigure,'Title','Generating Peak Bins','Message','Please wait . . .','Indeterminate','on');
                        drawnow
                        Visualization.plotBinningEdgeList(app);
                        Visualization.plotBinningSpectra(app);
                        MSpecController.Binning_displaySamplePointOption(app);
                        Visualization.displayBinDataTable(app);
                        %UI
                        app.Export_PeakBinningCheckBox.Enable = 'on';
                        app.Export_PeakBinningCheckBox.Value = true;
                        app.PeakBinningCheckBox.Enable = 'on';
                        app.PeakBinningCheckBox.Value = true;
                        close(d);
                    end
            end
            
        end
        
        function Binning_displaySamplePointOption(app)
            SampleIndex = transpose(1:app.CurrentProject.RawData.NumberOfSpectra);
            F = false(app.CurrentProject.RawData.NumberOfSpectra,1);
            F = [SampleIndex F];
            app.Binning_SelectDataTable.Data = F;
            app.Binning_SelectDataTable.ColumnFormat = {'char', 'logical'};
            s = uistyle('HorizontalAlignment','center');
            addStyle(app.Binning_SelectDataTable,s);
        end
        
        function Binning_updateBinningPlot(app)
            Visualization.plotBinningSpectra(app);
        end
        
        
    end
end

