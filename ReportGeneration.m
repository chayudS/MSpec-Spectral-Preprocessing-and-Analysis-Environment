classdef ReportGeneration
    
    properties
    end
    
    methods (Static)
        function generatePDFReport(app)
            exportFileName = strcat(app.CurrentProject.ProjectName,'.pdf');
            [file,path] = uiputfile(exportFileName);
            
            waitbar = uiprogressdlg(app.MSPECAppUIFigure,'Title','Please Wait',...
                'Message','Initializing');
            pause(.5)
            
            project = app.CurrentProject;
            ppms = project.PreprocessedData;

            Parameter = {'Window Size';'Step Size';'Quantile Value' ...
            ;'Reference Spectrum'; 'Minimum Segment Size Allowed';'Maximum Shift Allowed'};
        
            PeakDetectionParameter = {'Base';'Multiplier';'Height Filter' ...
            ;'Threshold'};
        
            PeakBinningParameter = {'Metod';'Maximum no. of peaks';'Tolerance'};

            Value = {ppms.WindowSize;ppms.StepSize;ppms.QuantileValue; ...
                ppms.ReferenceSpectrum;ppms.SegmentSize;ppms.ShiftAllowance};
            PeakDetectionValue = {ppms.Base;ppms.Multiplier;ppms.HeightFilter; ...
                ppms.PeakThreshold};
            PeakBinningValue = {ppms.BinningMethod;ppms.BinningMaxPeaks;ppms.BinningTolerance};
        
        
       
             
             pause(1.5)
            % Import report API classes (optional)
            import mlreportgen.report.* 
            import mlreportgen.dom.* 
            
            
            %*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

            waitbar.Value = .2; 
            waitbar.Message = 'Generating the Report';
            pause(.5)
            
            % Add report container (required)
            report = Report(fullfile(path,file),'pdf');
            waitbar.Message = "report = Report(fullfile(path,file),'pdf');";
            % Add content to container (required)
            % Types of content added here: title 
            % page and table of contents reporters
            titlepg = TitlePage;
            titlepg.Title = project.ProjectName;
            titlepg.Subtitle = 'MSpec'; 
            %titlepg.Author = sprintf('Created: %s',datestr(datetime('now')));
            add(report,titlepg);
            waitbar.Message = "add(report,titlepg);";
            %================================================
            
            append(report,TableOfContents); 
            
            chapter0 = Chapter('Project Information');
            sec0_1 = Section; 
            sec0_1.Title = 'Project Description'; 
            for i=1:length(app.CurrentProject.Description)
                para = string(app.CurrentProject.Description{i}); 
                append(sec0_1,para) 
            end
            append(chapter0,sec0_1) 
            
            create = ['Created: ',datestr(app.CurrentProject.CreatedDate)];
            file = ['File Name: ', app.CurrentProject.RawData.FileName];
                
            append(chapter0,create)
            append(chapter0,file)

            append(report,chapter0);

            
            %*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
            
            if app.PreprocessingCheckBox.Value
                waitbar.Value = .4; 
                waitbar.Message = 'Generating the Preprocessing Report';
                pause(.5)

                % Add content to report sections (optional)
                % Text and formal image added to chapter
                chapter1 = Chapter('Data Preprocessing');

                sec1_1 = Section; 
                sec1_1.Title = 'About MSpec Preprocessing'; 
                para = Paragraph(['Baseline Correction - The signal background estimation and baseline correction algorithms were implemented to provide background correction for a raw signal with peaks. The baseline was estimated using a sliding window approach. The algorithm estimates the background value for each window by performing the Expectation-Maximization (EM) or iterative histogram-based method and applies least squares linear regression to derive a continuous baseline for each shifted window. Then, the estimated continuous baseline was subtracted from the raw data. The result depends on the window size and step size. Define the parameters based on the width of your peaks in the signal and the presence of possible drifts. If you have wider peaks towards the end of the signal, consider using variable window sizes and/or step sizes.']); 
                para2 = Paragraph(['Peak Alignment - To align the peaks of the dataset, Peak Alignment by Fast Fourier Transform (PAFFT) was performed. PAFFT is an algorithm that calculates the correlations of sections in the dataset and shifts accordingly to align them.']); 
                append(sec1_1,para) 
                append(sec1_1,para2) 
                append(chapter1,sec1_1) 

                sec1_2 = Section; 
                sec1_2.Title = 'Parameters'; 
                % new line
                append(sec1_2,[newline]);

                concatTable = table(Parameter,Value);
                t = Table(concatTable);
                t.Style = {RowHeight('0.5in'),HAlign('center');};
                t.Border = 'solid';
                t.BorderWidth = '1px';
                t.ColSep = 'solid';
                t.ColSepWidth = '1';
                t.RowSep = 'solid';
                t.RowSepWidth = '1';

                % Set this property first to prevent overwriting alignment properties
                t.TableEntriesStyle = {FontFamily('Arial'),Width('3in'),Color('black')};
                t.TableEntriesHAlign = 'center';
                t.TableEntriesVAlign = 'middle';
                r = row(t,1);
                r.Style = [r.Style {Bold}];
                append(sec1_2,t) 

                append(chapter1,sec1_2) 

                sec1_3 = Section; 
                sec1_3.Title = 'Result'; 

                f1 = figure('visible','off');
                %plotting the raw data
                subplot(2,1,1,"Units","pixels");
                plot(project.RawData.RawMzValues, project.RawData.RawSpectraIntensities);
                xlim([project.RawData.MinIntensity project.RawData.MaxIntensity]);
                title('Raw Mass Spectra');

                % preprocessed
                subplot(2,1,2,"Units","pixels");
                plot(project.RawData.RawMzValues,project.PreprocessedData.BaselinedSpectra);
                xlim([project.PreprocessedData.SectionStart project.PreprocessedData.SectionEnd]);
                title('Preprocessed Mass Spectra');

                append(sec1_3,Figure(f1));

                append(chapter1,sec1_3) 
                
                append(report,chapter1);

            end
            %*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
            if app.NormalizationCheckBox.Value
                waitbar.Value = .5; 
                waitbar.Message = 'Generating the Normalization Report';
                pause(.5)

                chapter2 = Chapter('Data Normalization');

                sec2_1 = Section; 
                sec2_1.Title = 'About Normalization'; 
                para = Paragraph(['Normalization is the essential step for analyzing Mass Spectrometry imaging data. It gives the proper interpretation and is used to remove systematic artifacts that affect mass spectral intensity. MSpec offers several normalization methods, including total ion counts, p-norm, reference peak, noise level, median, and maximum peak.']); 

                sec2_2 = Section; 
                sec2_2.Title = 'Normalization Method'; 

                switch project.PreprocessedData.NormalizeMethod
                    case 'Sum'
                        methodName = 'Total Ion Count (TIC)';
                     case 'Area'
                        methodName = 'Area';
                     case 'Norm'
                        methodName = 'p-Norm';
                     case 'Median'
                        methodName = 'Median';
                     case 'Noise'
                        methodName = 'Noise Level';
                     case 'Max'
                        methodName = 'Maximum Intensity';
                     otherwise %peak
                        methodName = 'Reference Peak';
                end
                method = ['Method: ', methodName];

                append(sec2_1,para);
                append(sec2_2,method);

                fig = figure('visible','off');
                %plotting the Normalized data
                plot(project.RawData.RawMzValues, project.PreprocessedData.NormalizedSpectra);
                xlim([project.RawData.MinIntensity project.RawData.MaxIntensity]);
                title('Normalized Spectra');

                append(sec2_2,Figure(fig));

                append(chapter2,sec2_1) 
                append(chapter2,sec2_2) 
                append(report,chapter2);

            end

            
            %*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
            
            if app.PeakDetectionCheckBox.Value
                waitbar.Value = .6; 
                waitbar.Message = 'Generating the Peak Detection Report';
                pause(.5)

                chapter3 = Chapter('Peak Detection');

                sec3_1 = Section; 
                sec3_1.Title = 'About Peak Detection'; 
                para = Paragraph(['Peak Detection is used for extracting peaks from each spectra. MSpec offers an automatic peak detection option, but the parameters can also be adjusted in the self adjustment option. The detected peaks are aligned throughout the dataset according to the common m/z charge locations. The parameters defines the threshold for detecting peaks, and the criterions for finding m/z locations.']); 
                append(sec3_1,para);

                sec3_2 = Section; 
                sec3_2.Title = 'Peak Detection'; 

                switch project.PreprocessedData.IsAutoDetected
                    case true
                        methodName = 'Auto';
                        method = ['Method: ', methodName];
                        append(sec3_2,method);
                    otherwise
                        methodName = 'Self Adjustments';
                        concatTable = table(PeakDetectionParameter,PeakDetectionValue);
                        t = Table(concatTable);
                        t.Style = {RowHeight('0.5in'),HAlign('center');};
                        t.Border = 'solid';
                        t.BorderWidth = '1px';
                        t.ColSep = 'solid';
                        t.ColSepWidth = '1';
                        t.RowSep = 'solid';
                        t.RowSepWidth = '1';

                        % Set this property first to prevent overwriting alignment properties
                        t.TableEntriesStyle = {FontFamily('Arial'),Width('3in'),Color('black')};
                        t.TableEntriesHAlign = 'center';
                        t.TableEntriesVAlign = 'middle';
                        r = row(t,1);
                        r.Style = [r.Style {Bold}];
                        method = ['Method: ', methodName];
                        append(sec3_2,method);
                        append(sec3_2,t) ;
                end

                sec3_3 = Section; 
                sec3_3.Title = 'Result'; 
                total = ['Total detected peaks: ',num2str(my_numel(app.CurrentProject.PreprocessedData.CutThresholdPeak))];
                append(sec3_3,total);

                fig = figure('visible','off');
                hold("on");
                    for i=1:app.CurrentProject.RawData.NumberOfSpectra
                        plot(app.CurrentProject.RawData.RawMzValues,app.CurrentProject.PreprocessedData.NormalizedSpectra(:,i),app.CurrentProject.PreprocessedData.CutThresholdPeak{i}(:,1),app.CurrentProject.PreprocessedData.CutThresholdPeak{i}(:,2),'rx')
                    end
                hold("off");
                xlim([project.RawData.MinIntensity project.RawData.MaxIntensity]);
                title('Detected Peaks');

                append(sec3_3,Figure(fig));

                append(chapter3,sec3_1) 
                append(chapter3,sec3_2) 
                append(chapter3,sec3_3) 


                chapter4 = Chapter('Common Mass/Charge Locations');

                sec4_1 = Section; 
                sec4_1.Title = 'About Common Mass/Charge Locations'; 
                para = Paragraph(['Peaks corresponding to similar compounds may still be reported with slight mass/charge differences or drifts. Assuming that the four spectrograms correspond to comparable biological/chemical samples, it might be useful to compare peaks from different spectra, which requires peak binning (a.k.a. peak coalescing). The crucial task in data binning is to create a common mass/charge reference vector (or bins). Ideally, bins should collect one peak from each signal and should avoid collecting multiple relevant peaks from the same signal into the same bin.']); 

                append(sec4_1,para);

                sec4_2 = Section; 
                sec4_2.Title = 'Parameters'; 
                method = ['Method: ', methodName];
                method2 = 'Criterion: distance';
                method3 = ['Cutoff: ',num2str(app.CurrentProject.PreprocessedData.Cutoff)];
                append(sec4_2,method);
                append(sec4_2,method2);
                append(sec4_2,method3);


                sec4_3 = Section; 
                sec4_3.Title = 'Result'; 

                fig = figure('visible','off');
                total = ['Total CMZ: ',num2str(length(app.CurrentProject.PreprocessedData.CMZ))];
                append(sec4_3,total);

                hold("on");
                box("on");
                    for i=1:length(app.CurrentProject.PreprocessedData.CMZ)
                        xline(app.CurrentProject.PreprocessedData.CMZ(i),'k');
                    end
                plot(app.CurrentProject.RawData.RawMzValues,app.CurrentProject.PreprocessedData.NormalizedSpectra)
                xlim([project.RawData.MinIntensity project.RawData.MaxIntensity]);
                title('CMZ Locations');
                append(sec4_3,Figure(fig));


                append(chapter4,sec4_1) 
                append(chapter4,sec4_2) 
                append(chapter4,sec4_3) 

                chapter5 = Chapter('Peaks Aligned to CMZ');

                sec5_2 = Section; 
                sec5_2.Title = 'Parameters'; 
                method2 = 'Criterion: Auto';
                append(sec5_2,method2);


                sec5_3 = Section; 
                sec5_3.Title = 'Result'; 

                fig = figure('visible','off');

                hold ("on");
                box ("on");
                for i=1:length(app.CurrentProject.PreprocessedData.CMZ)
                    xline(app.CurrentProject.PreprocessedData.CMZ(i),'k');
                end
                plot(app.CurrentProject.RawData.RawMzValues,app.CurrentProject.PreprocessedData.NormalizedSpectra)
                plot(app.CurrentProject.PreprocessedData.CMZ,app.CurrentProject.PreprocessedData.AlignedDetectedPeak,'o')
                title('Peaks Aligned to CMZ');
                append(sec5_3,Figure(fig));


                append(chapter5,sec5_2) 
                append(chapter5,sec5_3) 
                append(report,chapter3);
                append(report,chapter4);
                append(report,chapter5);
            end
            
            %*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
            if app.PeakBinningCheckBox.Value

                waitbar.Value = .8; 
                waitbar.Message = 'Generating the Peak Binning Report';
                pause(.5)

                chapter6 = Chapter('Peak Binning');

                sec6_1 = Section; 
                sec6_1.Title = 'About Peak Binning'; 
                para = Paragraph(['Peak Binning is used for grouping data points as a vector to compare the peak between different spectra. For peak binning, common detected peaks among spectra were determined. This is done using hierarchical clustering to create a dendrogram tree. The number of clusters or bins depends on the cut-off value used to cut the tree. The bin edges were computed such that each bin is assigned with only one peak from the obtained common m/z reference vector. To create a new bin, the intensities of each m/z value in between the obtained edges are accumulated, and a mean mass of the bin will be assigned as the new peak position.']); 
                append(sec6_1,para);

                sec6_2 = Section; 
                sec6_2.Title = 'Parameters'; 
                switch project.PreprocessedData.IsImportedEdge
                    case true
                        method = ['Method: ', 'Imported edges'];
                        append(sec6_2,method);
                    otherwise
                        methodName = 'Self Adjustments';
                        concatTable = table(PeakBinningParameter,PeakBinningValue);
                        t = Table(concatTable);
                        t.Style = {RowHeight('0.5in'),HAlign('center');};
                        t.Border = 'solid';
                        t.BorderWidth = '1px';
                        t.ColSep = 'solid';
                        t.ColSepWidth = '1';
                        t.RowSep = 'solid';
                        t.RowSepWidth = '1';

                        % Set this property first to prevent overwriting alignment properties
                        t.TableEntriesStyle = {FontFamily('Arial'),Width('3in'),Color('black')};
                        t.TableEntriesHAlign = 'center';
                        t.TableEntriesVAlign = 'middle';
                        r = row(t,1);
                        r.Style = [r.Style {Bold}];
                        method = ['Method: ', methodName];
                        append(sec6_2,method);
                        append(sec6_2,t) ;
                end

                sec6_3 = Section; 
                sec6_3.Title = 'Result'; 

                fig = figure('visible','off');
                total = ['Total number of bins: ',num2str(length(app.CurrentProject.PreprocessedData.BinIndexList))];
                append(sec6_3,total);

                bar(app.CurrentProject.PreprocessedData.BinIndexList, app.CurrentProject.PreprocessedData.BinnedSpectra);
                xlim([project.RawData.MinIntensity project.RawData.MaxIntensity]);
                title('Binned Spectra');
                append(sec6_3,Figure(fig));

                append(chapter6,sec6_1) 
                append(chapter6,sec6_2) 
                append(chapter6,sec6_3) 
                append(report,chapter6);
            end

                   
            %*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
            waitbar.Value = 0.9; 
            waitbar.Message = 'Finishing';
            pause(.2)
            

            % Close the report (required)
            close(report);
            
            waitbar.Value = 1; 
            waitbar.Message = 'Displaying the Report';
            pause(.5)
            
            % Display the report (optional)
            rptview(report);
            
            %close wait bar
            close(waitbar)
        end
    end
end

