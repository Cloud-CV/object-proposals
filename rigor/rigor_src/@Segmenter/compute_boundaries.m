function [bndry_data, extra_bndry_compute_time] = ...
        compute_boundaries(bndry_filepath, orig_I, segm_params, ...
                           other_params, extra_params)
% computes probabilisitic boundaries using Gb, GPb, Pb, SketchTokens or
% StructEdges
%
% @authors:     Ahmad Humayun
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014
    
    switch segm_params.boundaries_method
        case 'Gb'
            bndry_func = @compute_gb;
        case 'GPb'
            bndry_func = @compute_gpb;
        case 'Pb'
            bndry_func = @compute_pb;
        case 'SketchTokens'
            bndry_func = ...
                @(I) compute_sketchtokens(I, ...
                                          extra_params.sketchtokens_model);
        case 'StructEdges'
            bndry_func = ...
                @(I) compute_structedges(I, extra_params.structedges_model);
        otherwise
            bndry_func = [];
    end
    
    % in case bndry directory doesn't exist and IO setting is off
    if exist(fileparts(bndry_filepath), 'dir') == 0 && ~other_params.io
        mkdir(fileparts(bndry_filepath));
    end

    extra_bndry_compute_time = 0;

    if ~exist(bndry_filepath, 'file')
        if isempty(bndry_func)
            error('Segmenter:precompute', ...
                  ['''%s'' is not a valid boundary detection method ', ...
                   'and precomputed boundary matrices inexist'], ...
                  segm_params.boundaries_method);
        end
        fprintf('Computing boundaries by %s ... ', ...
                segm_params.boundaries_method);
        
        t_bndry = tic();
        [bndry_thin, bndry_fat, bndry_extra_info] = bndry_func(orig_I);
        bndry_compute_time = toc(t_bndry);
        % in case IO setting is off, then write bndry result to disk
        if ~other_params.io
            save(bndry_filepath, 'bndry_thin', 'bndry_fat', ...
                                 'bndry_extra_info', 'bndry_compute_time');
        end
        
        fprintf('%.2fs\n', bndry_compute_time);
    else
        fprintf('Loading %s boundaries from file\n', ...
                segm_params.boundaries_method);
            % To eliminate warnings by not finding bndry_compute_time
        s = warning('off','all');
        load(bndry_filepath, 'bndry_thin', 'bndry_fat', ...
                             'bndry_compute_time');
        if exist('bndry_compute_time','var')
            extra_bndry_compute_time = bndry_compute_time;
        else
            extra_bndry_compute_time = 0;
        end
        % restore it
        warning(s);
    end
    
    bndry_data.bndry_thin = bndry_thin;
    bndry_data.bndry_fat = bndry_fat;
end

function [Gb_thin, Gb_fat, extra_info] = compute_gb(I)
    fprintf('\n-----\n');
    [Gb_thin, extra_info.Gb_thin_CS, Gb_fat, extra_info.textons] = ...
        simpleGPb(I);
    fprintf('----- ');
end

function [gPb_thin, gPb_fat, extra_info] = compute_gpb(I)
    I = im2double(I);
    gPb_fat = [];
    [extra_info.gPb_orient, gPb_thin, extra_info.textons] = globalPb_im(I);
end

function [pb_thin, pb_fat, extra_info] = compute_pb(I)
    pb_fat = [];
    [pb_thin, extra_info.theta] = pbCGTG(I);
end

function [st_thin, st_fat, extra_info] = compute_sketchtokens(I, st_model)
    extra_info = struct;
    st = stDetect(I, st_model);
    st_fat = stToEdges(st, 0, false) * 255;
    st_thin = uint8(stToEdges(st, 1, false) * 255);
end

function [st_thin, st_fat, extra_info] = compute_structedges(I, st_model)
    extra_info = struct;
    [st_fat, st_thin, extra_info.gPb_orient] = edgesDetect(I, st_model);
    st_thin = uint8(st_thin * 255);
end
