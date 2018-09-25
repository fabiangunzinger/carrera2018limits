/* ================================================================================

Replicating carrera2018limits

Fabian Gunzinger

10 September 2018

================================================================================
*/


clear all
set more off
log close _all

cd "$cloud/fab/coding/data_analysis/carrera2018limits"

log using "code/logs/stata-task.log", replace

// Manage program
global explore 0
global transform 1

// Macros
global data "./data/input/person_level_stata13"

// =============
// Explore data
// ============= 

if $explore {

clear
use $data


// Overview and duplicates check
codebook, c
duplicates list


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



// =============================
// Transform data to panel data
// =============================





