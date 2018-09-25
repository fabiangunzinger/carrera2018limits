/* ================================================================================

Replicating carrera2018limits

Fabian Gunzinger

10 September 2018

================================================================================
*/


clear all
set more off
log close _all

cd "/Users/fabiangunzinger/Library/Mobile Documents/com~apple~CloudDocs/fab/projects/data-analysis/carrera2018limits"

log using "code/logs/stata-task.log", replace

global datapath "./data/input/"
global outputpath "./output/"


// =============================================================================
// Figure 1
// =============================================================================

// Histogram of the fraction of people with # visits during treatment period by treatment status

clear
use "${datapath}person_level"




/*

/*** create histograms of the fraction of people with 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14 visits over the two week treatment period by treatment status ****************/

clear
use "${datapath}person_level"
drop if male==.
count if treated==1
gen nobs_treated=r(N)
count if treated==0
gen nobs_control=r(N)
keep visits_during nobs_treated nobs_control
keep in 1/14
sort visits_during
replace visits_during = _n - 1

save "${outputpath}visits_during", replace


clear
use "${datapath}person_level"
drop if male==.
keep if treated==1
gen visits_during_treated = visits_during
collapse (count) visits_during_treated, by(visits_during)
sort visits_during
merge 1:1 visits_during using "${outputpath}visits_during"
drop _merge
replace visits_during_treated = 0 if visits_during_treated==.
gen frac_during_treated = visits_during_treated / nobs_treated
sort visits_during
save "${outputpath}visits_during", replace


clear
use "${datapath}person_level"
drop if male==.
keep if treated==0
gen visits_during_control = visits_during
collapse (count) visits_during_control, by(visits_during)
sort visits_during
merge 1:1 visits_during using "${outputpath}visits_during"
list if _merge==2
drop _merge
replace visits_during_control = 0 if visits_during_control==.
gen frac_during_control = visits_during_control / nobs_control
sort visits_during
save "${outputpath}visits_during", replace
export excel using "${outputpath}Figure1", firstrow(var) replace


log using "${outputpath}\Figure1_rank_sum_test_pdf_days_attending", replace
/*** test for equality of distributions of days attending by treatment status ***/

clear
use "${outputpath}visits_during"
keep visits_during_control 
gen treated = 0
rename visits_during_control visits_during
save "${outputpath}holder", replace 
use "${outputpath}visits_during" 
keep visits_during_treated
gen treated = 1
rename visits_during_treated visits_during
append using  "${outputpath}holder"
ranksum visits_during, by(treated)
log close

erase "${outputpath}visits_during.dta"
erase "${outputpath}holder.dta"
