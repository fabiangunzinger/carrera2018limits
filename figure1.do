/* ============================================================================

Replicates figure 1, table 1 and rank-sum test in carrera2018limits

Fabian Gunzinger

September 2018

===============================================================================
*/


clear all
set more off
log close _all

cd "$cloud/fab/coding/data_analysis/carrera2018limits"

log using "code/logs/stata-task.log", replace

// Manage program
global explore 0
global figure1 0
global ranksum 0
global table1 0


// Macros
global personaldata "./data/input/person_level_stata13"
global visitdata "./data/input/visit_level_stata13"



// =============
// Explore data
// ============= 

if $explore {

clear
use $personaldata


// Overview and duplicates check
codebook, c
duplicates list
misstable sum


// Age by gender
local var age
local options lw(medium)
twoway (kdensity `var' if male == 1, `options') ///
	(kdensity `var' if male == 0, `options'), ///
	legend(label(1 "Men") label(2 "Women"))

	
// Visits
twoway (hist visits_pre, freq) (hist visits_during, freq bc(green)), ///
	legend(label(1 "Before") label(2 "During"))
	

// Balance
local balancevars age male university days_away university student visits_pre schedule_notatall schedule_somewhat schedule_verymuch think_plan_inapp think_plan_not think_plan_maybe think_plan_is_eff

orth_out `balancevars', by(treated) pcompare

}



// =========
// Figure 1
// =========


if $figure1 { 


// Histogram of the fraction of people with # visits during treatment period by treatment status


clear
use $persondata


// Generate person weights for each group

foreach group in treated control {
	count if `group' == 1
	gen obs_`group' = r(N)
	gen weight_`group' = `group' / obs_`group'
}


// Long titels for figure

local title ""Figure 1: Distribution of gym days by treatment status""
local note ""Each pair of bars represents the fraction of participants in both treatment groups that visited the gym for a given number of" "days during the 13-day intervention period.""
local label1 label(1 "Planning (treatment)")
local label2 label(2 "No planning (control)")


// Produce figure

graph bar (sum) weight_treated weight_control, over(visits_during) ///
	legend(`label1' `label2' position(6)) ///
	title(`title', position(12)) ///
	ytitle("Fraction of subjects") ///
	ylabel(#10, format(%4.2f)) ///
	lintensity(0) scale(.8) note(`note')


}


// ===============
// Rank-sum tests 
// ===============


if $ranksum {


// Rank sum test ast in carrera2018limits

clear
use $persondata
gen visits_duringtreated = visits_during if treated == 1
gen visits_duringcontrol = visits_during if control == 1
rename visits_during numberofdays
collapse (count) visits_duringtreated visits_duringcontrol, by(numberofdays)
reshape long visits_during, i(numberofdays) j(treated) string
ranksum visits_during, by(treated)

// I think using the aggregated data is wrong. What we want to rank is the number of gym visits by individual members. Using the aggregated data, the numbers are meaningless in that they do not refer to a number of visits. As long s both groups have the same set of frequencies overall, the ranksum will be the same (example: two perfectly mirrored distributions would have the same ranksum).


// Rank sum test using full sample

clear
use $persondata
ranksum visits_during, by(treated)


}


// ========
// Table 1
// ========


if $table1 {

clear
use $persondata

local backgroundvars "male age university student secondary visits_pre2 days_away schedule_notatall schedule_somewhat schedule_verymuch think_plan_not_eff think_plan_maybe_eff think_plan_is_eff think_plan_inapplic"

orth_out `backgroundvars', by(treated) ///
	pcompare count bdec(2) stars ///
	armlabel("Control" "Treatment")
}

