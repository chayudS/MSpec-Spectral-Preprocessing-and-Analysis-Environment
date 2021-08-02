function edgeList = generateBins(commonMZ, maxPeaks, tolerance, method)
    if (checkTolerance(commonMZ,tolerance)) & (size(commonMZ) <= maxPeaks )
    	edgeList = []; 
    elseif (checkTolerance(commonMZ,tolerance)) &  (method=="Relaxed")
        edgeList = []; 
    else
        edgeList = [];
        difList =  diff(commonMZ);
        maxDif = max( difList(difList>=0));
        index = find(difList==maxDif);
        % divide list by half and append new edge
        edgeList(end+1) = commonMZ(index(1))+ (maxDif/2);
        leftSubList = commonMZ(1:index);
        rightSubList = commonMZ(index+1:end);
        leftEdgeList = generateBins(leftSubList,maxPeaks, tolerance, method);
        rightEdgeList = generateBins(rightSubList,maxPeaks, tolerance, method);
        
        edgeList = cat(2,edgeList,leftEdgeList);
        edgeList = cat(2,edgeList,rightEdgeList);
        edgeList = sort(edgeList);
    end
end

function isBin = checkTolerance(Peaklist,tolerance)
    isBin = true;
    meanMass = mean(Peaklist);
    for i=1:size(Peaklist)
        threshold = (abs(Peaklist(i)-meanMass)/meanMass);
        if threshold > tolerance
            isBin = false;
        end
    end
end