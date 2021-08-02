classdef DataImportExportML
    
    properties   
    end
    
    methods (Static)

      function NextButtonHandler(app)
          app.ClassNum = app.ClassNumberSpinner.Value;
          for i = 1:app.ClassNum
              ClassList(i) = "Data Class " + int2str(i);
          end
          %ClassList = {'Data Class 1','Data Class 2','Data Class 3','Data Class 4','Data Class 5','Data Class 6','Data Class 7','Data Class 8','Data Class 9','Data Class 10'};
          for i = 1:app.ClassNum
                 app.ClassDropDown_2.Items = ClassList(1:i);
          end
          app.ProjectName = app.ProjectNameEditField_2.Value;
          app.ProjectDescription = app.DescriptionEditField_2.Value;
          app.Import_CreateProjectButton_4.Enable = 'off';
          app.Status(1:app.ClassNum) = "NotImported";
          
          try
           if app.Status(1:app.ClassNum) == "Imported"
                app.Import_CreateProjectButton_4.Enable = 'on';
           end
          catch
          end
          %disp(ClassList);
          
          %Create Class to store multiple classes
          app.importedData = StoreImportData(app.ClassNum);
          
          %Pre-allocate class name and status of each class
          app.Class(1:app.ClassNum) = "";
          app.Status(1:app.ClassNum) = "";
          app.importedData.DataType = app.DataTypesButtonGroup_4.SelectedObject;
          %disp(app.importedData);
      end
      
      
      function ProjectTitle(app,changingValue)
          
          %Name the project to allow next step
          if ~isempty(changingValue)
          app.Next_CreateProjectButton_2.Enable = 'on';
          end
          if isempty(changingValue)
          app.Next_CreateProjectButton_2.Enable = 'off';
          end
          
      end
          
        function importData(app)
            %global RawMlData
            
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
                app.ImportStatusLabel_3.FontColor = [0.1333 0.4588 0.1137];
                app.ImportStatusLabel_3.Text = [file,' has been imported successfully !'];

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

                
                    %===================================
                %Receive multiple data By return MSData ot multiple variables
                %One var is for all class together
                %every Spectrum number of every class should be recorded
                %for further ML pre-processing
                    %===================================
              
                %dataType = app.DataTypesButtonGroup_2.SelectedObject;

                Class = app.ClassDropDown_2.Value;
                %%%Rawdata = MLData(fileName,RawImportData,RawMzValues,RawSpectraIntensities,NumberOfSpectra, m , n);
                %%%DataImportExportML.initProjectInfo(app,Rawdata);
                [~, fName, ~] = fileparts(fileName);
                
                %Update import status of each data
                 
                for i = 1:app.ClassNum
                    %disp(Class);
                    if Class == "Data Class "+int2str(i)
                        app.importedData.FileName(i) = fName+".csv";
                        app.importedData.RawData{1,i} = RawImportData;
                        app.importedData.RawMzValues{1,i} = RawMzValues;
                        app.importedData.RawSpectraIntensities{1,i} = RawSpectraIntensities;
                        app.importedData.MinIntensity(i) = min(RawMzValues);
                        app.importedData.MaxIntensity(i) = max(RawMzValues);
                        app.importedData.NumberOfSpectra(i) = NumberOfSpectra;
                        app.importedData.RowNumber(i) = m;
                        app.importedData.ColumnNumber(i) = n;
                        app.Status(i) = "imported";
                    end
                end
                disp(app.importedData);
                              
                if app.Status(1:app.ClassNum) == "imported"
                    app.Import_CreateProjectButton_4.Enable = 'on';
                end
                

                DataImportExportML.initProjectInfo(app,app.importedData);
                %app.CurrentProject = MSProject(importedMLFinalData);
               
                
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
                    DataImportExportML.importData(newapp);
                    app.selectedButton = app.DataforMLModelPreprocessingButton;
                    app.CreateNewPreprocessingProjectPanel.Enable = 'off';  
                    app.CreateNewMLPreprocessingProjectPanel.Enable = 'on'; 
                end
            end
            catch
            end
        end
        
        
        function initProjectInfo(app, importedData)
             value = app.ClassDropDown_2.Value;
             for i = 1:app.ClassNum
                if value == "Data Class "+int2str(i)
                [~, fName, ~] = fileparts(importedData.FileName(i));
                %app.ClassNameEditField_2.Value = fName; %Previous version
                app.NumberofMassSpectraEditField_3.Value = importedData.NumberOfSpectra(i);
                app.WidthField_3.Value = 1;
                app.HeightField_3.Value = importedData.NumberOfSpectra(i);
              
                %===================================
                app.WidthField.Editable = 'off';
                app.HeightField.Editable = 'off';

                app.Import_CreateProjectButton.Enable = true;
                end
             end
            
        end    
        
        function MixData(app)
            d = uiprogressdlg(app.MSPECAppUIFigure,'Title','Creating Your Project','Message','Please wait . . .','Indeterminate','on');
            pass = true;
            ProjectName = app.ProjectName;
            
            temp1 = cell2mat(app.importedData.RawMzValues);
            temp = cell2mat(app.importedData.RawSpectraIntensities);%จริงๆไม่ได้ปัดค่าทิ้งแต่ถ้า disp มันจะโชว์ค่าปัด
            [x,y] = size(temp);
            RawImportTotalData(1:x,1) = temp1(1:x,1);
            RawImportTotalData(1:x,2:y+1) = temp(1:x,1:y);
            %disp(RawImportTotalData);
            
            %Check if all Class name filled or not
            for i = 1:app.ClassNum
                if app.Class(i) == ""
                   pass = false;
                end 
            end
            
                if pass
                RawMzValues=RawImportTotalData(:,1);
                [x,y] = size(RawImportTotalData);
                RawSpectraIntensities=zeros(x,y);
                for i = 2:y
                    RawSpectraIntensities(:,i)  = RawImportTotalData(:,i);
                end
                RawSpectraIntensities(:,1)=[];
                [m,n] = size(RawSpectraIntensities);
                NumberOfSpectra = n;
                RawTotalData = MSData(ProjectName,RawImportTotalData,RawMzValues,RawSpectraIntensities,NumberOfSpectra, m , n);
                RawTotalDataML = MLData(ProjectName,RawImportTotalData,RawMzValues,RawSpectraIntensities,NumberOfSpectra, m , n);
                
                app.importedMLData = RawTotalDataML(1:end,1:end);
                disp(app.importedMLData);
                %RawData = app.importedMLData;
                app.CurrentProject = MSProject(RawTotalData);  
                %app.Panel_2.Enable = 'off'; 
                app.ProjectInfo_ProjectNameEditField.Value = app.ProjectNameEditField_2.Value;
                
                app.Normalization_SamplePointSpinner.Limits = [1 NumberOfSpectra];
                app.Binning_SamplePointSpinner.Limits = [1 NumberOfSpectra];
                end
            
            app.CurrentProject.setProjectInfo(app.ProjectNameEditField.Value,app.DescriptionEditField.Value);
            app.CurrentProject.RawData.RowNumber = app.WidthField.Value;
            app.CurrentProject.RawData.ColumnNumber = app.HeightField.Value;
            
            %init ml prepos data
            app.ProjectNameLabel.Text = "Project Name: " + app.ProjectName;
            app.ClassNumberEditField.Value = int2str(app.ClassNum);
            app.TotalSpectraEditField.Value = int2str(NumberOfSpectra);

            
            
            %Init Raw Data Plot
            Visualization.plotRawMSData(app);
            MSpecController.initProjectInfo(app);
            
        end
        
        
        function width = calculateWidth (numberOfSpectra, height)
            width = numberOfSpectra/height;
        end
        
        function createProject (app)

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
        
        function exportDataforModel(app)
            
            exportFileName = strcat(app.ProjectName,'MLPreprocessed_Mixed.csv');
            [file,path] = uiputfile(exportFileName);
            filename = fullfile(path,file);
            OutputArray = app.TableMLExport;
            %TransArr = transpose(OutputArray(1:end,2:end));
            writetable(OutputArray,filename,WriteVariableNames = false);
        end
        
        function ExportSplitData(app)
            
              exportFileName = strcat(app.ProjectName,'_MLSplit_Data.zip');
            [file,path] = uiputfile(exportFileName);
            exportfilename = fullfile(path,file);
            mkdir tempFolder
            tempPath = './tempFolder/';

            MLexportFileList = {};
          
                OutputArray1 = app.TrainSet;
                fileName = strcat(tempPath,'TrainSet.csv');
                writetable(OutputArray1, fileName,WriteVariableNames = false); 
                MLexportFileList{end+1} = 'TrainSet.csv';
                
                OutputArray2 = app.TestSet;
                fileName = strcat(tempPath,'TestSet.csv');
                writetable(OutputArray2, fileName,WriteVariableNames = false); 
                MLexportFileList{end+1} = 'TestSet.csv';
                
                zip(exportfilename,MLexportFileList,tempPath);
            
                %remove createdFolder
                rmdir tempFolder s
            
        end
        

        function ExportAllMLData(app)
            
              exportFileName = strcat(app.ProjectName,'_MLPreprocessed_Data_All.zip');
            [file,path] = uiputfile(exportFileName);
            exportfilename = fullfile(path,file);
            mkdir tempFolder
            tempPath = './tempFolder/';

            MLexportFileList = {};
          
                OutputArray1 = app.TrainSet;
                fileName = strcat(tempPath,'MLPreprocessed_TrainSet.csv');
                writetable(OutputArray1, fileName,WriteVariableNames = false); 
                MLexportFileList{end+1} = 'MLPreprocessed_TrainSet.csv';
                
                OutputArray2 = app.TestSet;
                fileName = strcat(tempPath,'MLPreprocessed_TestSet.csv');
                writetable(OutputArray2, fileName,WriteVariableNames = false); 
                MLexportFileList{end+1} = 'MLPreprocessed_TestSet.csv';
                
                OutputArray3 = app.TableMLExport;
                fileName = strcat(tempPath,'MLPreprocessed_Mixed.csv');
                writetable(OutputArray3, fileName,WriteVariableNames = false); 
                MLexportFileList{end+1} = 'MLPreprocessed_Mixed.csv';
                 
                zip(exportfilename,MLexportFileList,tempPath);
            
                %remove createdFolder
                rmdir tempFolder s
        end
       
    end
end