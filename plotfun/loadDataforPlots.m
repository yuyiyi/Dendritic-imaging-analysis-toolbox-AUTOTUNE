function handles = loadDataforPlots(handles, plotID)
datafilepath = handles.datafilepath;
if nargin<2
    datafilename = handles.datafilename{1};
else
    datafilename = handles.datafilename{plotID};    
end
fprintf('Load data from: ' ); fprintf('%s\n', fullfile(datafilepath, datafilename));
variableinfo = who('-file', fullfile(datafilepath, datafilename));

variablename = [];
im_norm = [];
linewidth = [];
dendriteROI = [];
dend_trace = [];
dend_dff = [];
dend_filt = [];
dend_line_all = [];
dend_title = [];
spineROI = [];
rois = [];
spine_trace = [];
spine_dff = [];
spine_filt = [];
roi_seed = [];
spine_BAP_current = [];
spine_trace_BAPremoval = [];
spine_BAPremoval_coef = [];
spine_title = [];
dend_shaft = [];
shaft_trace = [];
shaft_dff = [];
shaft_filt = [];
shaft_BAP_current = [];
shaft_trace_BAPremoval = [];
shaft_BAPremoval_coef = [];
shaft_title = [];
cfeature_dff = [];
cfeature_filt = [];
cfeature_trace = [];
feature_title = [];

%%%% load feature detection results
if ismember('im_norm', variableinfo) 
    load(fullfile(datafilepath, datafilename), 'im_norm')
end
if ismember('linewidth', variableinfo)
    load(fullfile(datafilepath, datafilename), 'linewidth')
end
d = 0;
if ismember('spineROI', variableinfo)
    d = d+1;
    load(fullfile(datafilepath, datafilename), 'spineROI')
end
if ismember('dendriteROI', variableinfo)
    d = d+1;
    load(fullfile(datafilepath, datafilename), 'dendriteROI')
end
if ismember('dend_shaft', variableinfo)
    d = d+1;    
    load(fullfile(datafilepath, datafilename), 'dend_shaft')
end

%%%% allow user input traces in matrix format (not generated by the program)
if d==0
    disptext = 'Select custom features matrix'; 
    variablesel = featuresel(variableinfo, handles, disptext);    
    if ~isempty(variablesel)
        variablename = variableinfo(variablesel);
        [cfeature_dff, cfeature_trace, feature_title]...
            = loadcustomfeature(variablename, variableinfo, datafilepath, datafilename);
    end
    
else
    %%%% check if post processing results exist
    if ~isempty(dendriteROI)            
        if ~isfield(dendriteROI, 'dff')
            for i = 1:length(dendriteROI)
                dend_dff = [];
                if ~isempty(dendriteROI(i).trace)
                dend_trace_current = dendriteROI(i).trace;
                dend_dff = getdff(dend_trace_current);
                end
                dendriteROI(i).dff = dend_dff;
            end
            save(fullfile(datafilepath, datafilename), 'dendriteROI', '-append')
        end
        dend_line_all = [];
        dend_trace = [dendriteROI.trace];
        dend_dff = [dendriteROI.dff];
        if isfield(dendriteROI, 'dff_filt')
            dend_filt = [dendriteROI.dff_filt];
        end
        for i = 1:length(dendriteROI)
            if ~isempty(dendriteROI(i).dend_line)
                dend_title = cat(1,dend_title,i);
                dend_line = dendriteROI(i).dend_line;
                dend_line_all = cat(1, dend_line_all, [dend_line, ones(size(dend_line,1),1)*i]);
            end
        end
    end

    if ~isempty(spineROI) 
        roi_seed = reshape([spineROI.roi_seed], 2,[])';
        rois = [];
        for i = 1:length(spineROI)
            roitmp = zeros(size(im_norm,1)*size(im_norm,2), 1);
            if ~isempty(spineROI(i).spine_pixel)
                spine_title = cat(1, spine_title, i);
                roitmp(spineROI(i).spine_pixel, 1) = 1;
                rois = cat(2, rois, roitmp);
            end
        end
        rois = reshape(rois, size(im_norm,1), size(im_norm,2), []);
        if ~isfield(spineROI, 'spine_dff')
            for i = 1:length(spineROI)
                spine_dff = [];
                if ~isempty(spineROI(i).spine_trace)
                    spine_dff = getdff(spineROI(i).spine_trace);
                end
                    spineROI(i).spine_dff = spine_dff;            
            end
            save(fullfile(datafilepath, datafilename), 'spineROI', '-append')
        end
        spine_dff = [spineROI.spine_dff];
        spine_trace = [spineROI.spine_trace];
        if isfield(spineROI, 'BAP_current')
            spine_BAP_current = [spineROI.BAP_current];
        end
        if isfield(spineROI, 'dff_BAPremoval')
            spine_trace_BAPremoval = [spineROI.dff_BAPremoval];
        end
        if isfield(spineROI, 'BAPremoval_coef')
            spine_BAPremoval_coef = [spineROI.BAPremoval_coef];
        end
        if isfield(spineROI, 'dff_filt')
            spine_filt = [spineROI.dff_filt];
        end
        if ~isempty(dend_line_all)
            if ~isfield(spineROI, 'dendriteID') || ~isfield(spineROI, 'dendloc_linear')
                [nearestID, dend_arcloc, dendloc] = nearestDendrite(roi_seed, dendriteROI, handles);
                i = 0;
            for k = 1:length(spineROI)
                if ~isempty(spineROI(k).roi_seed)
                    i = i+1;
                    spineROI(k).dendriteID = nearestID(i);
                    spineROI(k).dendloc_linear = dend_arcloc(i);
                    spineROI(k).dendloc_pixel = dendloc(i,:);
                end
            end
            save(fullfile(datafilepath, datafilename), 'spineROI', '-append')
            end
        end
    end

    if ~isempty(dend_shaft)  
        flag = 0;
        if ~isfield(dend_shaft, 'dendloc_linear')
            dend_shaft = shaftloc(dend_shaft, dendriteROI);
            flag = 1;
        end
        if ~isfield(dend_shaft, 'shaft_dff')
            flag = 1;
        end
        for i = 1:length(dend_shaft)            
            if ~isempty(dend_shaft(i).shaft_trace)
                shaft_title = cat(1, shaft_title, i);
                if flag == 1
                    shaft_dff = getdff(dend_shaft(i).shaft_trace);
                    dend_shaft(i).shaft_dff = shaft_dff;
                end
            else
                dend_shaft(i).shaft_dff = [];
            end
        end
        if flag == 1
            save(fullfile(datafilepath, datafilename), 'dend_shaft', '-append')
        end
        shaft_dff = [dend_shaft.shaft_dff];
        shaft_trace = [dend_shaft.shaft_trace];
        if isfield(dend_shaft, 'BAP_current')
            shaft_BAP_current = [dend_shaft.BAP_current];
        end
        if isfield(dend_shaft, 'dff_BAPremoval')
            shaft_trace_BAPremoval = [dend_shaft.dff_BAPremoval];
        end
        if isfield(dend_shaft, 'BAPremoval_coef')
            shaft_BAPremoval_coef = [dend_shaft.BAPremoval_coef];
        end
        if isfield(dend_shaft, 'dff_filt')
            shaft_filt = [dend_shaft.dff_filt];
        end
    end
