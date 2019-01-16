function [masks] = image_labeler()
% image_labeler is a two step image labelling software that allows the user
% to select an image (or set of images) and label them for specific defects
% of interest commonly found on reinforced concrete bridges. The image mask
% is saved in a file directory based on the classification answers given in
% this program.
% 
% Pixel-wise labelling of defects of interests is performed in two steps.
% STEP 1, the user moves threshold filter, connectivity filter, and
% median filter sliders to obtain a best estimate of the defect labels. In
% STEP 2, the user is allowed to manually add and remove from the image
% mask to perfect the label.
%
%   Inputs: none; images are selected via GUI
%   Outputs: masks (cell); consisting of matrices of u,v pair pixel locations in
%            image i that correspond to defect location (dimensions u,v,i)
% 
% Copyright 2018 Evan McLaughlin  

clc, close all
addpath(fullfile(pwd,'functions')) % Add path to extra functions
label_dir = 'labeled';

%%% Begin Program

%% Initialize numerical values for logic
visible = 1; infrared = 2;
% specifify the number of defects for segmentation in each image type
visDefects = 4; infraDefects = 1; 
crack = 1; rebar = 2; spall = 3; corrosion_staining = 4; % visible defects 
delamination = 1; % infrared defects
% specify whether or not to save (used for debugging only)
saveFlag = 1;

%% Load and preprocess images for labelling
[imagesRaw,fileNames] = loadImages(); % Load images (in cell array format) for labelling

% Number of entries in the cell array to determine number of images
nImages = size(imagesRaw,1); % Figure out which dimension of images to use (unresolved)


% Preprocess image for labelling
imagesProcessed = imagePreprocess(imagesRaw);

% Initialize cell arrays to store data 
defects = cell(nImages,1);
masks = cell(nImages,1);

%% Main loop for labelling
for ii = 1:nImages % iterate through each selected image
    [imgHeight, imgWidth] = size(imagesProcessed{ii});
    masks{ii} = zeros(imgHeight,imgWidth);
    %%%%% DETERMINE IF IR OR VISIBLE
    f = figure();
    % Set Figure to be fullscreen, remove toolbar and menu
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
    set(gcf, 'Toolbar', 'none', 'Menu', 'none');
    imshow(imagesRaw{ii}); % show original image
    title('Select whether the image is visible spectrum or infrared')
    
    % Prompt user to select if the image is visible or infrared
    % Button to specify visible image type
    button.visible = uicontrol('Parent',f,'Style','pushbutton','Units',...
                'normalized','Position',[0.1,0.025,0.1,0.05],'String','VISIBLE',...
                'callback',{@selectImgType,f,visible,visDefects});
    % Button to specify infrared image type        
    button.IR = uicontrol('Parent',f,'Style','pushbutton','Units',...
                'normalized','Position',[0.8,0.025,0.1,0.05],'String','INFRARED',...
                'callback',{@selectImgType,f,infrared,infraDefects});
    
    uiwait % wait for user to select image type
    
    % set image type based on button
    imgType = getappdata(f,'ImageType');
    if imgType == infrared % take the complement of the white-hot images for labelling
        %imagesProcessed{ii} = imcomplement(imagesProcessed{ii});
        imgTypeText = 'infrared';
    elseif imgType == visible
        imgTypeText = 'visible';
    end
    
    % set number of defects to search for
    numDefects = getappdata(f,'NumberDefects'); 
    
    close(f); % close the figure of the original image
    
    %%%%% DETERMINE IMAGE LEVEL (material, object, structure)
    
    imgLevel = getImageLevel(imagesRaw{ii});
    
    if strcmp(imgLevel, 'material') % If Material
        %%%%% DETERMINE MATERIAL TYPE
        imgMaterial = getMaterialType(imagesRaw{ii}); % Get Material Type
        %%%%% BINARY DAMAGE CLASSIFICATION
        [isDamaged, binClass] = binDmgClassification(imagesRaw{ii}); 
        % Prepare save directory
        saveDir = fullfile(pwd, label_dir, imgTypeText, imgLevel, ...
                           imgMaterial, isDamaged);
    elseif strcmp(imgLevel, 'object')
        %%%%% DETERMINE OBJECT TYPE
        objType = getObjectType(imagesRaw{ii});
        %%%%% BINARY DAMAGE CLASSIFICATION
        [isDamaged, binClass] = binDmgClassification(imagesRaw{ii}); 
        % Prepare save directory
        saveDir = fullfile(pwd, label_dir, imgTypeText, imgLevel, ...
                           objType, isDamaged);
    elseif strcmp(imgLevel, 'structure')
        % Prepare save directory
        saveDir = fullfile(pwd, label_dir, imgTypeText, imgLevel);
        saveDataDir(imagesRaw{ii}, fileNames{ii}, saveDir);
        continue
    elseif strcmp(imgLevel, 'reject')
        % Prepare save directory
        saveDir = fullfile(pwd, label_dir, imgTypeText, imgLevel);
        saveDataDir(imagesRaw{ii}, fileNames{ii}, saveDir);
        continue
    end
    
    if binClass % binClass = 1 represents damaged
    
        for jj = 1:numDefects % iterate through each defect type for labelling

            % Find defect type based on image type and jj iteration #
            if imgType == visible
                if jj == crack 
                    defectType = 'CRACKING';
                elseif jj == rebar
                    defectType = 'EXPOSED REBAR';
                elseif jj == spall
                    defectType = 'SPALLING';
                elseif jj == corrosion_staining
                    defectType = 'CORROSION STAINING';
                end
            elseif imgType == infrared
                if jj == delamination
                    defectType = 'DELAMINATION';
                end
            end

            % detect defects using image thresholding and size filtering
            [defects{ii,jj}, continueFlag] = detectDefects(imagesProcessed{ii}, defectType);
            if continueFlag % if defect of type jj is visible in the image
                % Enter manual adjustment function
                indices = masks{ii} == 0; 
                tempMask = manualAdjust(imagesRaw{ii},defects{ii,jj}, defectType);
                tempMask = imcomplement(tempMask);
                masks{ii}(indices) = masks{ii}(indices) ...
                                   + tempMask(indices) * jj;
            end

        end
        if saveFlag % Check if user specified to save image masks
            saveMask(fileNames{ii}, masks{ii});
        end
        saveDataDir(imagesRaw{ii}, fileNames{ii}, saveDir);    
    else % there is no damage
        saveDataDir(imagesRaw{ii}, fileNames{ii}, saveDir);
    end
