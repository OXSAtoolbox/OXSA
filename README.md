# OXSA (Open-source eXtensible Spectroscopy Analysis) toolbox
This folder contains the OXSA (Open-source eXtensible Spectroscopy Analysis) toolbox for developing pipelines for spectroscopy analysis. It includes code for loading Siemens spectroscopy data, and for spectral fitting/analysis.

Version: 2.1
Release date: 2024-07-08

Contact: ctr28@cam.ac.uk or chris@rodgers.org.uk

Note that the Rodgers lab have an in-house version of OXSA ("RodgersSpectroTools") that contains many extensions particularly for use with Siemens 7T MRIs (Magnetom and Terra) on VB17 and VE-series software baselines but which is less clearly organised than OXSA. Please get in touch if this would help you.

If you use this software in an academic publication, please include the following, or similar, text in your methods section:

"OXSA Matlab code was used for analysis, as previously described [1]."

1.	Purvis LAB, Clarke WT, Biasiolli L, Valkovic L, Robson MD, Rodgers CT. OXSA: An open-source magnetic resonance spectroscopy analysis toolbox in MATLAB. Plos One. 2017; 12(9):e0185356.

If the included AMARES-based algorithm is used, the following paper should also be cited:

Vanhamme L, van den Boogaart A, Van Huffel S. Improved method for accurate and efficient quantification of MRS data with use of prior knowledge. J Magn Reson. 1997; 129(1):35-43.  https://doi.org/10.1006/jmre.1997.1244

AMARES builds on VARPRO so for deeper level modifications it will be very helpful to read:
J W van der Veen 1, R de Beer, P R Luyten, D van Ormondt. Accurate quantification of in vivo 31P NMR signals using the variable projection method and prior knowledge. Magn Reson Med. 1988 Jan;6(1):92-8. https://doi.org/10.1002/mrm.1910060111

Or this blog gives a readable introduction to VARPRO: https://geo-ant.github.io/blog/2020/variable-projection-part-1-fundamentals/

## License

This is released for NON-COMMERCIAL USE ONLY. See LICENSE.TXT for further details.

## Documentation

- [OXSA Fitting Guide v1.0](./documentation/OXSA%20Fitting%20Guide%20v1.0.pdf) - using the functions included in the AMARES package.
- [Loading data v1.0](./documentation/Loading%20data%20v1.pdf) - using Spectro classes and GUIs to load data.
- [OXSA v1.0](./documentation/OXSA%20v1.pdf) - details about the Spectro classes.
- [OXSA v2.0 update](./documentation/OXSA%20v2%20update.pdf) - Notes on the restructuring for OXSA v2.


## Examples

There are several examples included to show the methods of loading and running data. 
Each of these will change to the appropriate directory when run.

## Tests

The /test/ folder contains a few basic test scripts. The aim is to include additional scripts so that all testing is fully automated.
In the /test/MonteCarlo/ folder there are several scripts and data files that should allow the comparison of updates to OXSA fitting.

## Version information

v1.0 - 2017-07-10 - Initial release

v2.0 - 2018-05-30 - Restructuring to allow simpler inclusion of additional prior knowledge. Added the ability to fit using Voigt lineshapes.
					Some folder reorganisation so that the OXSA code can be run as part of the OCMR in-house processing pipeline. Several other
					minor changes to update all code to match current in-house versions.

v2.1 - 2024-07-08 - Update contact details and amend the name.

