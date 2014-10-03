ViewRay Radiation Isocenter Verification
==============

by Mark Geurts <mark.w.geurts@gmail.com>
<br>Copyright &copy; 2014, University of Wisconsin Board of Regents

ArcCheckRadIso.m loads Sun Nuclear ArcCHECK movie files recorded across multiple exposures at different gantry angles and computes the minimum sphere (or circle, see below) that intersects the center of all exposures.  The center of this sphere is the radiation-defined isocenter of the ViewRay treatment system, while the radius is the range of _walkout_, or positioning accuracy of the beam collimation system.  


## Compatibility and Requirements

This tool has been tested with ViewRay version 3.5 treatment software, Sun Nuclear Patient software version 6.2.3.5713, and MATLAB R2014a.  The 2D algorithm requires the MATLAB Mapping Toolbox Version 4.0 or later, while the 3D algorithm requires the Optimization Toolbox Version 7.0 or later.
