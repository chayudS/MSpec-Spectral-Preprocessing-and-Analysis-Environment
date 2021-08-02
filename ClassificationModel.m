classdef ClassificationModel
    
    properties
        ModelName
        Model
        Preprocessing PreprocessingParameters
    end
    
    methods
        function obj = ClassificationModel(name, model,preproc)
            obj.ModelName = name;
            obj.Model = model;
            obj.Preprocessing = preproc;
        end
    end
end

