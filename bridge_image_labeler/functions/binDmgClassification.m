function [ dmgClassification, binClass ] = binDmgClassification( img )
% binDmgClassification takes in an image and promts the user to select 
% whether the image containes damage or no damage to the structure.
%   img - image array (for display purposes)
%   binClass - binary output, 1 = damage and 0 = no damage
%   dmgClassification - string damage classification as damage or no_damage

%%% Begin Function

% Display image for decision making
f = figure();
% Set Figure to be fullscreen, remove toolbar and menu
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
set(gcf, 'Toolbar', 'none', 'Menu', 'none');
imshow(img); % show original image
title('Select the primary material type in the image')

% Prompt user to select the damage or no damge based on button clicks
% Button to select damage
button.damage = uicontrol('Parent',f,'Style','pushbutton','Units',...
            'normalized','Position',[0.1,0.025,0.1,0.05],'String','DAMAGE',...
            'callback',{@checkDamage,f,'damage', 1});
% Button to select no damage       
button.noDamage = uicontrol('Parent',f,'Style','pushbutton','Units',...
            'normalized','Position',[0.8,0.025,0.1,0.05],'String','NO DAMAGE',...
            'callback',{@checkDamage,f,'no_damage', 0});

uiwait % wait for user to select damage or no damage

% set image type based on button click
dmgClassification = getappdata(f,'DamageInfo');
binClass = getappdata(f, 'binClass');

close(f); % close the figure of the original image


function checkDamage(~,~,f,damageInfo, binClass)
    % Function to assign damage information based on button click
    setappdata(f,'DamageInfo',damageInfo);
    setappdata(f, 'binClass', binClass);
    uiresume
end

end

