classdef TestModelVisualization
    
    properties
    end
    
    methods (Static)
        
        function displayImportedDataTable(app)
            app.NumberofMassSpectraEditField_2.Value = app.CurrentProject.RawData.NumberOfSpectra;
            switch app.DataTypesButtonGroup.SelectedObject
                case app.MassSpectra1DButton
                    app.DataTypeButtonGroup.SelectedObject = app.MassSpectra1DButton_2;
                otherwise
                    app.DataTypeButtonGroup.SelectedObject = app.Imaging2DButton_2;
            end
            app.WidthField_2.Value = app.CurrentProject.RawData.RowNumber;
            app.HeightField_2.Value = app.CurrentProject.RawData.ColumnNumber;
            if app.CurrentProject.RawData.DataType == "imaging"
                app.DataTypeButtonGroup.SelectedObject = app.Imaging2DButton_2;
            else
                app.DataTypeButtonGroup.SelectedObject = app.MassSpectra1DButton_2;
            end
            
            %Table
            tdata = table(app.CurrentProject.RawData.RawMzValues,app.CurrentProject.RawData.RawSpectraIntensities,'VariableNames',{'M/Z','Spectrum'});
            
            app.ImportedDataTable.Data = tdata;
            app.ImportedDataTable.ColumnName = tdata.Properties.VariableNames;
            s = uistyle('HorizontalAlignment','center');
            addStyle(app.ImportedDataTable,s);

        end
        
        function plotPreprocessedData(app)
            cla(app.PreprocessedDataPlot)
            app.PreprocessedDataPlot.XLim = [app.CurrentProject.RawData.MinIntensity app.CurrentProject.RawData.MaxIntensity];
            data = app.CurrentProject.PreprocessedData;
            
            switch app.BinningDisplay
                case 'All'
                    bar(app.PreprocessedDataPlot,data.BinIndexList, data.BinnedSpectra);
                case 'Single'
                    bar(app.PreprocessedDataPlot,data.BinIndexList, data.BinnedSpectra(:, app.Binning_SamplePointSpinner.Value));
                case 'Multiple'
                    retreivedata = get(app.Binning_SelectDataTable,'data');
                    hold(app.PreprocessedDataPlot,"on");
                    for k = 1:length(retreivedata(:,2))
                        if retreivedata(k,2) == 1
                            bar(app.PreprocessedDataPlot,data.BinIndexList, data.BinnedSpectra(:, k));
                        end
                    end
                    hold(app.PreprocessedDataPlot,"off");
            end     
            
        end
        
        function displayPredictionResult(app)
            [x,y] = size(app.TestSet);
            sample = (1:x);
            sample = transpose(sample);
            disp(size(sample));
            disp(app.PredictionResult);
            t = table(sample,app.PredictionResult,app.TestSet{1:end,end},'VariableNames',{'Sample','Predicted Class','True Class'});
            app.ResultTable.Data = t;
            app.ResultTable.ColumnName = t.Properties.VariableNames;
            s = uistyle('HorizontalAlignment','center');
            addStyle(app.ResultTable,s,'table','');
            
            %Display Test Accurency
            X = app.TestSet{1:end,1:end-1};
            Y = app.TestSet{1:end,end};
            testLoss = loss(app.TrainedModel,X,Y);
            testAcc = 1 - testLoss;
            app.TestAccuracyPercentEditField.Value = testAcc*100;
            
            
        end
        
        function displayScoreTable(app, posterior,classNames)
            app.ScoreTable.RowName = 'numbered';
            app.ScoreTable.Data = posterior;
            app.ScoreTable.ColumnName = classNames;
            s = uistyle('HorizontalAlignment','center');
            addStyle(app.ScoreTable,s,'table','');
        end
        
        function findClassPercentage(app)
            labelsCat = categorical(app.PredictionResult);
            % find unique elements
            labels = categories(labelsCat);
            % count number
            labelCount = countcats(labelsCat);

            pie(app.PredictionResultPlot,labelCount);
            title(app.PredictionResultPlot,'Predicted Classes');
            
            legend(app.PredictionResultPlot,labels,'Location','bestoutside');

        end
        
        function plotConfusionMatrix(app,trueClass,predictedClass)
                    %classname = app.ClassNames;
                    predictedClass = string(predictedClass);
                    disp(predictedClass)
                    %[x,y] = size(trueClass);
                    confusionchart(trueClass,predictedClass)
            
        end
        
        function plotROC(app,label,score)
            temp = 0;
            for i = app.PositiveClassDropDown.Items
                temp = temp + 1;
                if string(i) == app.PositiveClassDropDown.Value
                    scores = score(1:end,temp);
                end
            end
           
            %scores = score(1:end,temp);
            if app.ClassNum <= 2
             [X,Y,T,AUC] = perfcurve(label, scores ,app.PositiveClassDropDown.Value); %Need to be adjust
             %(:,2) - score(:,1)
            else
             disp("More than 3 classes")
             [X,Y,T,AUC] = perfcurve(label,scores,app.PositiveClassDropDown.Value);
            end
             
             app.AUCEditField.Value = AUC;
             plot(app.UIAxes,X,Y);
        end
    end
end

