close all; clear all;  clc; format compact;

[file, path] = uigetfile('*.jpg','Image Files');

colorImage = imread([path file]);

grayImage = rgb2gray(colorImage);

mserRegions = detectMSERFeatures(grayImage, 'RegionAreaRange',[30 20000], 'ThresholdDelta', 3.5, 'MaxAreaVariation', .15);
mserRegionsPixels = vertcat(cell2mat(mserRegions.PixelList));

mserMask = false(size(grayImage));
ind = sub2ind(size(mserMask), mserRegionsPixels(:,2), mserRegionsPixels(:,1));
mserMask(ind) = true;

edgeMask = edge(grayImage);

edgeMask = bwmorph(edgeMask , 'bridge', 10);
edgeMask = bwmorph(edgeMask , 'fill', 10);
edgeEnhancedMask = imfill(edgeMask,'holes');

edgeEnhancedMask = edgeEnhancedMask + edgeMask;

edgeEnhancedMSERMask = edgeEnhancedMask & mserMask;

connComp = bwconncomp(edgeEnhancedMSERMask);
stats = regionprops(connComp,'Area','Eccentricity','Solidity');

regionFilteredTextMask = edgeEnhancedMSERMask;

regionFilteredTextMask(vertcat(connComp.PixelIdxList{[stats.Eccentricity] > .996})) = 0;
regionFilteredTextMask(vertcat(connComp.PixelIdxList{[stats.Area] < 60})) = 0;
regionFilteredTextMask(vertcat(connComp.PixelIdxList{[stats.Solidity] < .2})) = 0;

se = strel('line', 45, 0);
afterMorphologyMask = imclose(regionFilteredTextMask,se);

areaThreshold = 2500;
connComp = bwconncomp(afterMorphologyMask);
stats = regionprops(connComp,'BoundingBox','Area');
boxes = int32(round(vertcat(stats(vertcat(stats.Area) > areaThreshold).BoundingBox)));
red = uint8([255 0 0]);
green = uint8([0 255 0]);
yellow = uint8([255 255 0]);
shapeInserter1 = vision.ShapeInserter('Shape','Rectangles','BorderColor','Custom','CustomBorderColor',red);
shapeInserter2 = vision.ShapeInserter('Shape','Rectangles','BorderColor','Custom','CustomBorderColor',green);
shapeInserter3 = vision.ShapeInserter('Shape','Rectangles','BorderColor','Custom','CustomBorderColor',yellow);
for i=1:size(boxes,1)
    colorImage = step(shapeInserter1, colorImage, boxes(i,:));
    colorImage = step(shapeInserter2, colorImage, boxes(i,:) + int32([1 1 -2 -2]));
    colorImage = step(shapeInserter3, colorImage, boxes(i,:) + int32([2 2 -3 -3]));
end
imshow(colorImage);