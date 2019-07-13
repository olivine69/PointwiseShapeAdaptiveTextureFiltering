function f = GuidanceFilter(I, G,  params)

    if(isfield(params, 'LineRadius'))
        LineRadius = 3;
    else
        LineRadius = params.LineRadius;
    end
    if(isfield(params, 'JBFniter'))
        niter = params.JBFniter;
    else
        niter = 2;
    end
    sigmaR = 0.05*sqrt(size(G,3));
    
    f = BLFilteringGPU(I, G, LineRadius, sigmaR); 
    imwrite(gather(f), './overall/f0.jpg');
    for k=1:niter
         f = BLFilteringGPU(f, f, LineRadius, sigmaR);
    end
    imwrite(gather(f), './overall/f.jpg');
%     f = RF(gather(I), LineRadius, sigmaR, niter, gather(G));
%     f = gpuArray(f);
end