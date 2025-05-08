* Set the folder containing the .dta files
local folder "C:\Github\BC_dementia_after_cancer\codelists\"  // <-- change this to your folder

* Get list of .dta files in the folder
local filelist : dir "`folder'" files "*.dta"

* Loop through each .dta file
foreach file of local filelist {
    
    * Display progress
    di "Processing: `file'"
    
    * Build full path to input and output files
    local infile = "`folder'\`file'"
    local outfile = subinstr("`file'", ".dta", ".txt", .)
    local outpath = "`folder'\`outfile'"
    
    * Use and export
    use "`infile'", clear
    export delimited using "`outpath'", delimiter(tab) replace
}