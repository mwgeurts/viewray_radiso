ViewRay Radiation Isocenter Verification
==============

by Mark Geurts <mark.w.geurts@gmail.com>
<br>Copyright &copy; 2015, University of Wisconsin Board of Regents

ViewRay Radiation Isocenter Verification loads Sun Nuclear ArcCHECK&reg; movie files recorded across multiple exposures at different gantry angles and computes the minimum sphere (or circle, see below) that intersects the center of all exposures.  The center of this sphere is the radiation-defined isocenter of the ViewRay&trade; treatment system, while the radius is the positioning accuracy (or _walkout_) of the beam collimation system.  

The concept of radiation isocenter is conventionally regarded as a two dimensional value, due in part to how radiation isocenter is historically measured (using film). In this context, the radius refers only to a circle around which each ray was measured.  This restricts each measurement to only consider a single axis of source motion (collimator, gantry, or couch). In reality, however, the true isocenter location (and minimum radius) is a function of all motion axes and non-coplanarities of a treatment system.  

Because the ArcCHECK measures radiation across a cylinder in space, a three dimenionsal ray can be computed that defines the center the beam for each source position where both the entrance and exit are defined on the detectors.  The radiation isocenter therefore becomes the center of a _sphere_ that represents the location in space from which the smallest sphere intersecting all rays is minimized.  This has the advantage of being able to evaluate all components of source motion at once, and is more realistic of the true three dimensionsal source positioning accuracy of the system.

The graphical user interface has been optimized for ViewRay by providing three panels (with identical controls and analysis) for each ViewRay head.  However, exposures do not need to be limited to a single head (additionally, multiple files can be loaded at once) such that all three heads can be analyzed collectively.  Both methods are recommended in practice; the positioning accuracy of all three heads simultaneously may be more clinically relevant, while analyzing a single head can provide additional insight into systematic MLC calibration errors.  

Finally, by disabling the Tongue and Groove (TG) offset, this tool and the methods used therein are not specific to ViewRay and are capable of analyzing data from any treatment system.  ArcCHECK is a trademark of Sun Nuclear Corporation.  MATLAB&reg; is a registered trademark of MathWorks Inc.

## Contents

