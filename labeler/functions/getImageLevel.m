function [ imgLevel ] = getImageLevel( img )
% getImageLevel Takes in an image and promts the user to select the image
% level.
%   img - image array
%   imgLevel - string representing the selected image level 
%   Material Level - the image only shows material, and it is not clear
%                    what object is being viewed, or the object is not
%                    fully in view
%   Object Level -   the image clearly shows an object/component of the
%                    bridge structure
%   Strucutre Level - the entire structure or the majority of the structure
%                     can be seen in the image




%%% Begin Function

% Display image for decision making
f = figure();
% Set Figure to be fullscreen, remove toolbar and menu
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
set(gcf, 'Toolbar', 'none', 'Menu', 'none');
imshow(img); % show original image
title('Select whether the image is material, object, or structure level')

% Prompt user to select the image level
% Button to specify material level
button.material = uicontrol('Parent',f,'Style','pushbutton','Units',...
            'normalized','Position',[0.1,0.025,0.1,0.05],'String','MATERIAL',...
            'callback',{@selectImgLevel,f,'material'});
% Button to specify object level        
button.object = uicontrol('Parent',f,'Style','pushbutton','Units',...
            'normalized','Position',[0.45,0.025,0.1,0.05],'String','OBJECT',...
            'callback',{@selectImgLevel,f,'object'});
% Button to specify structure level       
button.structure = uicontrol('Parent',f,'Style','pushbutton','Units',...
            'normalized','Position',[0.8,0.025,0.1,0.05],'String','STRUCTURE',...
            'callback',{@selectImgLevel,f,'structure'});
        
button.reject = uicontrol('Parent',f,'Style','pushbutton','Units',...
            'normalized','Position',[0.85,0.9,0.1,0.05],'String','REJECT',...
            'callback',{@selectImgLevel,f,'reject'});

uiwait % wait for user to select image level

% set image type based on button click
imgLevel = getappdata(f,'ImageLevel');

close(f); % close the figure of the original image


function selectImgLevel(~,~,f,imgLevel)
    % Function to assign image level based on button click
    setappdata(f,'ImageLevel',imgLevel);
    uiresume
end

end

