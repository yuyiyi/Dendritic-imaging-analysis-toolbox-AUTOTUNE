function handles = Call_loadmovie(loadmovieflag, I1, Mem_max, w, f_wait, handles)

tic
if loadmovieflag
    if handles.datatype ~=3
        %%%%% load movie in .tiff format%%%%%%%%%%%%
        imageinfo = handles.imageinfo;
        grad = handles.movieinputgrad;
        fext = handles.fext;
        mov = zeros([size(I1), length(1:grad:length(imageinfo))], handles.WorkingPrecision);
        j1 = 1;
        for j = 1:grad:length(imageinfo)
            if ~isempty(fext)
                I1 = imread(fullfile(handles.filepath, handles.filename), j);
            else
                I1 = imread(fullfile(handles.filepath, handles.filename, imageinfo(j).name));
            end
            mov(:,:,j1) = I1;
            j1 = j1+1;
            waitbar(j/length(imageinfo), f_wait);
        end
        [d1,d2,T] = size(mov);
        handles.size = [d1, d2, T];
    else
        %%%%% load movie in .bin format%%%%%%%%%%%%
        binfilelist = handles.RegPara.savename;
        if ~iscell(binfilelist)
            binfilelist = {binfilelist};
            handles.RegPara.savename = {binfilelist};
        end
        grad = handles.movieinputgrad;
        Ly = handles.size(1);
        Lx = handles.size(2);
        mov = [];
        for j = 1:length(binfilelist)
            fig = fopen(fullfile(handles.filepath, binfilelist{j}), 'r');
            clear mov_sub; 
            mov_sub = fread(fig, Ly*Lx*handles.imagelength(j), [handles.WorkingPrecision '=>' handles.WorkingPrecision]);
            mov_sub = reshape(mov_sub, Ly,Lx,handles.imagelength(j));
            mov = cat(3, mov, mov_sub(:,:,1:grad:end));
            fclose(fig);    
            waitbar(j/length(binfilelist), f_wait);
        end
        clear mov_sub;
    end
    [d1,d2,T] = size(mov);
    handles.size = [d1, d2, T]; % working size, T is not the full length
    maxL = min(floor((Mem_max-w.bytes*T)/w.bytes), 5000);
    Gpara = handles.defaultPara.GaussKernel;
    G = fspecial('gaussian', Gpara(1:2), Gpara(3));
    subsample = max(ceil(T/maxL),1);
    movF = MovGaussFilter_v2(mov, G, subsample, handles.WorkingPrecision, handles.useGPU, handles);
%     assignin('base', 'movF', movF)
    mov2d_filt = reshape(movF,d1*d2,size(movF,3));
    im = single(mean(mov,3));
    handles.im = im;
    im_norm = im;
    im_norm = im_norm-quantile(im_norm(:), 0.02);
    im_norm(im_norm<0) = 0;
    im_norm = im_norm/max(im_norm(:));
    handles.im_norm = im_norm;
    handles.roimask = zeros(size(im_norm));
%     assignin('base', 'movF', movF);
    handles.mov2d_filt = mov2d_filt;
    handles.mov = reshape(mov, [], size(mov,3));    
end
toc
close(f_wait)
delete(f_wait)