end
handles.im_norm = im_norm;
handles.linewidth = linewidth;

handles.dendrite = dendriteROI;
handles.dend_trace = dend_trace;
handles.dend_dff = dend_dff;
handles.dend_filt = dend_filt;
handles.dend_line_all = dend_line_all;
    
handles.spineROI = spineROI;
handles.roi = rois;
handles.spine_trace = spine_trace;
handles.spine_dff = spine_dff;
handles.spine_filt = spine_filt;
handles.roi_seed = roi_seed;
handles.spine_BAP_current = spine_BAP_current;
handles.spine_trace_BAPremoval = spine_trace_BAPremoval;
handles.spine_BAPremoval_coef = spine_BAPremoval_coef;

handles.dend_shaft = dend_shaft;
handles.shaft_trace = shaft_trace;
handles.shaft_dff = shaft_dff;
handles.shaft_filt = shaft_filt;
handles.shaft_BAP_current = shaft_BAP_current;
handles.shaft_trace_BAPremoval = shaft_trace_BAPremoval;
handles.shaft_BAPremoval_coef = shaft_BAPremoval_coef;

handles.spine_title = spine_title;
handles.dend_title = dend_title;
handles.shaft_title = shaft_title;

handles.variablename = variablename;
handles.cfeature_dff = cfeature_dff;
handles.cfeature_filt = cfeature_filt;
handles.cfeature_trace = cfeature_trace;
handles.feature_title = feature_title;

%% load frame stamps
framestampname = '';
handles = loadframestamp(framestampname, datafilepath, handles);

% if length(handles.datafilename) == 1
%     if isempty( handles.framestamp )
%         opts.Interpreter = 'tex';
%         opts.Default = 'Yes';
%         anw = questdlg('\fontsize{12}If input frame stamp from another direction?',...
%             'Load frame stamp', 'Yes', 'No', opts);
%         if strcmp(anw, 'Yes')
%             [framestampname, framestamppath, indx] = uigetfile({'*.mat';'*.*'}, 'Select ROI map');
%             if indx > 0
%                 fprintf('Load frame stamp from: ' ); fprintf('%s\n', fullfile(framestamppath, framestampname));
%                 handles.framestampname = framestampname;
%                 handles.framestamppath = framestamppath;
%                 [framestamp, stampinfo] = loadframestamp(framestampname, framestamppath, handles);
%                 if ~isempty(framestamp)
%                     handles.framestamp = framestamp;
%                     save(fullfile(datafilepath, datafilename), 'framestamp', '-append')
%                 end
%                 if ~isempty(stampinfo)
%                     handles.stampinfo = stampinfo;
%                     save(fullfile(datafilepath, datafilename), 'stampinfo', '-append')
%                 end
%             end
%         end
%     end
%     if isempty(handles.stampinfo)
%         opts.Interpreter = 'tex';
%         opts.Default = 'Yes';
%         anw = questdlg('\fontsize{12}If input stamp label from another direction?',...
%             'Load stamp label', 'Yes', 'No', opts);
%         if strcmp(anw, 'Yes')
%             [stampinfoname, stampinfopath ,indx] = uigetfile({'*.mat';'*.*'}, 'Select ROI map');
%             if indx>0
%                 fprintf('Load stamp information from: ' ); fprintf('%s\n', fullfile(stampinfopath, stampinfoname));
%                 handles.stampinfoname = stampinfoname;
%                 handles.stampinfopath = stampinfopath;
%                 [~, stampinfo] = loadframestamp(stampinfoname, stampinfopath, handles);
%                 if ~isempty(stampinfo)
%                     handles.stampinfo = stampinfo;
%                     save(fullfile(datafilepath, datafilename), 'stampinfo', '-append')
%                 end
%             end
%         end
%     end
% end