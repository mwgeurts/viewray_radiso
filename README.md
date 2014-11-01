ViewRay Radiation Isocenter Verification
==============

by Mark Geurts <mark.w.geurts@gmail.com>
<br>Copyright &copy; 2014, University of Wisconsin Board of Regents

ArcCheckRadIso.m loads Sun Nuclear ArcCHECK movie files recorded across multiple exposures at different gantry angles and computes the minimum sphere (or circle, see below) that intersects the center of all exposures.  The center of this sphere is the radiation-defined isocenter of the ViewRay treatment system, while the radius is the positioning accuracy (or _walkout_) of the beam collimation system.  

The concept of radiation isocenter is conventionally regarded as a two dimensional value, due in part to how radiation isocenter is historically measured (using film). In this context, the radius refers only to a circle around which each ray was measured.  This restricts each measurement to only consider a single axis of source motion (collimator, gantry, or couch). In reality, however, the true isocenter location (and minimum radius) is a function of all motion axes and non-coplanarities of a treatment system.  

Because the ArcCHECK measures radiation across a cylinder in space, a three dimenionsal ray can be computed that defines the center the beam for each source position where both the entrance and exit are defined on the detectors.  The radiation isocenter therefore becomes the center of a _sphere_ that represents the location in space from which the smallest sphere intersecting all rays is minimized.  This has the advantage of being able to evaluate all components of source motion at once, and is more realistic of the true three dimensionsal source positioning accuracy of the system.

The graphical user interface has been optimized for ViewRay by providing three panels (with identical controls and analysis) for each ViewRay head.  However, exposures do not need to be limited to a single head (additionally, multiple files can be loaded at once) such that all three heads can be analyzed collectively.  Both methods are recommended in practice; the positioning accuracy of all three heads simultaneously may be more clinically relevant, while analyzing a single head can provide additional insight into systematic MLC calibration errors.  

Finally, by disabling the TG offset, this tool and the methods used therein are not specific to ViewRay and are capable of analyzing data from any treatment system.

## Contents

* [Installation and Use](README.md#installation-and-use)
* [Measurement Instructions](README.md#measurement-instructions)
* [2D Computation Methods](README.md#2D-computation-methods)
* [3D Computation Methods](README.md#3D-computation-methods)
* [MLC Offset](README.md#mlc-offset)
* [Compatibility and Requirements](README.md#compatibility-and-requirements)

## Installation and Use

To run this application, copy all MATLAB .m and .fig files into a directory with read/write access and then execute ArcCheckRadIso.m.  Global configuration variables can be modified by changing the values in `ArcCheckRadIso_OpeningFcn` prior to execution.  A log file will automatically be created in the same directory and can be used for troubleshooting.  For instructions on acquiring the input data, see [Measurement Instructions](README.md#measurement-instructions). For information about software version and configuration pre-requisities, see [Compatibility and Requirements](README.md#compatibility-and-requirements).

## Measurement Instructions

The following steps illustrate how to acquire and process radiation isocenter measurements using the Sun Nuclear MR compatible ArcCHECK on a ViewRay treatment system.

## MLC Offset

In addition to computing the radiation isocenter for a set of exposures, the tool computes the distance from isocenter to the central ray perpendicular to the ray, along the MLC X and Y directions.  Termed _MLC Offsets_, these values represent the amount each square MLC field is shifted along the MLC X and Y directions relative to the identified minimum isocenter, and can be used to recalibrate or reposition the ViewRay treatment heads.  In the MLC X direction, a systematic positive or negative shift in offsets suggests that at all angles the MLC is shifted in the same direction, and the radiation isocenter minimum radius could likely be reduced by adjusting the MLC calibration offset value (or zero value).  This is particularly true if the minimum radius is being limited by opposing exposures, where the radius will be limited by the amount of MLC X offset.  In the Y direction, differences in MLC offsets with gantry angle or between heads is suggestive of non-coplanarities in the head(s).

## 2D Computation Methods

The algorithm used in ComputeRadIso.m to determine the minimum radius of a circle intersecting all incident rays is detailed in Depuydt et al, [Computer-aided analysis of star shot films for high-accuracy radiation therapy treatment units](http://www.ncbi.nlm.nih.gov/pubmed/22538289), Phys. Med. Biol. 57 (2012), 2997-3011. The author shows how the minimum circle is in fact the inscribed circle for the triangle defined by three intersecting rays. Therefore, by computing the inscribed circle for all permutations of three rays from the provided dataset, one can sort the result in ascending radius and stop after the first inscribed circle that intersects all other rays.

In MATLAB, this approach is implemented by first using `nchoosek` to compute all possible triplets of the array of rays. Then, for each triplet, the three intersection points of each ray are computed. Next, a Delauney triangulation object is created using `DT = delaunayTriangulation`, and the inscribed circle is computed using `incenter(DT)`.  Finally, when finding the smallest valid inscribed circle, the intersection of each circle with each ray is tested using `linecirc`.

## 3D Computation Methods

The method used in ComputeRadIso3d.m to determine the minimum radius of a sphere intersecting all incident rays is a direct search optimization.  Using an initial guess of the ArcCHECK defined isocenter [0, 0, 0], the objective function `maxradius` is minimized.  The objective function computes the largest distance, and therefore the sphere radius, from each ray to a three dimensional point.  

The MATLAB Optimization Toolbox `fminsearch` function is used to optimize the coordinates of the point such that the radius is minimized.  The Nelder-Mead Simplex method used by `fminsearch` is detailed in Lagarias, J.C., J. A. Reeds, M. H. Wright, and P. E. Wright, [Convergence properties of the Nelder-Mead simplex method in low dimensions](http://epubs.siam.org/doi/abs/10.1137/S1052623496303470), SIAM Journal of Optimization 9 (1998), 112-147.

The distance from each ray to the sphere center is computed for each optimization iteration using the formula `norm(cross(p1 - p2, c - p2)) / norm(p1 - p2)`, where `c1` and `p2` are points that lie on the ray and `c` is the center.

## Compatibility and Requirements

This tool has been tested with ViewRay version 3.5 treatment software and Sun Nuclear Patient software version 6.2.3.5713 on MATLAB 8.3 and 8.4.  The 2D algorithm requires the MATLAB Mapping Toolbox Version 4.0 or later (tested through 4.0.2), while the 3D algorithm requires the Optimization Toolbox Version 7.0 or later (tested through 7.1).
