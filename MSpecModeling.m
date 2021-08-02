classdef MSpecModeling
    
    properties
    end
    
    methods (Static)
        
        function importData(app)
            d = uiprogressdlg(app.MSPECAppUIFigure,'Title','Please Wait',...
                'Message','Opening the import window');
            pause(.5)
            [file,path] = uigetfile('*.csv*');
            [fPath, fName, fExt] = fileparts(file);
            fileName = fullfile(path,file)
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
                
                msgbox('Please input CSV files')
                app.ImportStatusLabel_4.FontColor = [0.6902 0.2549 0.2549];
                app.ImportStatusLabel_4.Text = 'The file must be in .csv format';
                close(d)
            end
            
            app.ImportStatusLabel_4.FontColor = [0.1333 0.4588 0.1137];
            app.ImportStatusLabel_4.Text = [fileName,' has been imported successfully !'];
            %end
            
            d.Value = .67;
            d.Message = 'Processing the data';
            pause(1)
            
            RawMzValues=RawImportData(:,1);
            [x,y] = size(RawImportData);
            RawSpectraIntensities=zeros(x,y);
            for i = 2:y
                RawSpectraIntensities(:,i)  = RawImportData(:,i);
            end
            RawSpectraIntensities(:,1)=[];
            [m,n] = size(RawSpectraIntensities);
            NumberOfSpectra = n;
            
            % Finish calculations
            % ...
            d.Value = 1;
            d.Message = 'Finishing';
            pause(1)
            
            importedMSData = MSData(fileName,RawImportData,RawMzValues,RawSpectraIntensities,NumberOfSpectra, m , n);
            MSpecModeling.initProjectInfo(app,importedMSData);
            app.ModelTest = MSAnalysisProject(importedMSData);

            % Close dialog box
            close(d)
        end
        
        function requestExit(app)
            projectName = app.CurrentProject.ProjectName;            
            Location = pwd; 
            ProjectData = app.CurrentProject;
            dir = '\analysis projects';
            Location = strcat(Location,dir);
            FileName = strcat(projectName,'.mat');
            
            msg = ['Want to save your changes to "',FileName,'" ?'];
            title = 'MSpec';
            selection = uiconfirm(app.MSpecAnalysisUIFigure,msg,title,...
                    'Options',{'Save and Exit','Exit without Saving','Cancel'},...
                    'DefaultOption',1,'CancelOption',3);
                if selection == "Save and Exit"
                    save(fullfile(Location, projectName), 'ProjectData','-v7.3');
                    delete(app);
                elseif selection == "Exit without Saving"
                    selection = uiconfirm(app.MSpecAnalysisUIFigure,'Close document?','Confirm Close without saving',...
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
        
        function initProjectInfo(app, MSData)
            [~, fName, ~] = fileparts(MSData.FileName);
            app.FileNameEditField.Value = fName;
            app.NumberofMassSpectraEditField_4.Value = MSData.NumberOfSpectra;
            app.WidthField_4.Value = 1;
            app.HeightField_4.Value = MSData.NumberOfSpectra;
            %app.WidthField.Editable = 'off';
            %app.HeightField.Editable = 'off';
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
        
        function createProject (app)

            app.ModelTest.RawData.RowNumber = app.WidthField.Value;
            app.ModelTest.RawData.ColumnNumber = app.HeightField.Value;
            %if app.Imaging2DButton.Value
             %   app.ModelTest.RawData.DataType = 'ms';
           % end
            %Init Classification Tab
            %MSpecModeling.displayProjectInfo(app);
           MSpecModeling.displayImportedDataTable(app);
    
        end
        
         function displayImportedDataTable(app)
            %app.NumberofMassSpectraEditField_2.Value = app.CurrentProject.RawData.NumberOfSpectra;
            %switch app.DataTypesButtonGroup.SelectedObject
                %case app.MassSpectra1DButton
                    %app.DataTypeButtonGroup.SelectedObject = app.MassSpectra1DButton_2;
                %otherwise
                    %app.DataTypeButtonGroup.SelectedObject = app.Imaging2DButton_2;
            %end
            %app.WidthField_2.Value = app.CurrentProject.RawData.RowNumber;
            %app.HeightField_2.Value = app.CurrentProject.RawData.ColumnNumber;
            %if app.CurrentProject.RawData.DataType == "imaging"
                %app.DataTypeButtonGroup.SelectedObject = app.Imaging2DButton_2;
            %else
               % app.DataTypeButtonGroup.SelectedObject = app.MassSpectra1DButton_2;
           % end
            
            %Table
            tdata = table(app.ModelTest.RawData.RawMzValues,app.ModelTest.RawData.RawSpectraIntensities,'VariableNames',{'M/Z','Spectrum'});
            
            app.ImportedDataTable.Data = tdata;
            app.ImportedDataTable.ColumnName = tdata.Properties.VariableNames;
            s = uistyle('HorizontalAlignment','center');
            addStyle(app.ImportedDataTable,s);

        end
  
        function displayProjectInfo(app)
            app.ProjectInfo_ProjectNameEditField.Value = app.CurrentProject.ProjectName;
            app.ProjectInfo_ImportedFileEditField.Value = app.CurrentProject.RawData.FileName;
            app.ProjectInfo_CreatedDate.Value = datestr(app.CurrentProject.CreatedDate);
            app.ProjectInfo_DescriptionTextArea.Value = app.CurrentProject.Description;
        end
        
        
        function saveChanges(app)
            d = uiprogressdlg(app.MSpecAnalysisUIFigure,'Title','Saving',...
            'Indeterminate','on');
            drawnow
            projectName = app.CurrentProject.ProjectName;            
            Location = pwd; 
            ProjectData = app.CurrentProject;
            dir = '\analysis projects';
            Location = strcat(Location,dir);
            FileName = strcat(projectName,'.mat');
            save(fullfile(Location, FileName), 'ProjectData', '-v7.3');
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
                dir = '\analysis projects';
                Location = strcat(Location,dir);
                FileName = strcat(projectName,'.mat');

                % if the file already exists then deny
                if exist(fullfile(Location, FileName), 'file')
                    msg = 'Saving these changes will overwrite previous files.';
                    title = 'Project already exists';
                    selection = uiconfirm(app.MSpecAnalysisUIFigure,msg,title,...
                        'Options',{'Overwrite','Cancel'},...
                        'DefaultOption',1,'CancelOption',2);
                    if selection == "Overwrite"
                        app.CurrentProject.ProjectName = answer{1};
                        ProjectData = app.CurrentProject;
                        save(fullfile(Location, projectName), 'ProjectData', '-v7.3');
                    else
                        % do nothing
                        uiconfirm(app.MSpecAnalysisUIFigure,'Your project is not saved.','Cancel','Options',{'OK'},'Icon','error');
                    end
                else
                % File does not exist.
                    app.CurrentProject.ProjectName = answer{1};
                    ProjectData = app.CurrentProject;
                    save(fullfile(Location, projectName), 'ProjectData', '-v7.3');
                    msg = sprintf('Your project has been saved to %s',Location);
                    selection = uiconfirm(app.MSpecAnalysisUIFigure,msg,'Saved Sucessfully','Options',{'OK'},'Icon','success');
                    if selection == "OK"
                        % do nothing
                    end
                end 
            end
        end
        
        
        
        function retrieveModelTypes(app)
            
            t = app.ModelTypeTree;
            
            % First level nodes
            KNN = app.KNEARESTNEIGHBORKNNNode;
            % Second level nodes.
            knndir = '.\models\KNN\';
            KNNFolderInfo = dir(fullfile(knndir,'*.mat'));
            [numFile,~] = size(KNNFolderInfo);
            for i = 1:numFile
                uitreenode(KNN,'Text',KNNFolderInfo(i).name(1:end-4),'NodeData',[strcat(knndir,KNNFolderInfo(i).name)]);
            end
            
            SVM = app.SUPPORTVECTORMACHINESSVMNode;
            svmdir = '.\models\SVM\';
            SVMFolderInfo = dir(fullfile(svmdir,'*.mat'));
            [numFile,~] = size(SVMFolderInfo);
            for i = 1:numFile
                uitreenode(SVM,'Text',SVMFolderInfo(i).name(1:end-4),'NodeData',[strcat(svmdir,SVMFolderInfo(i).name)]);
            end
            
            DT = app.DECISIONTREESNode;
            dtdir = '.\models\Decision Tree\';
            DTFolderInfo = dir(fullfile(dtdir,'*.mat'));
            [numFile,~] = size(DTFolderInfo);
            for i = 1:numFile
                uitreenode(DT,'Text',DTFolderInfo(i).name(1:end-4),'NodeData',[strcat(dtdir,DTFolderInfo(i).name)]);
            end
            
            NB = app.NAIVEBAYESCLASSIFIERSNode;
            nbdir = '.\models\Naive Bayes\';
            NBFolderInfo = dir(fullfile(nbdir,'*.mat'));
            [numFile,~] = size(NBFolderInfo);
            for i = 1:numFile
                uitreenode(NB,'Text',NBFolderInfo(i).name(1:end-4),'NodeData',[strcat(nbdir,NBFolderInfo(i).name)]);
            end
            
            Ensem = app.ENSEMBLEBaggedTreeNode;
            endir = '.\models\Ensemble\';
            EnsFolderInfo = dir(fullfile(endir,'*.mat'));
            [numFile,~] = size(EnsFolderInfo);
            for i = 1:numFile
                uitreenode(Ensem,'Text',EnsFolderInfo(i).name(1:end-4),'NodeData',[strcat(endir,EnsFolderInfo(i).name)]);
            end
            
            LDA = app.LINEARDISCRIINANTANALYSISLDANode;
            ldadir = '.\models\LDA\';
            LDAFolderInfo = dir(fullfile(ldadir,'*.mat'));
            [numFile,~] = size(LDAFolderInfo);
            for i = 1:numFile
                uitreenode(LDA,'Text',LDAFolderInfo(i).name(1:end-4),'NodeData',[strcat(ldadir,LDAFolderInfo(i).name)]);
            end
            
            % Expand the tree
            expand(t);
        end
        
        function retrieveModelInfo(app)
            selectedNodes = app.ModelTypeTree.SelectedNodes;
            filename = selectedNodes.NodeData;
            infodir = strcat(filename(1:end-4),'.txt');
            
            fid = fopen(infodir,'r');

            info = textscan(fid, '%s', 'whitespace', '', 'delimiter', ';');

            app.ModelInfoTextArea.Value = info{1};
        end
        
        function mdl = retrieveModel(app)
            selectedNodes = app.ModelTypeTree.SelectedNodes;
            filename = selectedNodes.NodeData;
            mdldir = strcat(filename(1:end-4),'.mat');
            
            mdl = load(mdldir);
        end
        
        function importModel(app)
            [file,path] = uigetfile('*.mat*');
            fileName=fullfile(path,file);
            model=load(fileName);
            app.ImportedModel = model;
            app.ModelFileLabel.Text = [fileName,' has been imported successfully !'];
            app.ModelFileLabel.FontColor = [0.1333 0.4588 0.1137];

            app.ModelNameEditField.Enable = true;
            app.ModelNameEditField.Value = fileName(1:end-4);

            app.ModelTypeDropDown.Enable = true;
            app.ModelDescriptionLabel.Enable = true;
            app.NextButton.Enable = true;
            app.ModelDescriptionTextArea.Enable = true;

        end
        
        function importBinEdges(app)
            handles.filename = uigetfile('*.csv*');
            fileName=handles.filename;
            edgeList=readmatrix(fileName);
            app.Binning_FileLabel.Text = fileName;
            app.ImportedEdgeListFileName = fileName;
            app.ImportedEdgeList = edgeList;
            app.ImportModelButton.Enable = true;
            [~,num] = size(edgeList);
            app.NoofBinsEditField.Value = num;
        end
        
        function setPreprocessParam(app)
            
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
             
            edgeList = app.ImportedEdgeList;
            edgeListFileName =  app.ImportedEdgeListFileName;
             
            app.PreprocessingSetting = PreprocessingParameters(startpt,endpt,winsize,stepsize,quantile,...
                 refspec,minseg,maxshift,norm,normrefMZ,normpvalue,edgeList,edgeListFileName);

        end
        
        function importModelToApp(app)
            
            modelName = app.ModelNameEditField.Value;
            description = string(app.ModelDescriptionTextArea.Value);
            toSavePath = app.ToImportPath; 
            
            if isempty(description)
                description = 'Model Imported By Users';
            end
            
            fileName = strcat(modelName,'.txt');
            fullFileName = strcat(toSavePath,fileName);
            % write model description to txt file
            fid = fopen(fullFileName, 'wt');
            fprintf(fid,'%s\n', description);
            fclose(fid);
            
            MSpecAnalysisController.setPreprocessParam(app); % collect data
            
            model = ClassificationModel(modelName, app.ImportedModel,app.PreprocessingSetting);
            modelFileName = strcat(modelName,'.mat');
            modelfullFileName = strcat(toSavePath,modelFileName);
            save(modelfullFileName,'model');
            
        end
        
        function loadPreprocessParameters(app)
            selectedModel = MSpecAnalysisController.retrieveModel(app);
            app.CurrentProject.ClassificationModelName = selectedModel.model.ModelName;
            app.CurrentProject.ClassificationModel = selectedModel.model.Model;
            app.CurrentProject.PreprocessParameters = selectedModel.model.Preprocessing;
        end
        
        function setupModelType(app)
            selectedNodes = app.ModelTypeTree.SelectedNodes;
            switch selectedNodes.Parent
                case app.KNEARESTNEIGHBORKNNNode
                    app.CurrentProject.ClassificationModelType = 'KNN';
                case app.SUPPORTVECTORMACHINESSVMNode
                    app.CurrentProject.ClassificationModelType = 'SVM';
                case app.DECISIONTREESNode
                    app.CurrentProject.ClassificationModelType = 'Decision Tree';
                case app.NAIVEBAYESCLASSIFIERSNode
                    app.CurrentProject.ClassificationModelType = 'Naive Bayes';
                case app.ENSEMBLEBaggedTreeNode
                    app.CurrentProject.ClassificationModelType = 'Ensemble';
                case app.LINEARDISCRIINANTANALYSISLDANode
                    app.CurrentProject.ClassificationModelType = 'LDA';
                otherwise
            end
        end
        
        function parametersToUI(app)
            params = app.CurrentProject.PreprocessParameters;
            
            % set UI parameters
            app.Preprocessing_WindowSizeEditField.Value = params.WindowSize; %window size
            app.Preprocessing_StepsizeEditField.Value = params.StepSize; %step size
            app.Preprocessing_QuantilevalueEditField.Value = params.QuantileValue; %quantile value

            app.Preprocessing_ReferenceSpectrumEditField.Value = params.ReferenceSpectrum; %alignment refernce spectrum
            app.Preprocessing_MinimumsegementsizeallowedEditField.Value = params.SegmentSize; %alignment segment size
            app.Preprocessing_MaximumshiftallowedEditField.Value = params.ShiftAllowance; %alignment shift alowance

            app.Preprocessing_StartingpointEditField.Value = num2str(params.SectionStart); %starting point of section of interest
            app.Preprocessing_EndingpointEditField.Value = num2str(params.SectionEnd); %ending point of section of interest
            
            app.NumberofBinsEditField.Value = length(params.ImportedEdgeList)+1;
            MSpecAnalysisController.DisplaySamplePointOption(app);
        
        end
        
        function DisplaySamplePointOption(app)
            SampleIndex = transpose(1:app.CurrentProject.RawData.NumberOfSpectra);
            F = false(app.CurrentProject.RawData.NumberOfSpectra,1);
            F = [SampleIndex F];
            app.Binning_SelectDataTable.Data = F;
            app.Binning_SelectDataTable.ColumnFormat = {'char', 'logical'};
            s = uistyle('HorizontalAlignment','center');
            addStyle(app.Binning_SelectDataTable,s);
            app.Binning_SamplePointSpinner.Limits = [1 app.CurrentProject.RawData.NumberOfSpectra];
        end
        
        function startPreprocessing(app)
            d = uiprogressdlg(app.MSpecAnalysisUIFigure,'Title','Initializing the Preprocessing',...
            'Indeterminate','on');
            drawnow
            
            % LOAD and STORE PARAM from the model
            MSpecAnalysisController.loadPreprocessParameters(app);
            MSpecAnalysisController.setupModelType(app);
            % set UI params
            MSpecAnalysisController.parametersToUI(app);
            app.TabGroup.SelectedTab = app.PreprocessingTab;
            % Do preprocessing
            MSpecAnalysisController.preprocessing(app);
            % Plot
            AnalysisVisualization.plotPreprocessedData(app);
            
            close(d)
        end
        
        function startWithoutPreprocessing(app)
            d = uiprogressdlg(app.MSpecAnalysisUIFigure,'Title','Preparing features',...
            'Indeterminate','on');
            drawnow
            % LOAD and STORE PARAM from the model
            MSpecAnalysisController.loadPreprocessParameters(app);
            MSpecAnalysisController.setupModelType(app);
            % set UI params
            MSpecAnalysisController.parametersToUI(app);
            app.TabGroup.SelectedTab = app.PreprocessingTab;
            % Do preprocessing
            MSpecAnalysisController.skipPreprocessing(app);
            close(d)

        end
        
        
        function preprocessing(app)
            rawData = app.CurrentProject.RawData;
            params = app.CurrentProject.PreprocessParameters;

            preprocessedData = PreprocessedMSAData();
            
            % start
            MSpecAnalysisController.alignment(rawData,params,preprocessedData);
            MSpecAnalysisController.baselineCorrection(rawData, preprocessedData, params);
            MSpecAnalysisController.normalizeSpectra(rawData, preprocessedData, params);
            MSpecAnalysisController.startPeakBinningFromEdges(rawData, preprocessedData, params);
            
            app.CurrentProject.PreprocessedData = preprocessedData;
        end
        
        function skipPreprocessing(app)
            rawData = app.CurrentProject.RawData;
            params = app.CurrentProject.PreprocessParameters;

            preprocessedData = PreprocessedMSAData();
            preprocessedData.PreprocessedSpectra = rawData.RawSpectraIntensities;

            % start
            MSpecAnalysisController.startPeakBinningFromEdges(rawData, preprocessedData, params);
            app.CurrentProject.PreprocessedData = preprocessedData;
        end
        
        function alignment(rawData,params,preprocessedData)
            sample = rawData.RawSpectraIntensities;
            spectra = transpose(sample);
            reference = spectra(params.ReferenceSpectrum,:);
            segSize = params.SegmentSize;
            shift = params.ShiftAllowance;
            
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
                        MSpecAnalysisController.findMin(preprocessedData,samseg,refseg);
                        minpos = preprocessedData.MinPosition;
                        endpos = startpos+minpos+segSize;
                        samseg = spectra(i,startpos:endpos);
                        refseg = reference(1,startpos:endpos);
                    end
                    MSpecAnalysisController.FFTcorr(preprocessedData,samseg,refseg,shift);
                    lag = preprocessedData.SegmentLag;
                    MSpecAnalysisController.move(preprocessedData,samseg,lag);
                    aligned = [aligned preprocessedData.ShiftedSegment];
                    startpos=endpos+1;
                end
                preprocessedData.PreprocessedSpectra(i,:) = aligned;
            end
        end
        
        function FFTcorr(preprocessedData,spectrum, target, shift)
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
            preprocessedData.SegmentLag = lag;
        end

        function move(preprocessedData, seg, lag)
            
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
            preprocessedData.ShiftedSegment = movedSeg;
        end
        
        function findMin(preprocessedData, samseg,refseg)
        
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
            preprocessedData.MinPosition = Is(1,1);
        end
        
        function baselineCorrection(rawData, preprocessedData, params)
            baselined = msbackadj(rawData.RawMzValues,transpose(preprocessedData.PreprocessedSpectra),'STEPSIZE', params.StepSize,...
                'WINDOWSIZE', params.WindowSize,'QuantileValue',params.QuantileValue,'SmoothMethod','lowess');        
            baselined = max(baselined,0);
            preprocessedData.PreprocessedSpectra = mslowess(rawData.RawMzValues,baselined);
        end
        
        function normalizeSpectra(rawData, preprocessedData, params)
            % Data Normalization
                
            NormalizedSpectra = preprocessedData.PreprocessedSpectra;
            numberOfSpectra = rawData.NumberOfSpectra;
            
            switch params.NormalizeMethod % Get Tag of selected object.
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
                    idx = params.ReferencePeakIndex;
                    for j = 1:numberOfSpectra
                        ref = NormalizedSpectra(idx,j);
                        NormalizedSpectra(:, j) = NormalizedSpectra(:, j)./ref;
                    end
            end
            preprocessedData.PreprocessedSpectra = NormalizedSpectra;
        end
        
        function startPeakBinningFromEdges(rawData, preprocessedData, params)
            
            edgeList = params.ImportedEdgeList;
            binnedData = generateBinsFromEdges(edgeList, rawData.RawMzValues, preprocessedData.PreprocessedSpectra);
            
            preprocessedData.BinIndexList = binnedData(:,1);
            binnedData(:,1) = [];
            preprocessedData.BinnedSpectra = binnedData;

            
        end
        
        function initAppFromFiles(app)
           
            
            prj = app.CurrentProject;
            tempTab = app.ClassificationTab;

            AnalysisVisualization.displayImportedDataTable(app);

            if ~isempty(prj.ClassificationModel)
                switch prj.ClassificationModelType
                    case 'KNN'
                    case 'SVM'
                        SVM = app.SUPPORTVECTORMACHINESSVMNode;
                        children = SVM.Children;
                    case 'Decision Tree'
                    case 'Naive Bayes'
                    case 'Ensemble'
                    case 'LDA'
                end
                for i=1:length(children)
                    if children(i).Text == string(app.CurrentProject.ClassificationModelName)
                        app.ModelTypeTree.SelectedNodes = children(i);
                    end
                end
                MSpecAnalysisController.retrieveModelInfo(app);
            end
            if ~isempty(prj.PreprocessedData.PreprocessedSpectra)
            	AnalysisVisualization.plotPreprocessedData(app);
                MSpecAnalysisController.parametersToUI(app)
                tempTab = app.PreprocessingTab;
            end
            
            if ~isempty(prj.PredictionResult)
            	AnalysisVisualization.displayPredictionResult(app);
                AnalysisVisualization.displayScoreTable(app,app.CurrentProject.ScoreMatrix,app.CurrentProject.ClassNames);
                AnalysisVisualization.findClassPercentage(app);
                tempTab = app.ResultsTab;
            end
         
         
            % Others UI Setting
            MSpecAnalysisController.displayProjectInfo(app);
            app.TabGroup.SelectedTab = tempTab;
            
        end
        
                
    end
end

