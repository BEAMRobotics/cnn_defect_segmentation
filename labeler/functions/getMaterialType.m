function [ imgMaterial ] = getMaterialType( img )
% getMaterialType Takes in an image and promts the user to select the image
% material type
%   img - image array
%   imgMaterial - string representing the selected image material type
%   Concrete - the image is primarily concrete
%   Asphalt -  the image is primarily asphaly
%   Other - The image is primarily another material not of interest


%%% Begin Function

% Display image for decision making
f = figure();
% Set Figure to be fullscreen, remove toolbar and menu
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
set(gcf, 'Toolbar', 'none', 'Menu', 'none');
imshow(img); % show original image
title('Select the primary material type in the image')

% Prompt user to select the dominant material type
% Button to specify concrete material
button.concrete = uicontrol('Parent',f,'Style','pushbutton','Units',...
            'normalized','Position',[0.1,0.025,0.1,0.05],'String','CONCRETE',...
            'callback',{@selectImgLevel,f,'concrete'});
% Button to specify asphalt material        
button.asphalt = uicontrol('Parent',f,'Style','pushbutton','Units',...
            'normalized','Position',[0.45,0.025,0.1,0.05],'String','ASPHALT',...
            'callback',{@selectImgLevel,f,'asphalt'});
% Button to specify other material      
button.other = uicontrol('Parent',f,'Style','pushbutton','Units',...
            'normalized','Position',[0.8,0.025,0.1,0.05],'String','OTHER',...
            'callback',{@selectImgLevel,f,'other'});

uiwait % wait for user to select material type

% set image type based on button
imgMaterial = getappdata(f,'ImageMaterial');

close(f); % close the figure of the original image


function selectImgLevel(~,~,f,imgMaterial)
    % Function to assign dominant material type based on button press
    setappdata(f,'ImageMaterial',imgMaterial);
    uiresume
end

end

