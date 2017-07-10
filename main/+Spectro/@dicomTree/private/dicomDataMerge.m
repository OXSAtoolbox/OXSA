function dicomData = dicomDataMerge(varargin)
% Test merging these...

dicomData = varargin{1};

% Merge in varargin{2}
for dirDx = 2:numel(varargin)
    for studyDx = 1:numel(varargin{dirDx}.study)
        oldStudyDx = find(strcmp({dicomData.study.StudyInstanceUID},varargin{dirDx}.study(studyDx).StudyInstanceUID));
        if isempty(oldStudyDx)
            % Not found - append
            oldStudyDx = numel(dicomData.study) + 1;
            dicomData.study(oldStudyDx) = varargin{dirDx}.study(studyDx);
        else
            % Merge study
            oldStudyDx = oldStudyDx(1);
            
            for seriesDx = 1:numel(varargin{dirDx}.study(studyDx).series)
                oldSeriesDx = find(strcmp({dicomData.study(oldStudyDx).series.SeriesInstanceUID},varargin{dirDx}.study(studyDx).series(seriesDx).SeriesInstanceUID));
                if isempty(oldSeriesDx)
                    % Not found - append
                    oldSeriesDx = numel(dicomData.study(oldStudyDx).series) + 1;
                    dicomData.study(oldStudyDx).series(oldSeriesDx) = varargin{dirDx}.study(studyDx).series(seriesDx);
                else
                    % Merge series
                    oldSeriesDx = oldSeriesDx(1);
                    
                    for instanceDx = 1:numel(varargin{dirDx}.study(studyDx).series(seriesDx).instance)
                        dicomData.study(oldStudyDx).series(oldSeriesDx).instance(end+1) = varargin{dirDx}.study(studyDx).series(seriesDx).instance(instanceDx);
                    end
                end
            end
        end
    end
end
