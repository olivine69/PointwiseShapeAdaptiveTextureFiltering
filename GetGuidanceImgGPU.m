function [G, Alpha] = GetGuidanceImgGPU(E, I, params)
%
%Input:
%       E                               由边缘探测算法得到的边缘置信图；
%       I                                 输入图像；
%       LineRadius                 Line的半径，控制了滤除纹理的空间尺度大小;
%       t                                 角度空间分割的间隔，与90度整除
%Output:
%       G                               得到指导图像；
%       alpha                          alpha.

if(isfield(params, 'LineRadius'))
    LineRadius = params.LineRadius;
else
    LineRadius = 3;
end
if(isfield(params, 'AngleInterval'))
    t = params.AngleInterval;
else
    t = 30;
end
if(isfield(params, 'isShowGuiandceSlant'))
    isShowGuiandceSlant = params.isShowGuiandceSlant;
else
    isShowGuiandceSlant = false;
end
Sigma = LineRadius*10;
%获取图像的亮度通道！
l = rgb2lab(gather(I));
l = l(:,:,1)/100;
% l = I;
G = gpuArray(zeros(size(l)));
Alpha = gpuArray(zeros(size(l)));

if(isShowGuiandceSlant)
    index = 1;
    AlphaTheta = cell(1, 180/t);
end
for theta=0:t:89
    if theta==0
        [GX, GY, AlphaX, AlphaY] = LineShiftGPU(E, l, params);
    else
        [GX, GY, AlphaX, AlphaY] = LineShiftGPU_Slant(E, l, theta, params);
    end
    AlphaX = exp(-Sigma.*AlphaX);
    AlphaY = exp(-Sigma.*AlphaY);    
    if(isShowGuiandceSlant)
        figure, imshow(GX);
        figure, imshow(GY);
        imwrite(gather(GX), ['./SingleTestRlt/GSlant_theta = ', num2str(180 - theta), '.jpg']);
        imwrite(gather(GY), ['./SingleTestRlt/GSlant_theta = ', num2str(90 - theta), '.jpg']);
        imwrite(gather(AlphaX), ['./SingleTestRlt/GSlant_theta = ', num2str(180 - theta), '_Alpha.jpg']);
        imwrite(gather(AlphaY), ['./SingleTestRlt/GSlant_theta = ', num2str(90 - theta), '_Alpha.jpg']);
        AlphaTheta{index} = AlphaX;
        AlphaTheta{index+1} = AlphaY;
        index = index + 2;    
    end
    G = G + bsxfun(@times, GX, AlphaX) + bsxfun(@times, GY, AlphaY);
    Alpha = Alpha + AlphaX + AlphaY;
end
if(isShowGuiandceSlant)
    index = 1;
    for theta=0:t:89 
        AlphaX = AlphaTheta{index}./Alpha;
        AlphaY = AlphaTheta{index+1}./Alpha; 
        imwrite(gather(AlphaX), ['./SingleTestRlt/GSlant_theta = ', num2str(180 - theta), '_Alpha.jpg']);
        imwrite(gather(AlphaY), ['./SingleTestRlt/GSlant_theta = ', num2str(90 - theta), '_Alpha.jpg']);
        index = index + 2;
     end  
end
G = bsxfun(@rdivide, G, Alpha);
imwrite(gather(G), './overall/G.jpg');
if(isShowGuiandceSlant)
    imwrite(gather(G), './SingleTestRlt/GSlant.jpg');
end
% 获得G'
Alpha = bsxfun(@rdivide, Alpha, max(Alpha(:)));
imwrite(gather(Alpha), './overall/Alpha.jpg')
% Alpha = 1 - exp(-Sigma.*Alpha);
B = BoxFilterGPU(l, LineRadius);
imwrite(gather(B), './overall/B.jpg')
G = bsxfun(@times, G,  (1 - Alpha)) + bsxfun(@times, B, Alpha);
imwrite(gather(G), './overall/Gfinal.jpg')
end