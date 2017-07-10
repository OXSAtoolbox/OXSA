////////////////////////////////////////////////////////
// RodgersSpectroTools: compiled 31P analysis tool. //
////////////////////////////////////////////////////////

Distributed and created by Chris Rodgers and Will Clarke.


1) Instructions for set up.

Download the MATLAB Compiler Runtime (MCR) software here: http://www.mathworks.co.uk/products/compiler/mcr/  
Under step one you want the option 2014a (8.3) and then choose the relevant operating system.
 
If you don’t know whether you are running 64 or 32 bit (probably 64), please follow the instructions here:
http://windows.microsoft.com/en-gb/windows7/find-out-32-or-64-bit

After installation of this program, please try to run 31P_Analysis_Tool.exe. The program should work as per the video demo included in the .zip file. 
If instead you recieve a runtime error "Unable to find MCR version 8.3", let either of the know as some previous MCR installations conflict with version 8.3.

2) Instuctions for use.
	
On starting the program you will be presented with a small user interface with five buttons and a menu.

If this is the first time running the program please set locations to save scan information and results to when running in automated mode via the "Set enviroment variables" option in the settings menu.
This step is detailed in the attached PDF - "FirstTimeSetup.pdf".

Load: Loads a single dataset in to the main spectroscopy GUI. 

Save scan details: Saves the scan details (location, choice of series and instance and currently selected voxel) to a collection text file. Doing this will enable that specific combination to be run again automatically using run multiple. 

Close all: Closes all windows except the 31P-MRS Loader. Reset for the next scan.

Save and close: Combines both the save scan details and close all buttons.

Run multiple: Automaticly analyses a collection of scans listed in a text file specified using the save buttons. To manually alter the the text files use the "Open folder containing collections" in the settings menu. The results and a log file can be found in the appropriately named folder using the "Open results folder" option in the menu.
 
3) Please do report any bugs, suggested improvements, or when it completely fails to run…
