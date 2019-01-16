function [ objType ] = getObjectType( img )
% getObjectType Takes in an image and promts the user to select the
% dominant object within the image.
%   img - image array
%   objType - string representing the selected object type
%   abutment_column - image predominantly abutment or column vertical
%                     structure
%   girder_soffit - image predominantly shows girder or deck soffit
%                   (underside of bridge structure)
%   deck - image predominantly shows top of the bridge deck
%   oher - image shows object other than stated 




% DETERMINE IMAGE LEVEL (material, object, structure)
f = figure();
% Set Figure to be fullscreen, remove toolbar and menu
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
set(gcf, 'Toolbar', 'none', 'Menu', 'none');
imshow(img); % show original image
title('Select whether the image is material, object, or structure level')

% Prompt user to select the image object type
% Button to specify abutment or column
button.abutment = uicontrol('Parent',f,'Style','pushbutton','Units',...
            'normalized','Position',[0.1,0.025,0.1,0.05],'String','ABUT/COL',...
            'callback',{@selectImgLevel,f,'abutment_column'});
% Button to specify girder or soffit       
button.girder = uicontrol('Parent',f,'Style','pushbutton','Units',...
            'normalized','Position',[0.333,0.025,0.1,0.05],'String','GIRDER/SOFFIT',...
            'callback',{@selectImgLevel,f,'girder_soffit'});
% Button to specify top deck      
button.deck = uicontrol('Parent',f,'Style','pushbutton','Units',...
            'normalized','Position',[0.567,0.025,0.1,0.05],'String','TOP DECK',...
            'callback',{@selectImgLevel,f,'deck'});
% Button to specify other object    
button.other = uicontrol('Parent',f,'Style','pushbutton','Units',...
            'normalized','Position',[0.8,0.025,0.1,0.05],'String','OTHER',...
            'callback',{@selectImgLevel,f,'other'});
        
uiwait % wait for user to select object type

% set image type based on button
objType = getappdata(f,'ObjectType');

close(f); % close the figure of the original image


function selectImgLevel(~,~,f,objType)
    % Function to assign object type based on button click
    setappdata(f,'ObjectType',objType);
    uiresume
end

end

