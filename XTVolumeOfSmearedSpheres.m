function XTVolumeOfSmearedSpheres(aImarisApplicationID)

% Created by Gábor Szegvári in 2019. You are free to use this script or to create derivatives if you attribute it to me properly.
% https://github.com/SzegaX/VolumeOfSmearedSpheres

% connect to Imaris interface
if ~isa(aImarisApplicationID, 'Imaris.IApplicationPrxHelper')
    javaaddpath ImarisLib.jar
    vImarisLib = ImarisLib;
    if ischar(aImarisApplicationID)
        aImarisApplicationID = round(str2double(aImarisApplicationID));
    end
    vImarisApplication = vImarisLib.GetApplication(aImarisApplicationID);
else
    vImarisApplication = aImarisApplicationID;
end

%setting
maskWindowFactor=10;

% detect Surface objects
mb=msgbox('Detecting Surfaces');
vSurpassScene = vImarisApplication.GetSurpassScene;
vNumberOfSurfaces = 0;
vSurfacesList = [];
vSurfacesName = {};
for vIndex = 1:vSurpassScene.GetNumberOfChildren
    vItem = vSurpassScene.GetChild(vIndex-1);
    if vImarisApplication.GetFactory.IsSurfaces(vItem)
        vNumberOfSurfaces = vNumberOfSurfaces + 1;
        vSurfacesList(vNumberOfSurfaces) = vIndex; %#ok<AGROW>
        vSurfacesName{vNumberOfSurfaces} = char(vItem.GetName); %#ok<AGROW>
    end
end
close(mb);

switch vNumberOfSurfaces
    case 0
        ed=errordlg('No surfaces found','XT script error');
        uiwait(ed);
        return
    case 1
        vSurfaceObj = vSurpassScene.GetChild(vSurfacesList(1)-1);
    otherwise
        [vSelection,vOk] = listdlg('ListString',vSurfacesName,...
                                    'PromptString','Select the Surface object to use',...
                                    'ListSize',[200 250],...
                                    'SelectionMode','single');
        if vOk<1, return, end
        vSurfaceObj = vSurpassScene.GetChild(vSurfacesList(vSelection(1))-1);
end
vSurfaceObj = vImarisApplication.GetFactory.ToSurfaces(vSurfaceObj);

%get dataset
vDataSet = vImarisApplication.GetDataSet;
%get sizes
sizeInPixelsX=vDataSet.GetSizeX;
sizeInUnitsX=vDataSet.GetExtendMaxX - vDataSet.GetExtendMinX;
sizeInUnitsY=vDataSet.GetExtendMaxY - vDataSet.GetExtendMinY;
units2pixels=sizeInPixelsX/sizeInUnitsX;

numSurfaces=vSurfaceObj.GetNumberOfSurfaces;
allRadii=[];
vProgressDisplay = waitbar(0,'Estimating original radii..');
for surfaceIdx=0:numSurfaces-1
    centerOfMass=vSurfaceObj.GetCenterOfMass(surfaceIdx);
    minX=double(max(centerOfMass(1)-sizeInUnitsX/maskWindowFactor,vDataSet.GetExtendMinX));
    minY=double(max(centerOfMass(2)-sizeInUnitsY/maskWindowFactor,vDataSet.GetExtendMinY));
    maxX=double(min(centerOfMass(1)+sizeInUnitsX/maskWindowFactor,vDataSet.GetExtendMaxX));
    maxY=double(min(centerOfMass(2)+sizeInUnitsY/maskWindowFactor,vDataSet.GetExtendMaxY));
    pixelsX=round((maxX-minX)*units2pixels);
    pixelsY=round((maxY-minY)*units2pixels);
    vData=vSurfaceObj.GetSingleMask(surfaceIdx, ...
                                    minX,minY,vDataSet.GetExtendMinZ,...
                                    maxX,maxY,vDataSet.GetExtendMaxZ,...
                                    pixelsX,pixelsY,vDataSet.GetSizeZ);
    surfaceRadii=[];
    for i=0:vData.GetSizeZ-1
        [~,radii]=imfindcircles(logical(vData.GetDataSliceBytes(i,0,0)),[1 round(sizeInPixelsX/25)]); %max radius is arbitrary
        surfaceRadii=cat(1,surfaceRadii,radii);
    end
    if isempty(surfaceRadii)
        addValue=NaN;
    else
        addValue=max(surfaceRadii);
    end
    allRadii=cat(1,allRadii,addValue);
    waitbar((surfaceIdx+1)/numSurfaces);
end
allRadiiUnits=allRadii/units2pixels;
allVolumes=4/3*pi*(allRadiiUnits.^3);
vOutput=cat(2,double(vSurfaceObj.GetIds),allVolumes);
close(vProgressDisplay);

% export into csv
cc=regexp(char(vImarisApplication.GetCurrentFileName),'(?<=\\)[^\\]*(?=\.)','match');
[fileName,filePath]=uiputfile(['volumeOfSmearedSpheres_',cc{1},'.xls']);
xlswrite([filePath,fileName],vOutput);
