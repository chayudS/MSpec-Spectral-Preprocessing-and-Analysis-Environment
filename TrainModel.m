classdef TrainModel
    
    properties
    end
    
    methods (Static)
        
        function initInfo(app)
             d = uiprogressdlg(app.MSPECAppUIFigure,'Title','Preparing your data','Message','Please wait . . .','Indeterminate','on');
                    pause(0.2);
          [x,y] = size(app.TrainSet); 
          app.UITable.Data = app.TableMLExport;
          app.DataNumberEditField.Value = x;
          app.FeatureNumberEditField_2.Value = y-1;
          app.ClassNumberEditField_2.Value = app.ClassNum;
          app.ClassListListBox.Items = app.Class(1:end);
          app.X = app.TrainSet(1:end,1:end-1);%TrainData
          app.Y = app.TrainSet(1:end,end); %Label  
        end
        
        function trainModel(app)
               d = uiprogressdlg(app.MSPECAppUIFigure,'Title','Training your data','Message','Please wait . . .','Indeterminate','on');
                    pause(0.2);
            selectedButton = app.ValidationButtonGroup.SelectedObject;
            switch selectedButton
                case app.CrossValidationButton
                    app.folds = app.CrossValidationfoldsSpinner.Value;
                    TrainModel.modelPick(app);
                    %TrainModel.c_validation(app);
                    TrainModel.showAcc(app);
                case app.HoldoutValidationButton
                    app.percent = app.PercentheldoutSpinner.Value;
                    TrainModel.modelPick(app);
                    %h_validation(app);
                    TrainModel.showAcc(app);
                     
                case app.ResubstitutionValidationButton
                     TrainModel.modelPick(app);
                     TrainModel.showAcc(app);
            end

        end
        
        
        function modelPick(app)
              value = lower(app.OptimizerDropDown.Value);
            switch value
                case 'bayesian'
                    app.optimizer = 'bayesopt';
                otherwise
                    app.optimizer = value;
            end
            selectedButton = app.ModelSelectionButtonGroup.SelectedObject;
            switch selectedButton
                case app.DecisionTreesButton
                    app.mtype = app.DropDown_2.Value;
                    TrainModel.trainDT(app,app.mtype);
                case app.DiscriminantAnalysisButton
                    app.mtype = app.DropDown.Value;
                    TrainModel.trainDA(app,app.mtype);
                case app.NaiveBayesButton
                    app.mtype = app.DropDown_5.Value;
                    TrainModel.trainNB(app,app.mtype);
                case app.SupportVectorMachinesButton
                    app.mtype = app.DropDown_4.Value;
                    TrainModel.trainSVM(app,app.mtype);
                case app.NearestNeighborButton
                    app.mtype = app.DropDown_3.Value;
                   TrainModel.trainKNN(app,app.mtype);
                case app.NeuralNetworkButton
                    app.mtype = app.DropDown_6.Value;
                    TrainModel.trainNN(app,app.mtype);                
            end

        end
        
        
        function showAcc(app)
           selectedButton = app.ValidationButtonGroup.SelectedObject;
           switch selectedButton
                case app.CrossValidationButton
                    app.ValidatedModel = crossval(app.TrainedModel,'KFold',app.folds);
                    app.classLoss = kfoldLoss(app.ValidatedModel);
                    disp("ClassLoss:")
                    disp(app.classLoss);
                    classAcc = 1-app.classLoss;
                    app.ValAcc = classAcc*100;
                    app.FoldsEditField.Value = app.folds;
                    app.FoldsEditField.Enable = "on";
                    app.HeldoutEditField.Enable = "off";
                case app.HoldoutValidationButton
                    app.ValidatedModel = crossval(app.TrainedModel,'Holdout',app.percent/100);
                    app.classLoss = kfoldLoss(app.ValidatedModel); %Can use this for holdout
                    disp("ClassLoss:")
                    disp(app.classLoss);
                    classAcc = 1-app.classLoss;
                    app.ValAcc = classAcc*100;
                    app.HeldoutEditField.Value = app.percent;
                    app.FoldsEditField.Enable = "off";
                    app.HeldoutEditField.Enable = "on";
                case app.ResubstitutionValidationButton
                    app.classLoss = resubLoss(app.TrainedModel);
                    disp("ClassLoss:")
                    disp(app.classLoss);
                    classAcc = 1-app.classLoss;
                    app.ValAcc = classAcc*100;  
                    app.FoldsEditField.Value = 0;
                    app.HeldoutEditField.Value = 0;
                    app.FoldsEditField.Enable = "off";
                    app.HeldoutEditField.Enable = "off";
           end
           
            app.ModelNameEditField.Value = app.ModelSelectionButtonGroup.SelectedObject.Text;
            app.ModelTypeEditField.Value = app.mtype;
            app.ValidationTypeEditField.Value = selectedButton.Text;
            app.ValidationAccuracyPercentEditField.Value = app.ValAcc;
            app.ClassLossEditField_2.Value = app.classLoss;
            
            %Y = table2array(app.Y);
            %pred = reshape(pred,size(pred));
            %ConfusionMat1 = confusionchart(Y,pred);
            
 
            
            disp(app.ValidatedModel);
            disp("ClassValidationAcc = ");
            disp(app.ValAcc)
        end
        
        
        
  

                
        
        function trainSVM(app,mtype)
            mtype  = lower(mtype);
            disp(mtype)
            if mtype == "optimizable"
                    app.TrainedModel = fitcecoc(app.X,app.Y,'OptimizeHyperparameters','auto', ...
                    'HyperparameterOptimizationOptions',struct('Optimizer',app.optimizer, ...
                    'AcquisitionFunctionName',app.aqfn,'MaxObjectiveEvaluations',app.iteration));
                    aqfn = ['AcquisitionFunctionName: ' app.aqfn];
                    opt = ['Optimizer: ' upper(app.OptimizerDropDown.Value(1)) app.OptimizerDropDown.Value(2:end)];
                    it = ['Iteration: ' num2str(app.iteration)];
                
                    app.TextArea.Value = sprintf('%s\n\n%s\n\n%s\n\n%s', 'Model Name: Optimizable SVM', opt, ...
                    aqfn ,it);
            elseif mtype == "cubic"
                t = templateSVM('Standardize',true,'KernelFunction','Polynomial','KernelScale','auto','PolynomialOrder',3);
                app.TrainedModel = fitcecoc(app.X,app.Y,'Learners',t);
                app.TextArea.Value = sprintf('%s\n\n%s\n\n%s\n\n%s\n\n%s', 'Model Name: Cubic SVM', 'Standardize: true', ...
                'KernelFunction: Polynomial','KernelScale: auto','PolynomialOrder: 3');
            else
                    t = templateSVM('Standardize',true,'KernelFunction',mtype,'KernelScale','auto');
                    disp(t);
                    modelname = ['Model Name: ' upper(mtype(1)) mtype(2:end) ' SVM'];
                    kernelfn = ['KernelFunction: ' mtype];
                    app.TextArea.Value = sprintf('%s\n\n%s\n\n%s\n\n%s\n\n',modelname, 'Standardize: true', ...
                    kernelfn,'KernelScale: auto');
                    app.TrainedModel = fitcecoc(app.X,app.Y,'Learners',t);
            end
            disp("===============================")
            disp(app.TrainedModel);
            %All ok
        end
        
        
        function trainDT(app,mtype)
            mtype  = lower(mtype);
            disp(mtype)
            
            switch mtype
                case "fine tree"
                   app.TrainedModel = fitctree(app.X,app.Y,'MaxNumSplits',100,'SplitCriterion','gdi','Surrogate','off');
                    modelname = ['Model Name: ' upper(mtype(1)) mtype(2:end)];
                    maxsplit = ['MaxNumSplits: ' num2str(100)];
                    app.TextArea.Value = sprintf('%s\n\n%s\n\n%s\n\n%s\n\n',modelname, maxsplit, ...
                    "SplitCriterion: Gini's diversity index",'Surrogate: Off');
                case "medium tree"
                    app.TrainedModel = fitctree(app.X,app.Y,'MaxNumSplits',20,'SplitCriterion','gdi','Surrogate','off');
                    modelname = ['Model Name: ' upper(mtype(1)) mtype(2:end)];
                    maxsplit = ['MaxNumSplits: ' num2str(20)];
                    app.TextArea.Value = sprintf('%s\n\n%s\n\n%s\n\n%s\n\n',modelname, maxsplit, ...
                    "SplitCriterion: Gini's diversity index",'Surrogate: Off');
                case "coarse tree"
                    app.TrainedModel = fitctree(app.X,app.Y,'MaxNumSplits',4,'SplitCriterion','gdi','Surrogate','off');   
                     modelname = ['Model Name: ' upper(mtype(1)) mtype(2:end)];
                    maxsplit = ['MaxNumSplits: ' num2str(4)];
                    app.TextArea.Value = sprintf('%s\n\n%s\n\n%s\n\n%s\n\n',modelname, maxsplit, ...
                    "SplitCriterion: Gini's diversity index",'Surrogate: Off');
                case "optimizable tree"
                    app.TrainedModel = fitctree(app.X,app.Y,'OptimizeHyperparameters','auto', ...
                    'HyperparameterOptimizationOptions',struct('Optimizer',app.optimizer, ...
                    'AcquisitionFunctionName',app.aqfn,'MaxObjectiveEvaluations',app.iteration));
                
                    aqfn = ['AcquisitionFunctionName: ' app.aqfn];
                    opt = ['Optimizer: ' upper(app.OptimizerDropDown.Value(1)) app.OptimizerDropDown.Value(2:end)];
                    it = ['Iteration: ' num2str(app.iteration)];
                
                    app.TextArea.Value = sprintf('%s\n\n%s\n\n%s\n\n%s', 'Model Name: Optimizable Tree', opt, ...
                    aqfn ,it);
            end
                disp(app.TrainedModel)
        end
        
        function trainKNN(app,mtype)
            mtype  = lower(mtype);
            disp(mtype)
            switch mtype
                case "fine knn"
                   app.TrainedModel = fitcknn(app.X,app.Y,'NumNeighbors',1,...
                   'Distance','euclidean',...
                   'DistanceWeight','equal','Standardize',true);
               
                    modelname = ['Model Name: ' upper(mtype(1)) mtype(2:end)];
                    maxsplit = ['NumNeighbors: ' num2str(1)];
                    app.TextArea.Value = sprintf('%s\n\n%s\n\n%s\n\n%s\n\n%s\n\n',modelname, maxsplit, ...
                    'Distance: Euclidean','DistanceWeight: equal','Standardize: true');
               
               
                case "medium knn"
                    app.TrainedModel = fitcknn(app.X,app.Y,'NumNeighbors',10,...
                    'Distance','euclidean',...
                    'DistanceWeight','equal','Standardize',true);
                
                    modelname = ['Model Name: ' upper(mtype(1)) mtype(2:end)];
                    maxsplit = ['NumNeighbors: ' num2str(10)];
                    app.TextArea.Value = sprintf('%s\n\n%s\n\n%s\n\n%s\n\n%s\n\n',modelname, maxsplit, ...
                    'Distance: Euclidean','DistanceWeight: equal','Standardize: true');
                case "coarse knn"
                    app.TrainedModel = fitcknn(app.X,app.Y,'NumNeighbors',100,...
                    'Distance','euclidean',...
                    'DistanceWeight','equal','Standardize',true);
                    modelname = ['Model Name: ' upper(mtype(1)) mtype(2:end)];
                    maxsplit = ['NumNeighbors: ' num2str(100)];
                    app.TextArea.Value = sprintf('%s\n\n%s\n\n%s\n\n%s\n\n%s\n\n',modelname, maxsplit, ...
                    'Distance: Euclidean','DistanceWeight: equal','Standardize: true');
                case "cosine knn"
                    app.TrainedModel = fitcknn(app.X,app.Y,'NumNeighbors',10,...
                    'Distance','cosine',...
                    'DistanceWeight','equal','Standardize',true);
                
                    modelname = ['Model Name: ' upper(mtype(1)) mtype(2:end)];
                    maxsplit = ['NumNeighbors: ' num2str(10)];
                    app.TextArea.Value = sprintf('%s\n\n%s\n\n%s\n\n%s\n\n%s\n\n',modelname, maxsplit, ...
                    'Distance: Cosine','DistanceWeight: equal','Standardize: true');
                case "cubic knn"
                    app.TrainedModel = fitcknn(app.X,app.Y,'NumNeighbors',10,...
                    'Exponent',3,'Distance','minkowski',...
                    'DistanceWeight','equal','Standardize',true);
                    modelname = ['Model Name: ' upper(mtype(1)) mtype(2:end)];
                    maxsplit = ['NumNeighbors: ' num2str(10)];
                    app.TextArea.Value = sprintf('%s\n\n%s\n\n%s\n\n%s\n\n%s\n\n%s\n\n',modelname, maxsplit,'Exponent: 3', ...
                    'Distance: Minkowski','DistanceWeight: equal','Standardize: true');
                    
                case "optimizable knn"
                    app.TrainedModel = fitcknn(app.X,app.Y,'OptimizeHyperparameters','auto', ...
                    'HyperparameterOptimizationOptions',struct('Optimizer',app.optimizer, ...
                    'AcquisitionFunctionName',app.aqfn,'MaxObjectiveEvaluations',app.iteration));
                
                    aqfn = ['AcquisitionFunctionName: ' app.aqfn];
                    opt = ['Optimizer: ' upper(app.OptimizerDropDown.Value(1)) app.OptimizerDropDown.Value(2:end)];
                    it = ['Iteration: ' num2str(app.iteration)];
                
                    app.TextArea.Value = sprintf('%s\n\n%s\n\n%s\n\n%s', 'Model Name: Optimizable knn', opt, ...
                    aqfn ,it);
            end
            disp(app.TrainedModel)
            
        end
        
        function trainDA(app,mtype)
            mtype = lower(mtype);
            disp(mtype)
            switch mtype
                case "linear discriminant"
                   app.TrainedModel = fitcdiscr(app.X,app.Y,'DiscrimType','pseudoLinear'); 
                   
                   modelname = ['Model Name: ' upper(mtype(1)) mtype(2:end)];
                   app.TextArea.Value = sprintf('%s\n\n%s\n\n',modelname,'Discriminator Type: PseudoLinear');
                   
                   
                   %{
                case "optimizable discriminant"
                    app.TrainedModel = fitcdiscr(app.X,app.Y,'DiscrimType','pseudoLinear','OptimizeHyperparameters','auto', ...
                    'HyperparameterOptimizationOptions',struct('Optimizer',app.optimizer, ...
                    'AcquisitionFunctionName',app.aqfn,'MaxObjectiveEvaluations',app.iteration));
                   %}
            end
                disp(app.TrainedModel)
            
        end
        
        function trainNB(app,mtype)
            app.TrainedModel = fitcnb(app.X,app.Y,'DistributionNames','kernel','Kernel','normal','Support','unbounded'); 
            
            modelname = ['Model Name: ' upper(mtype(1)) mtype(2:end)];
            app.TextArea.Value = sprintf('%s\n\n%s\n\n%s\n\n%s\n\n',modelname, 'DistributionNames: Kernel','Kernel: Normal', ...
            'Support: Unbounded');
            
            disp(app.TrainedModel)
        end
        
         function trainNN(app,mtype)
            disp(mtype)
            switch mtype
                case "Narrow Neural Network"
                   app.TrainedModel = fitcnet(app.X,app.Y,'LayerSizes',10,'Activations','relu');
                    app.TextArea.Value = sprintf('%s\n\n%s\n\n%s\n\n%s\n\n',['Model Name: ' mtype],'Layers: 1','LayerSizes: [10]','Activations: relu');
                case "Medium Neural Network"
                    app.TrainedModel = fitcnet(app.X,app.Y,'LayerSizes',25,'Activations','relu');
                    app.TextArea.Value = sprintf('%s\n\n%s\n\n%s\n\n%s\n\n',['Model Name: ' mtype],'Layers: 1','LayerSizes: [25]','Activations: relu');
                case "Wide Neural Network"
                    app.TrainedModel = fitcnet(app.X,app.Y,'LayerSizes',100,'Activations','relu');
                    app.TextArea.Value = sprintf('%s\n\n%s\n\n%s\n\n%s\n\n',['Model Name: ' mtype],'Layers: 1','LayerSizes: [100]','Activations: relu');
                case "Bilayered Neural Network"
                    app.TrainedModel = fitcnet(app.X,app.Y,'LayerSizes',[10 10],'Activations','relu');
                    app.TextArea.Value = sprintf('%s\n\n%s\n\n%s\n\n%s\n\n',['Model Name: ' mtype],'Layers: 2','LayerSizes: [10 10]','Activations: relu');
                case "Trilayered Neural Network"
                    app.TrainedModel = fitcnet(app.X,app.Y,'LayerSizes',[10 10 10],'Activations','relu');
                    app.TextArea.Value = sprintf('%s\n\n%s\n\n%s\n\n%s\n\n',['Model Name: ' mtype],'Layers: 3','LayerSizes: [10 10 10]','Activations: relu');
            end
             disp(app.TrainedModel)
         end
        
         function exportModel(app)
             exportFileName = strcat(app.ProjectName,"_Trained_",app.ModelSelectionButtonGroup.SelectedObject.Text);
            [file,path] = uiputfile(exportFileName);
            filename = fullfile(path,file);
            saveLearner(app.TrainedModel,filename); 
         end
        
    end
end