* [Installation and Use](README.md#installation-and-use)
* [Compatibility and Requirements](README.md#compatibility-and-requirements)
* [Measurement Instructions](README.md#measurement-instructions)
* [2D Computation Methods](README.md#2d-computation-methods)
* [3D Computation Methods](README.md#3d-computation-methods)
* [MLC Offset](README.md#mlc-offset)

## Installation and Use

To install the most recent release of this application, [download ArcCheckRadIso.mlappinstall from this repository](https://github.com/mwgeurts/viewray_radiso/archive/master.zip), then open MATLAB, select the _Apps_ tab, and click _Install App_.  In the Install App dialog box, browse to the downloaded file and then click _Open_.  Finally, in the App Installer dialog box click _Install_ or _Reinstall_.  If using git, execute `git clone --recursive https://github.com/mwgeurts/viewray_radiso`.

Global configuration variables can be modified by changing the values in `ArcCheckRadIso_OpeningFcn` prior to execution.  A log file will automatically be created in the same directory and can be used for troubleshooting.  For instructions on acquiring the input data and processing in this tool, see [Measurement Instructions](README.md#measurement-instructions). For information about software version and configuration pre-requisities, see [Compatibility and Requirements](README.md#compatibility-and-requirements).

## Compatibility and Requirements

This tool has been tested with ViewRay version 3.5 treatment software and Sun Nuclear Patient software version 6.2.3.5713 on MATLAB 8.3 through 8.5.  The 2D algorithm requires the MATLAB Mapping Toolbox Version 4.0 or later (tested through 4.1), while the 3D algorithm requires the Optimization Toolbox Version 7.0 or later (tested through 7.2).

## Measurement Instructions

The following steps illustrate how to acquire and process radiation isocenter measurements using the Sun Nuclear MR compatible ArcCHECK on a ViewRay treatment system.

### Set up the ArcCHECK

1. Place the SNC ArcCHECK on the treatment couch
2. Connect the ArcCHECK to the Physics Workstation using the PIM and designated cable
3. Launch the SNC Patient software on the Physics Workstation
  1. The SNC Patient application will automatically collect a background reading
4. Place a level along the top of the ArcCHECK and adjust the feet until it reads level
5. Roll the ArcCHECK until it is level using the left and right coronal wall lasers
6. Align the center of the phantom to the lasers in the IEC X, Y, and Z directions
7. Record the current couch position
8. Press the ENABLE and ISO buttons on the Couch Control Panel to move the couch from virtual to mechanical isocenter

### Collect Data

1. On the ViewRay TPDS, select Tools > QA Procedure and select the Calibration tab
2. Select an arbitrary phantom and click Load Phantom
3. Under Beam Setup and Controls, select Head 1
4. Set Delivery Angle to 0 degrees
5. Under MLC Setup, set the following MLC positions: X1/Y1 = -5.25 cm, X2/Y2 = +5.25 cm
6. Click Set Shape to apply the MLC positions
8. Enter 30 seconds as the Beam-On Time
9. Click Prepare Beam Setup
10. Click Enable Beam On
11. On the Treatment Control Panel, wait for the ready light to appear, then press Beam On
12. In the SNC Patient application, select Measure
13. Wait for the beam to be delivered
14. Change the Delivery Angle to 10 degrees
15. Click Prepare Beam Setup
16. Click Enable Beam On
17. On the Treatment Control Panel, wait for the ready light to appear, then press Beam On
18. Wait for the beam to be delivered
19. Repeat the steps above for the remaining angles for Head 1: 0 to 180 degrees in 10 degree increments
  1.  Skip 130 degrees as it will be incident on the couch edge, thereby reducing the quality of the results
20. In the SNC Patient application, select Stop
21. Save the file as _H1 G0 to G180.acm_
22. Repeat for the remaining two heads (Head 2 from 90 to 270, Head 3 from 270 to 90)
  1. Skip 130 and 230 degrees as they will be incident on the couch edge

### Analyze Radiation Isocenter Data

1. Execute the `ArcCheckRadIso` in MATLAB
2. Under Head 1, click Browse to load the SNC ArcCHECK Multi-Frame export _H1 G0 to G180.acm_
3. Continue to load the remaining heads
4. Review the resulting profile comparisons and statistics
  1. Verify that the minimum radius is less than 2 mm
  2. Verify that the IEC X, Y, and Z position of each radius is less than 1 mm and less than 1 mm in any direction from the  isocenter position of the two other heads

## 2D Computation Methods

The algorithm used in `ComputeRadIso()` to determine the minimum radius of a circle intersecting all incident rays is detailed in Depuydt et al, [Computer-aided analysis of star shot films for high-accuracy radiation therapy treatment units](http://www.ncbi.nlm.nih.gov/pubmed/22538289), Phys. Med. Biol. 57 (2012), 2997-3011. The author shows how the minimum radius can be determined from an inscribed circle for the triangle defined by three intersecting rays. Therefore, by computing the inscribed circles for all permutations of three rays from the provided dataset, one can sort the result in ascending radius and stop after the first inscribed circle that intersects all other rays.

In MATLAB, this approach is implemented by first using `nchoosek` to compute all possible triplets of the array of rays. Then, for each triplet, the three intersection points of each ray are computed. Next, a Delauney triangulation object is created using `DT = delaunayTriangulation`, and the inscribed circle is computed using `incenter(DT)`.  Finally, when finding the smallest valid inscribed circle, the intersection of each circle with each ray is tested using `linecirc`.

## 3D Computation Methods

The method used in `ComputeRadIso3d()` to determine the minimum radius of a sphere intersecting all incident rays is a direct search optimization.  Using an initial guess of the ArcCHECK defined isocenter [0, 0, 0], the objective function `maxradius` is minimized.  The objective function computes the largest distance, and therefore the sphere radius, from each ray to a three dimensional point.  

The MATLAB Optimization Toolbox `fminsearch` function is used to optimize the coordinates of the point such that the radius is minimized.  The Nelder-Mead Simplex method used by `fminsearch` is detailed in Lagarias, J.C., J. A. Reeds, M. H. Wright, and P. E. Wright, [Convergence properties of the Nelder-Mead simplex method in low dimensions](http://epubs.siam.org/doi/abs/10.1137/S1052623496303470), SIAM Journal of Optimization 9 (1998), 112-147.

The distance from each ray to the sphere center is computed for each optimization iteration using the formula `norm(cross(p1 - p2, c - p2)) / norm(p1 - p2)`, where `c1` and `p2` are points that lie on the ray and `c` is the center.

## MLC Offset

In addition to computing the radiation isocenter for a set of exposures, the tool computes the distance from isocenter to the central ray perpendicular to the ray, along the MLC X and Y directions.  Termed _MLC Offsets_, these values represent the amount each square MLC field is shifted along the MLC X and Y directions relative to the identified minimum isocenter, and can be used to recalibrate or reposition the ViewRay treatment heads.  In the MLC X direction, a systematic positive or negative shift in offsets suggests that at all angles the MLC is shifted in the same direction, and the radiation isocenter minimum radius could likely be reduced by adjusting the MLC calibration offset value (or zero value).  This is particularly true if the minimum radius is being limited by opposing exposures, where the radius will be limited by the amount of MLC X offset.  In the Y direction, differences in MLC offsets with gantry angle or between heads is suggestive of non-coplanarities in the head(s).