end

    function selectImgType(~,~,f,imgType,numDefects)
        % Function to select image type (vision or infrared) based on button press
        setappdata(f,'ImageType',imgType);
        setappdata(f,'NumberDefects',numDefects);
        uiresume
    end

    function [images,fileNames] = loadImages()
        % Opens file dialog, allowing user to specify location and files to
        % open
        [fileNames,path] = uigetfile({'*.jpg;*.jpeg','JPEG Files (*.jpg,*.jpeg)';
            '*.png','Portable Network Graphics (*.png)';
            '*.gif','Graphics Interchance Format (*.gif)'},...
            'Select one or more image files','MultiSelect','on');
        
        % Including an exception for if only a single file is opened where
        % fileNames becomes a char of length nx1 where n is number of chars
        % New cell array created to force fileNames to write to a cell
        % array to avoid issue of "cell contents assigned to non-cell array
        % object"
        if (ischar(fileNames) || isstring(fileNames))
            fileNamesTemp = cell(1,1);
            fileNamesTemp{1} = fileNames;
            fileNames = fileNamesTemp;
        end
        
        images = cell(length(fileNames),1);
        for kk = 1:length(images)
            fileName = strcat(path,fileNames{kk});
            images{kk} = imread(fileName);
        end
    end

    function imageOut = imagePreprocess(imageIn)
        % Takes in cell array imageIn of images and outputs cell array
        % imageOut of processes images
        % Processing consists of converting the image to grayscale for thesholding 
        imageOut = cell(size(imageIn));
        for i = 1:size(imageIn)
            imageTemp = rgb2gray(imageIn{i}); % convert image to grayscale
            imageTemp = imsharpen(imageTemp);
            %imageTemp = histeq(imageTemp);
            %imageTemp = imgaussfilt(imageTemp,2);
            imageOut{i} = imageTemp;
        end
    end
    
    function [defects,continueFlag] = detectDefects(img, defectType)
        % Opening GUI to find image thresholds
        [threshold, filtThreshold, medFilterSize, complementFlag] = openThresholdGUI(img);

        % Check if the threshold doesnt exits
        if threshold == 0 && filtThreshold == 0
            defects = ones(size(img)); % blank mask
            continueFlag = 0; % exit loop flag
        else % read selected threshold and filter, continue to manual adjustments
            defects = detection(img,threshold,filtThreshold,medFilterSize, complementFlag);
            continueFlag = 1;
        end

        function [threshold, filtThreshold, medFilterSize, complementFlag] = openThresholdGUI(imageIn)
            % Figure f is present in all stages of function as the GUI window and is
            % passed into each function to allow writing to appdata
            f = figure;
            % always set figure to fullscreen and remove the top toolbar
            set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
            set(gcf, 'Toolbar', 'none', 'Menu', 'none');

            % ThresholdValue is only set when slider is moved, so threshold is defined
            % here to allow for the event where someone presses next without moving
            % slider
            threshold = 0.5; % Initialize threshold
            filtThreshold = 0; % Initialize filter
            medFilterSize = 1; % Default median filter size
            
            % Convert to binary black and white image
            imageBW = imbinarize(imageIn,'adaptive','Sensitivity',threshold);
            % Take the complement of the black and white image
            imageComp = imcomplement(imageBW);
            % Filter portions of the mask that are below a certain pixel
            % size
            imageCompFilt = bwareaopen(imageComp,filtThreshold);
            % Take the complement to convert back to the original image
            % style
            imageFilt = imcomplement(imageCompFilt);
            imageFilt = medfilt2(imageFilt, [medFilterSize,medFilterSize]);
            
            a = subplot(1,2,1);
            imshow(histeq(imageIn)); % First plot show the image for reference
            b = subplot(1,2,2);
            h = imshow(imageFilt); % Second plot show the current mask
            title({'Use threshold (top) and size filter (bottom) sliders to highlight', defectType})
            set(a, 'Position', [0.005,0,0.4925,1]);
            set(b, 'Position', [0.5025,0,0.4925,1]);
            
            % Create slide control for thresholding
            slideControlThresh = uicontrol('Parent',f,'Style','slider','Units',...
                'normalized','Position',[0.25,0.12,0.5,0.025],'value',threshold,...
                'min',0,'max',1.0, 'Tag', 'threshSlider', 'String', 'threshold',...
                'callback',{@sliderCallbackThresh,h,imageIn,f});
            % Add annotation to explain slide filter
            annotation('textbox', [0.25,0.145,0.5,0.025], 'String', ...
                'THRESHOLD FILTER TO BINARIZE GRAYSCALE IMAGE', 'EdgeColor', 'none', ...
                'HorizontalAlignment', 'center')
            
            % Create slide control to filter min pixel group size
            slideControlFilt = uicontrol('Parent',f,'Style','slider','Units',...
                'normalized','Position',[0.25,0.07,0.5,0.025],'value',filtThreshold,...
                'min',0,'max',2000, 'Tag', 'filtSlider',...
                'callback',{@sliderCallbackFilt,h,imageIn,f});
            % Add annotation to explain slide filter
            annotation('textbox', [0.25,0.095,0.5,0.025], 'String', ...
                'SIZE FILTER TO REMOVE SMALL PIXEL CLUSTERS', 'EdgeColor', 'none', ...
                'HorizontalAlignment', 'center')
            
            % Create slide control for median convolutional filter
            medianControlFilt = uicontrol('Parent',f,'Style','slider','Units',...
                'normalized','Position',[0.25,0.02,0.5,0.025],'value',medFilterSize,...
                'min',1,'max',20, 'Tag', 'medianSlider',...
                'callback',{@sliderCallbackMed,h,imageIn,f});
            % Add annotation to explain slide filter
            annotation('textbox', [0.25,0.045,0.5,0.025], 'String', ...
                'MEDIAN FILTER TO SMOOTH EDGES AND FILL GAPS', 'EdgeColor', 'none', ...
                'HorizontalAlignment', 'center')
            
            % Create button to continue to manual adjustment
            nextButton = uicontrol('Parent',f,'Style','pushbutton','Units',...
                'normalized','Position',[0.825,0.02,0.15,0.05],'String', 'CONTINUE',...
                'callback',{@nextFig});
            
            % Create slide control to filter min pixel group size
            complementFilt = uicontrol('Parent',f,'Style','slider','Units',...
                'normalized','Position',[0.025,0.09,0.15,0.05],'value',0,...
                'min',0,'max',1, 'Tag', 'complementFlag',...
                'callback',{@getImgComplement,h,imageIn,f});
            % Add annotation to explain slide filter
            annotation('textbox', [0.025,0.145,0.15,0.025], 'String', ...
                'IMCOMPLEMENT SWITCH', 'EdgeColor', 'none', ...
                'HorizontalAlignment', 'center')
            
            % Create button to specify that the defect does not exist in
            % the image
            button.noDamage = uicontrol('Parent',f,'Style','pushbutton','Units',...
                'normalized','Position',[0.025,0.02,0.15,0.05],'String',['NO ', defectType],...
                'callback',{@noDamage,f});
            
            uiwait %uiwait used to wait for the next button in figure
            
            % If slider was moved, temp will have a value and will need to be assigned
            % here, but if temp is empty then slider was not moved and default as above
            % retained
            if ~isempty(getappdata(f,'exitCommand')) % check if exit button was pressed
                threshold = 0; filtThreshold = 0; 
                close(f)
                return % return command to parent function
            end
            
            temp = getappdata(f,'ThresholdValue');
            if ~isempty(temp) % 0.5 is default value given in determineThreshold
                threshold = temp;
            end

            % Similar to above, filtThreshold only used in event person doesn't move
            % slider
            temp = getappdata(f,'FilterThresholdValue');
            % If slider was moved, temp will have a value and will need to be assigned
            % here, but if temp is empty then slider was not moved and default as above
            % retained
            if ~isempty(temp)
                filtThreshold = temp;
            end

            temp = getappdata(f, 'MedFilterSize');
            if ~isempty(temp)
                medFilterSize = temp;
            end
            
            temp = getappdata(f, 'imComplement');
            if ~isempty(temp)
                complementFlag = temp;
            else
                complementFlag = 0;
            end
            
            close(f) % always close figure after to avoid clutter
        end

         function getImgComplement(hObject,~,h,imageIn,f)
            % Callback function to replot mask after threshold adjustment
            tempObj = findobj('Tag', 'filtSlider'); % find current pixel filter
            sensitivity = double(uint16(tempObj.Value)); % read filter value
            tempObj2 = findobj('Tag', 'medianSlider'); % find med filter 
            medFiltSize = round(tempObj2.Value); % read med filter size
            tempObj3 = findobj('Tag', 'threshSlider'); % read thresh filt
            threshold = tempObj3.Value; % read theshold value
            % Plot the same as originally done
            imageBW = imbinarize(imageIn,'adaptive','Sensitivity',threshold);
            if hObject.Value % if complement specified
                imageBW = imcomplement(imageBW);
            end
            
            % removing area requires the complement
            imageBW = imcomplement(imageBW);
            imageBW = bwareaopen(imageBW,sensitivity);
            imageBW = imcomplement(imageBW);
            
            imageBW = medfilt2(imageBW, [medFiltSize,medFiltSize]);
            h.CData = imageBW;
            setappdata(f,'imComplement',ceil(hObject.Value))
        end
        
        
        function sliderCallbackThresh(hObject,~,h,imageIn,f)
            % Callback function to replot mask after threshold adjustment
            tempObj = findobj('Tag', 'filtSlider'); % find current pixel filter
            sensitivity = double(uint16(tempObj.Value)); % read filter value
            tempObj2 = findobj('Tag', 'medianSlider'); % find med filter 
            medFiltSize = round(tempObj2.Value); % read med filter size
            tempObj3 = findobj('Tag', 'complementFlag');
            complementFlag = tempObj3.Value;
            threshold = hObject.Value; % read theshold value
            % Plot the same as originally done
            imageBW = imbinarize(imageIn,'adaptive','Sensitivity',threshold);
            if complementFlag
                imageBW = imcomplement(imageBW);
            end
            
            % removing area requires the complement
            imageBW = imcomplement(imageBW);
            imageBW = bwareaopen(imageBW,sensitivity);
            imageBW = imcomplement(imageBW);
            
            imageBW = medfilt2(imageBW, [medFiltSize,medFiltSize]);
            h.CData = imageBW;
            setappdata(f,'ThresholdValue',threshold)
        end

        function sliderCallbackFilt(hObject,~,h,imageIn,f)
            % Callback function to replot mask after pixel filter adjustment
            tempObj = findobj('Tag', 'threshSlider'); % find current threshold
            threshold = tempObj.Value; % read current threshold value
            tempObj2 = findobj('Tag', 'medianSlider'); % find med filter
            medFiltSize = round(tempObj2.Value); % read med filter size
            tempObj3 = findobj('Tag', 'complementFlag');
            complementFlag = tempObj3.Value;
            sensitivity = double(uint16(hObject.Value)); % read current pixel filter
            % Plot the same as originally done
            imageBW = imbinarize(imageIn,'adaptive','Sensitivity',threshold);
            if complementFlag
                imageBW = imcomplement(imageBW);
            end
            
            % removing area requires the complement
            imageBW = imcomplement(imageBW);
            imageBW = bwareaopen(imageBW,sensitivity);
            imageBW = imcomplement(imageBW);
            
            imageBW = medfilt2(imageBW, [medFiltSize,medFiltSize]);
            h.CData = imageBW;
            setappdata(f,'FilterThresholdValue',sensitivity)
        end

        function sliderCallbackMed(hObject,~,h,imageIn,f)
            % Callback function to replot mask after pixel filter adjustment
            tempObj = findobj('Tag', 'threshSlider'); % find current threshold
            threshold = tempObj.Value; % read current threshold value
            tempObj2 = findobj('Tag', 'filtSlider'); % find size filter
            sensitivity = double(uint16(tempObj2.Value)); % read size filter values
            tempObj3 = findobj('Tag', 'complementFlag');
            complementFlag = tempObj3.Value;
            medFiltSize = round(hObject.Value); % read current pixel filter
            % Plot the same as originally done
            imageBW = imbinarize(imageIn,'adaptive','Sensitivity',threshold);
            if complementFlag
                imageBW = imcomplement(imageBW);
            end
            
            % removing area requires the complement
            imageBW = imcomplement(imageBW);
            imageBW = bwareaopen(imageBW,sensitivity);
            imageBW = imcomplement(imageBW);
            
            imageBW = medfilt2(imageBW, [medFiltSize,medFiltSize]);
            h.CData = imageBW;
            setappdata(f,'MedFilterSize',medFiltSize)
        end
        
        function nextFig(~,~)
            uiresume % resume if continue button is pressed
        end

        function noDamage(~,~,f)
            setappdata(f,'exitCommand',1) % Tell program to skip this defect
            uiresume % resume
        end
        
        function rawMask = detection(imageIn,threshold,filtThreshold,medFilterSize,complementFlag)
            % function to generate the mask based on threshold and filter
            imageBW = imbinarize(imageIn,'adaptive','Sensitivity',threshold);
            if complementFlag
                imageBW = imcomplement(imageBW);
            end
            
            % need to apply complement before removing area
            imageBW = imcomplement(imageBW);
            imageBW = bwareaopen(imageBW,filtThreshold);
            imageBW = imcomplement(imageBW);

            rawMask = medfilt2(imageBW, [medFilterSize, medFilterSize]);
            % rawMask outputs as binary image
        end 
    end

    function maskOut = manualAdjust(imageIn, maskIn, defectType)
        % Function to manual add to or remove from the auto-generated mask
        curMask = maskIn;
        prevMask = maskIn;
        f = figure();
        set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);

        while true
            if ~exist('f')
                f = figure();
                set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
                %set(gcf, 'Toolbar', 'none', 'Menu', 'none');
            end
            clf
            set(gcf, 'Toolbar', 'figure', 'Menu', 'figure');
            % Clear current figure, plot current mask
            a = subplot(1,2,1);
            imshow(histeq(imageIn));
            b = subplot(1,2,2);
            imshow(imageIn), hold on
            % Plot the mask over the current image for visual
            BB = image(curMask, 'CDataMapping', 'Scaled', 'AlphaData', 0.3*imcomplement(curMask));
            colormap autumn
            set(a, 'Position', [0.005,0,0.4925,1]);
            set(b, 'Position', [0.5025,0,0.4925,1]);
            title({'Select function to manually adjust mask for', defectType})
            
            % Setup buttons for different action to manually adjust
            addFree = 1; addRect = 2; addPoly = 3;
            removeFree = 4; removeRect = 5; removePoly = 6;
            setUndo = 7; setDone = 8;
            
            % Add button to add freehand area to mask
            button.addFree = uicontrol('Parent',f,'Style','pushbutton','Units',...
                'normalized','Position',[0.05,0.085,0.15,0.05],'String','Add Free',...
                'callback',{@setAdjustType,f,addFree});
            % Add button to add rectangular area to mask
            button.addRect = uicontrol('Parent',f,'Style','pushbutton','Units',...
                'normalized','Position',[0.25,0.085,0.15,0.05],'String','Add Rect',...
                'callback',{@setAdjustType,f,addRect});
            button.addPoly = uicontrol('Parent',f,'Style','pushbutton','Units',...
                'normalized','Position',[0.45,0.085,0.15,0.05],'String','Add Poly',...
                'callback',{@setAdjustType,f,addPoly});
            
            % Remove Button to remove freehand are from mask
            button.removeFree = uicontrol('Parent',f,'Style','pushbutton','Units',...
                'normalized','Position',[0.05,0.025,0.15,0.05],'String','Remove Free',...
                'callback',{@setAdjustType,f,removeFree});
            % Remove button to remove rectangular area from mask
            button.removeRect = uicontrol('Parent',f,'Style','pushbutton','Units',...
                'normalized','Position',[0.25,0.025,0.15,0.05],'String','Remove Rect',...
                'callback',{@setAdjustType,f,removeRect});
            button.removePoly = uicontrol('Parent',f,'Style','pushbutton','Units',...
                'normalized','Position',[0.45,0.025,0.15,0.05],'String','Remove Poly',...
                'callback',{@setAdjustType,f,removePoly});
            
            % Undo button to undo most recent change
            button.undoButton = uicontrol('Parent',f,'Style','pushbutton','Units',...
                'normalized','Position',[0.8,0.025,0.075,0.05],'String','Undo',...
                'callback',{@setAdjustType,f,setUndo});
            
            % Done button to save and exit
            button.doneButton = uicontrol('Parent',f,'Style','pushbutton','Units',...
                'normalized','Position',[0.9,0.025,0.075,0.05],'String','Done',...
                'callback',{@setAdjustType,f,setDone});
             
            uiwait % pause until button has been pressed
             
            choice = getappdata(f,'DecisionValue'); % set choice based on button press
           
            if choice == addFree % check if the add free button has been pressed
                plotSettings(defectType);
                h = imfreehand(); % freehand drawing
                [curMask, prevMask] = addToMask(h, BB, curMask);
            elseif choice == addRect % check if the add rect button has been pressed
                plotSettings(defectType);
                h = imrect(); % rectangular drawing
                [curMask, prevMask] = addToMask(h, BB, curMask);
            elseif choice == addPoly % check if the add poly button has been pressed
                plotSettings(defectType);
                h = impoly(); % polygon drawing
                [curMask, prevMask] = addToMask(h, BB, curMask);
            elseif choice == removeFree % check if the remove free button has been pressed
                plotSettings(defectType);
                h = imfreehand(); % freehand drawing
                [curMask, prevMask] = removeFromMask(h, BB, curMask);
            elseif choice == removeRect % check if the remove rect button has been pressed
                plotSettings(defectType);
                h = imrect(); % rectangular drawing
                [curMask, prevMask] = removeFromMask(h, BB, curMask);
            elseif choice == removePoly % check if the remove polygon button has been pressed
                plotSettings(defectType);
                h = impoly(); % polygon drawing
                [curMask, prevMask] = removeFromMask(h, BB, curMask);
            elseif choice == setUndo % check if the undo button has been pressed
                curMask = prevMask;
            elseif choice == setDone % check if the exit button has been pressed
                maskOut = curMask;
                close(f)
                
                % Ask user to confirm they are done editing the mask
                keepEditing = 1; saveAndContinue = 2; 
                f = figure();
                set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
                imshow(imageIn), hold on
                % Plot the mask over the current image for visual
                image(curMask, 'CDataMapping', 'Scaled', 'AlphaData', 0.3*imcomplement(curMask));
                colormap autumn
                title(['Are you sure you want to save the current ', ...
                    defectType, ' image mask?'])
                
                % Button to go back and keep editing mask       
                button.continueEdit = uicontrol('Parent',f,'Style','pushbutton','Units',...
                'normalized','Position',[0.1,0.025,0.1,0.05],'String','GO BACK',...
                'callback',{@checkSave,f,keepEditing});
                % Button to confirm done editing mask - save and continue
                button.saveMask = uicontrol('Parent',f,'Style','pushbutton','Units',...
                'normalized','Position',[0.8,0.025,0.1,0.05],'String','SAVE',...
                'callback',{@checkSave,f,saveAndContinue});
            
                uiwait
            
                saveCheck = getappdata(f, 'saveCheck');
                
                if saveCheck == keepEditing
                    close(f), clear f
                    continue
                elseif saveCheck == saveAndContinue
                    close(f), clear f
                    break
                end
                
            end
        end  
        
        function plotSettings(defectType)
            % Function to adjust the plot settings once a button is pressed
            title({'Use the cursor to draw a section of pixels to add to the mask for',...
                    defectType}); % add explantory title 
            % remove buttons to prevent double press    
            set(findall(gcf, 'Type', 'UIControl'), 'Visible', 'off');
            % turn toolbar off to prevent zooming or other interation
            set(gcf, 'Toolbar', 'none', 'Menu', 'none');
        end   
        
        function [curMask, prevMask] = removeFromMask(h, axes, curMask)
            % function to remove selected ROI from current mask
            if ~isempty(h)
                BW = createMask(h, axes);
                prevMask = curMask; % save current mask
                curMask(BW == 1) = 1;
            else
                close(f), clear f % reset figure to deal with errors from h being empty
                prevMask = curMask;
            end
        end
        
        function [curMask, prevMask] = addToMask(h, axes, curMask)
            % function to add selected ROI to current mask
            if ~isempty(h)
                BW = createMask(h, axes);
                prevMask = curMask; % save current mask
                curMask(BW == 1) = 0;
            else
                close(f), clear f % reset figure to deal with errors from h being empty
                prevMask = curMask;
            end
        end
        
        function setAdjustType(~,~,f,decisionVal)
            % Callback function to return which button was selected
            setappdata(f,'DecisionValue',decisionVal)
            uiresume
        end
        
    end

    function checkSave(~,~,f,saveCheck)
        % Function to check if the user is confirmed done with the mask
        setappdata(f,'saveCheck',saveCheck)
        uiresume
    end

    function saveDataDir(rawImage, rawFileName, saveDir)
        if ~exist(saveDir) % check if directory exists
            mkdir(saveDir) % if doesn't, make directory
        end
        imwrite(rawImage, fullfile(saveDir,rawFileName));
        
        typeHandle = regexp(rawFileName, '\w*\w_', 'match'); % read type from image name
        if strcmp(typeHandle{1},'vis_') % if img is visible
            folderName = 'visible';
        elseif strcmp(typeHandle{1},'ir_') % if img is infrared
            folderName = 'infrared';
        end
        
        % open data from current 
        fid = fopen(['completed/',folderName,'.txt'], 'a+');
        fnames = textscan(fid, '%s');
        completedMasks = fnames{1};
        if sum(strcmp(completedMasks, rawFileName)) < 1
            % write textfile to show that mask has been saved 
            fprintf(fid, [rawFileName,'\n']); 
            fclose(fid);
        end
    end
        
    function saveMask(rawFileName, mask)
    % Save Function for each individual mask
    typeHandle = regexp(rawFileName, '\w*\w_', 'match'); % read type from image name
    digitHandle = regexp(rawFileName, '\d*', 'match'); % read number from image name
        if strcmp(typeHandle{1},'vis_') % if img is visible
            folderName = 'visible';
        elseif strcmp(typeHandle{1},'ir_') % if img is infrared
            folderName = 'infrared';
        end
        fileName = [typeHandle{1},digitHandle{1},...
                    '_mask','.png']; % save file name
        savePath = fullfile(pwd,'masks', folderName); % save path
        if ~exist(savePath) % check if directory exists
            mkdir(savePath); % if doesn't exist, make directory
        end
        % write .png image file
        imwrite(uint8(mask), fullfile(savePath,fileName), 'WriteMode', 'overwrite');
          
    end
end