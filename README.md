# VolumeOfSmearedSpheres
Imaris XT MatLab script for the approximation of the volume of spheres distorted in a Z-stack.

The .m file is the source. It is not necessary if you want to add this extension to Imaris.
You need to place the .exe and .xml files in the appropriate Imaris folders. The new option will appear in the menu of Imaris.

This code works on a Surfaces object. If there is only one such object, it is automatically selected, otherwise you are prompted to choose.
The code assumes that the object represents spherical items that are distorted because they moved during the capture of a Z-stack image. This also means that all slices in the XY direction are assumed to be circles. Volume is approximated based on the largest such circle. Thus it is possible that it is underestimated, but not that it is overestimated.
The output is a .csv file listing for all items their Surface ID (col 1) and approximated volume (col 2). You will be prompted to select a directory and name for this file.

Created by Gábor Szegvári in 2019. You are free to use this script or to create derivatives if you attribute it to me properly.
