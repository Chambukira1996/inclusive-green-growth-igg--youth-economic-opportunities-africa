********************************************************************
*Can Inclusive Green Growth Unlock Economic Opportunities for the Youth in Africa? Evidence from the labour market and income-based wealth accumulation outcomes 
*Authors: Madalitso Chambukira, Andrew Jamali and Daniel Mwapasa
*Institution: National Planning Commission of Malawi


*Main empirical analysis:
*1. Data preparation
*2. PCA-based IGG index
*3. Descriptive statistics
*4. Multicollinearity diagnostics
*5. Cross-sectional dependence tests
*6. Slope heterogeneity tests
*7. CIPS panel unit-root tests
*8. Two-way fixed-effects models
*9. Two-way fixed-effects model with a log transformed income variable for robustness check
*10. Dynamic FE for robustness check
*11. First-difference estimator for robustness check
*12. Quantile heterogeneity analysis for robustness check
*13. The Present Value of Prospective Lifetime Labour Income (PVPLLI) model-implied calculations

*Dataset:
*N = 54 African countries
*T = 24 years, 1999–2023
*Observations = 1,350

********************************************************************/
clear all
set more off
set scheme s2color
set linesize 255
version 19


********************************************************************************
* SETTING UP WORKING DIRECTORIES
********************************************************************************

* Set working directory 
cd "C:\Users\LENOVO\Downloads\AFRICA AGGRE DATA\panel dataset for African countries\panel_data_African_countries\data and STATA do files"

* Create working directories
capture mkdir "Logs"
capture mkdir "Tables"
capture mkdir "Figures"
capture mkdir "Figures\Income_Group_Trends"
capture mkdir "Data"

* Load the dataset 
use "C:\Users\LENOVO\Downloads\AFRICA AGGRE DATA\panel dataset for African countries\panel_data_African_countries\data and STATA do files\Panel data_African countries.dta", clear

* Create the log file
capture log close
log using "C:\Users\LENOVO\Downloads\AFRICA AGGRE DATA\panel dataset for African countries\panel_data_African_countries\data and STATA do files\ 18th August 2026_FE analysis of youth bulge and youth demographic dividends in Africa.log", replace

********************************************************************
* INSTALL REQUIRED PACKAGES
********************************************************************

local packages estout outreg2 coefplot xtcsd xtcd2 xtscc xtabond2 xtqreg mmqreg  xtcips ivreg2

foreach pkg of local packages {
    capture which `pkg'
    if _rc {
        capture noisily ssc install `pkg', replace
    }
}

capture which asdoc
if _rc != 0 {
    ssc install asdoc, replace
}

capture which factortest
if _rc != 0 {
    ssc install factortest, replace
}

capture which schemepack
if _rc != 0 {
    ssc install schemepack, replace
}

net sj 3-2 st0039       
net install st0039
ssc install xthst

* Set scheme for better graphics
set scheme s2color

********************************************************************
* DATA EXPLORATION
********************************************************************
describe
summarize year country_id

**** Verify panel structure ****

isid country_id year
xtset country_id year, yearly
xtdescribe


assert year >= 1999
assert year <= 2023

********************************************************************
* VARIABLE NAME HARMONISATION
********************************************************************

*The following block creates standard names used in the analysis. It first checks whether the corresponding variable exists.*

capture confirm variable urban_pop_growth_rate
if !_rc rename urban_pop_growth_rate urban_growth

capture confirm variable urban_pop_growth
if !_rc rename urban_pop_growth urban_growth

capture confirm variable real_labincome_per_young_person
if !_rc rename real_labincome_per_young_person real_income_youth

capture confirm variable real_labincome_per_youth
if !_rc rename real_labincome_per_youth real_income_youth

capture confirm variable real_labourincome_growth_per_young_person
if !_rc rename real_labourincome_growth_per_young_person income_growth_youth

capture confirm variable real_labourincome_growth_youth
if !_rc rename real_labourincome_growth_youth income_growth_youth

capture confirm variable Total_youthpop
if !_rc rename Total_youthpop youth_population

capture confirm variable Total_youthpop
if _rc {
    capture confirm variable Total_youthpop
    if !_rc rename Total_youthpop youth_population
}

capture confirm variable gov_effectiveness_score
if !_rc rename gov_effectiveness_score gov_effectiveness

capture confirm variable gov_effective_score
if !_rc rename gov_effective_score gov_effectiveness

capture confirm variable control_corruptScore
if !_rc rename control_corruptScore control_corruption

capture confirm variable RuleofLawGovernancescore
if !_rc rename RuleofLawGovernancescore rule_of_law

capture confirm variable RuleofLawGovernance_score
if !_rc rename RuleofLawGovernance_score rule_of_law

capture confirm variable urban_pop_growth_rate
if !_rc rename urban_pop_growth_rate urban_growth

capture confirm variable agriculture_value_added
if !_rc rename agriculture_value_added agriculture_va

capture confirm variable agri_va_gdp
if !_rc rename agri_va_gdp agriculture_va

capture confirm variable manuf_va_gdp
if !_rc rename manuf_va_gdp manufacturing_va

capture confirm variable serv_va_gdp
if !_rc rename serv_va_gdp services_va

capture confirm variable domestic_credit
if !_rc rename domestic_credit financial_depth

capture confirm variable internet_users
if !_rc rename internet_users digitalisation

********************************************************************
*CHECK REQUIRED VARIABLES
********************************************************************

local required "country_id year youth_neet unemp_youth real_income_youth youth_population inflation trade fdi_net hc urban_growth financial_depth digitalisation agriculture_va manufacturing_va services_va gov_effectiveness control_corruption PS_score VA_score RQ_score rule_of_law"

foreach v of local required {
    capture confirm variable `v'
    if _rc {
        display as error "ERROR: Variable `v' is missing."
    }
    else {
        display "Variable `v' found."
    }
}

********************************************************************
*LOG AND TRANSFORM VARIABLES
********************************************************************

gen ln_youth_population = ln(youth_population) if youth_population > 0

gen ln_real_income_youth = ln(real_income_youth) if real_income_youth > 0

gen lag_inflation = L.inflation
recode lag_inflation (.=0)

label variable ln_youth_population "Log of youth population, individuals aged 15–24"
label variable ln_real_income_youth "Log of real labour income-earnings per young person"

*------------------------------------------------------------*
* Create clean country identifier
*------------------------------------------------------------*
gen country1 = country_name

* Define country value labels
label define country1 5   "Algeria" 8   "Angola" 24  "Benin" 29  "Botswana" 34  "Burkina Faso" 35  "Burundi" 36  "Cabo Verde" 38  "Cameroon" 42  "Central African Republic" 44  "Chad" 49  "Comoros" 50  "Congo, Dem Rep" 51  "Congo, Rep" 53  "Cote d'Ivoire" 60  "Djibouti" 68  "Egypt, Arab Rep" 70  "Equatorial Guinea" 71  "Eritrea" 73  "Eswatini" 74  "Ethiopia" 85  "Gabon" 86  "Gambia, The" 89  "Ghana" 96  "Guinea" 97  "Guinea-Bissau" 123 "Kenya" 138 "Lesotho" 139 "Liberia" 140 "Libya" 148 "Madagascar" 149 "Malawi" 152 "Mali" 155 "Mauritania" 156 "Mauritius" 167 "Morocco" 168 "Mozambique" 170 "Namibia" 177 "Niger" 178 "Nigeria" 203 "Rwanda" 206 "Sao Tome and Principe" 208 "Senegal" 210 "Seychelles" 211 "Sierra Leone" 218 "Somalia, Fed Rep" 219 "South Africa" 222 "South Sudan" 232 "Sudan" 238 "Tanzania" 241 "Togo" 244 "Tunisia" 249 "Uganda" 264 "Zambia" 265 "Zimbabwe"

* Attach the value label
label values country1 country1

* Variable label
label variable country1 "Country1 identifier"

tab country1, missing
order country1, after(country_name)

********************************************************************
* CREATE REGIONAL CLASSIFICATION
********************************************************************

capture drop region

gen byte region = .

********************************************************************
* WEST AFRICA
* Cote d'Ivoire     53
* Benin             24
* Burkina Faso      34
* Gambia             86
* Ghana              89
* Guinea             96
* Guinea-Bissau      97
* Liberia            139
* Mali              152
* Mauritania        155
* Niger             177
* Nigeria            178
* Senegal            208
* Sierra Leone       211
* Togo               241
* Cabo Verde         36
********************************************************************

replace region = 1 if inlist(country_name, 53, 24, 34, 86, 89, 96, 97, 139, 152, 155, 177, 178, 208, 211, 241, 36)

********************************************************************
* EAST AFRICA
*
* Burundi             35
* Comoros             49
* Djibouti             60
* Eritrea              71
* Ethiopia             74
* Kenya               123
* Rwanda              203
* Somalia             218
* South Sudan         222
* Tanzania             238
* Uganda               249
********************************************************************

replace region = 2 if inlist(country_name, 35, 49, 60, 71, 74, 123, 203, 218, 222, 238, 249)

********************************************************************
* SOUTHERN AFRICA
* Angola                8
* Botswana             29
* Eswatini              73
* Lesotho              138
* Madagascar           148
* Malawi               149
* Mauritius             156
* Mozambique            168
* Namibia               170
* Seychelles             210
* South Africa           219
* Zambia                 264
* Zimbabwe               265
********************************************************************

replace region = 3 if inlist(country_name, 8, 29, 73, 138, 148, 149, 156, 168, 170, 210, 219, 264, 265)

********************************************************************
* NORTH AFRICA
*
* Algeria               5
* Egypt                 68
* Libya                140
* Morocco              167
* Sudan                232
* Tunisia              244
********************************************************************

replace region = 4 if inlist(country_name, 5, 68, 140, 167, 232, 244)

********************************************************************
* CENTRAL AFRICA
*
* Cameroon               38
* Central African Rep.   42
* Chad                    44
* DR Congo                50
* Congo Rep.              51
* Equatorial Guinea       70
* Gabon                   85
* Sao Tome & Principe    206
********************************************************************

replace region = 5 if inlist(country_name, 38, 42, 44, 50, 51, 70, 85, 206)

********************************************************************
* DEFINE REGION LABELS
********************************************************************

capture label drop region_lbl

label define region_lbl 1 "West Africa" 2 "East Africa" 3 "Southern Africa" 4 "North Africa" 5 "Central Africa"

label values region region_lbl

label variable region "African regional classification"

tab region, gen(REGION)

********************************************************************
* CREATE SADC MEMBER STATE VARIABLE
********************************************************************

capture drop sadc

gen byte sadc = 0

********************************************************************
* SADC COUNTRIES PRESENT IN THE SAMPLE
*
* Angola                 8
* Botswana              29
* Comoros               49
* DR Congo              50
* Eswatini              73
* Lesotho              138
* Madagascar            148
* Malawi                149
* Mauritius              156
* Mozambique             168
* Namibia                170
* Seychelles              210
* South Africa            219
* Tanzania                238
* Zambia                  264
* Zimbabwe                265
********************************************************************/

replace sadc = 1 if inlist(country_name, 8, 29, 49, 50, 73, 138, 148, 149, 156, 168, 170, 210, 219, 238, 264, 265)

********************************************************************
* DEFINE SADC LABELS
********************************************************************
capture label drop sadc_lbl

label define sadc_lbl 0 "Non-SADC" 1 "SADC"

label values sadc sadc_lbl

label variable sadc "SADC member state=1, otherwise=0"

tab country1 region, missing

********************************************************************
* CHECK FOR COUNTRIES WITHOUT A REGION
********************************************************************
count if missing(region)
list country_name country1 if missing(region)

********************************************************************
* CHECK REGIONAL FREQUENCIES
********************************************************************
tab region, missing
tab sadc
tab country1 sadc, missing

********************************************************************
*CONSTRUCTION OF IGG INDEX USING PCA
********************************************************************

* Socioeconomic sustainability indicators
global IGG_SOC fertility health_exp infant_mort water_safe sanit_safe undernourish pop_density GNIpercapitaPPPconstant20 AfricaInfrastructureDevelopmen gini_index_wiid life_expect

* Environmental sustainability indicators
global IGG_ENV forest_area arable_land pm25 fisheries_prod nat_resource_rent clean_cooking fossil_fuel_energy renewable_energy Mortalityfromexposuretoambie Welfarecostsofprematuremorta Mortalityambientozone Welfarecost_ambientozone CarbonintensityofGDPkgCO2e MethaneCH4emissionstotal temperature_change_c Grossvalueaddedatbasicprice

* Combine all indicators
global igg_indicators $IGG_SOC $IGG_ENV

* Display available indicators
des $igg_indicators

********************** Factor test of inter-correlations **********************
factortest $igg_indicators

********************** Correlation Matrix **********************
quietly estpost correlate $igg_indicators, matrix listwise
esttab using "Tables/Table_A1_IGG_Correlation.rtf", unstack not noobs compress replace title("Appendix Table A1: Correlation Matrix of IGG Indicators")

* Principal component analysis (PCA)
pca $igg_indicators

* Screeplot of eigenvalues
screeplot, yline(1) ytitle("Eigenvalues") xtitle("Number of IGG Components") title("Scree Plot of IGG Components") name(scree_graph, replace)
graph export "Figures/Figure_Scree_Plot.png", width(1200) height(800) replace

* Principal component analysis with eigenvalue > 1
pca $igg_indicators, mineigen(1)

* Component rotations
rotate, varimax

* Loadings/scores of the components
estat loadings

* Predict IGG score
predict igg, score

label var igg "Inclusive Green Growth index"

* KMO measure of sampling adequacy
estat kmo

* Summary of IGG
sum igg, detail

********************** Figure: IGG by Country **********************
capture confirm variable country_name
if _rc == 0 {
    graph hbar igg, over(country1, sort(1) descending label(labsize(vsmall))) blabel(bar, format(%3.2f) position(outside) size(vsmall)) ytitle("Inclusive Green Growth Index") title("Inclusive Green Growth by Country", size(medium)) bargap(10) graphregion(color(white)) plotregion(color(white))
    graph export "Figures/Figure1_IGG_bycountry.png", replace width(1200) height(800)
}

********************** Annual Mean Graphs **********************
preserve
collapse (mean) igg unemp_youth youth_neet real_income_youth, by(year)
format year %ty

graph bar igg, over(year, gap(15) label(angle(45) labsize(vsmall))) bar(1, color(navy)) ytitle("Mean Inclusive Green Growth Index") title("Average Inclusive Green Growth among African Countries") legend(off) graphregion(color(white)) bgcolor(white) name(g_igg, replace)
graph export "Figures/g_igg.png", replace width(2400)

graph hbar unemp_youth, over(year, gap(15) label(angle(45) labsize(vsmall))) bar(1, color(navy)) ytitle("Mean Youth Unemployment rate (%)") title("Average Youth Unemployment rate among African Countries") legend(off) graphregion(color(white)) bgcolor(white) name(g_unemp, replace)
graph export "Figures/g_unemp.png", replace width(2400)

graph bar youth_neet, over(year, gap(15) label(angle(45) labsize(vsmall))) bar(1, color(navy)) ytitle("Mean Youth NEET rate (%)") title("Average Youth NEET rate among African Countries") legend(off) graphregion(color(white)) bgcolor(white) name(g_neet, replace)
graph export "Figures/g_neet.png", replace width(2400)

graph bar real_income_youth, over(year, gap(15) label(angle(45) labsize(vsmall))) bar(1, color(navy)) ytitle("Annual Real Labour Income-Earnings per Young Person (US$)", size(vsmall)) title("Average Youth Real Labour Income-Earnings per Young Person among African Countries", size(small)) legend(off) graphregion(color(white)) bgcolor(white) name(g_income, replace)
graph export "Figures/g_income.png", replace width(2400)
restore

********************************************************************
* DESCRIPTIVE STATISTICS
********************************************************************

global outcomes youth_neet unemp_youth real_income_youth

global controls igg ln_youth_population inflation lag_inflation trade fdi_net hc urban_growth financial_depth digitalisation agriculture_va manufacturing_va services_va gov_effectiveness control_corruption PS_score VA_score rule_of_law RQ_score

estpost sum $outcomes $controls, detail

capture program drop xtsum2
program define xtsum2, eclass
    syntax varlist
    local matall
    local obw
    foreach var of local varlist {
        quietly xtsum `var'
        tempname mat_`var'
        matrix `mat_`var'' = J(3,5,.)
        matrix `mat_`var''[1,1] = (`r(mean)', `r(sd)', `r(min)', `r(max)', `r(N)')
        matrix `mat_`var''[2,1] = (., `r(sd_b)', `r(min_b)', `r(max_b)', `r(n)')
        matrix `mat_`var''[3,1] = (., `r(sd_w)', `r(min_w)', `r(max_w)', `r(Tbar)')
        matrix colnames `mat_`var'' = Mean "Std. Dev." Min Max "N/n/T-bar"
        matrix rownames `mat_`var'' = `var' " " " "
        local matall `matall' `mat_`var''
        local obw `obw' overall between within
    }
    if wordcount("`varlist'") > 1 {
        local matall = subinstr("`matall'", " ", " \ ", .)
        matrix allmat = (`matall')
        ereturn matrix mat_all = allmat
    }
    else {
        ereturn matrix mat_all = `mat_`varlist''
    }
    ereturn local obw "`obw'"
end
xtsum2 $outcomes $controls
esttab e(mat_all) using "Tables/xtsum_table.rtf", replace rtf title("Panel Data Descriptive Statistics") mlabels(none) labcol2(`e(obw)') varlabels(r2 " " r3 " ") collabels("Mean" "Std. Dev." "Min" "Max" "N/n/T-bar") noobs nonumber b(%9.2f)

********************************************************************
* PAIRWISE CORRELATIONS AND MULTICOLLINEARITY TESTS
********************************************************************
global controls igg ln_youth_population inflation lag_inflation trade fdi_net hc urban_growth financial_depth digitalisation agriculture_va manufacturing_va services_va gov_effectiveness control_corruption PS_score VA_score rule_of_law RQ_score

quietly estpost correlate youth_neet $controls, matrix listwise
esttab using "Tables/Table_A2.1_Pairwise Correlation_Matrix.rtf", replace unstack not noobs compress title("Appendix Table A2. Pairwise Correlation Matrix")

quietly estpost correlate unemp_youth $controls, matrix listwise
esttab using "Tables/Table_A2.2_Pairwise Correlation_Matrix.rtf", replace unstack not noobs compress title("Appendix Table A2. Pairwise Correlation Matrix")

quietly estpost correlate real_income_youth $controls, matrix listwise
esttab using "Tables/Table_A2.3_Pairwise Correlation_Matrix.rtf", replace unstack not noobs compress title("Appendix Table A2. Pairwise Correlation Matrix")

*VIF is evaluated using pooled OLS as a diagnostic only. It is not the final estimator.*
reg youth_neet igg ln_youth_population inflation lag_inflation trade fdi_net hc urban_growth financial_depth digitalisation agriculture_va manufacturing_va services_va gov_effectiveness control_corruption PS_score VA_score rule_of_law RQ_score i.year

estat vif

reg unemp_youth  igg ln_youth_population inflation lag_inflation trade fdi_net hc urban_growth financial_depth digitalisation agriculture_va manufacturing_va services_va gov_effectiveness control_corruption PS_score VA_score rule_of_law RQ_score i.year

estat vif

reg real_income_youth  igg ln_youth_population inflation lag_inflation trade fdi_net hc urban_growth financial_depth digitalisation agriculture_va manufacturing_va services_va gov_effectiveness control_corruption PS_score VA_score rule_of_law RQ_score i.year

estat vif

*** Testing of endogeneity *****
** Testing whether inclusive green growth index variable is endogenous or not ************
ivregress 2sls youth_neet (igg= l.igg l2.igg) ln_youth_population inflation trade fdi_net hc urban_growth financial_depth digitalisation agriculture_va manufacturing_va services_va gov_effectiveness control_corruption PS_score VA_score rule_of_law RQ_score
estat endogenous
estat firststage
estat overid

ivregress 2sls unemp_youth (igg= l.igg l2.igg) ln_youth_population inflation trade fdi_net hc urban_growth financial_depth digitalisation agriculture_va manufacturing_va services_va gov_effectiveness control_corruption PS_score VA_score rule_of_law RQ_score
estat endogenous
estat firststage
estat overid

ivregress 2sls real_income_youth (igg= l.igg l2.igg) ln_youth_population inflation trade fdi_net hc urban_growth financial_depth digitalisation agriculture_va manufacturing_va services_va gov_effectiveness control_corruption PS_score VA_score rule_of_law RQ_score
estat endogenous
estat firststage
estat overid

********************************************************************
* BASELINE FE MODEL REGRESSORS
********************************************************************

global xvars igg ln_youth_population inflation lag_inflation trade fdi_net hc urban_growth financial_depth digitalisation agriculture_va manufacturing_va services_va gov_effectiveness control_corruption PS_score VA_score rule_of_law RQ_score

global interactions c.igg#c.ln_youth_population c.igg#c.hc c.igg#c.financial_depth c.igg#c.digitalisation c.igg#c.agriculture_va c.igg#c.manufacturing_va c.igg#c.services_va c.igg#c.gov_effectiveness c.igg#c.control_corruption c.igg#c.PS_score c.igg#c.VA_score c.igg#c.rule_of_law c.igg#c.RQ_score

********************************************************************
* CROSS-SECTIONAL DEPENDENCE TESTS
********************************************************************

*Estimate a two-way FE model first and test residual dependence.*

xtreg youth_neet $xvars i.year, fe vce(cluster country_id)
predict resid_neet, e

capture noisily xtcsd, pesaran abs
capture noisily xtcsd, frees
capture noisily xtcd2 resid_neet

xtreg unemp_youth $xvars i.year, fe vce(cluster country_id)
predict resid_unemp, e

capture noisily xtcsd, pesaran abs
capture noisily xtcsd, frees
capture noisily xtcd2 resid_unemp

xtreg real_income_youth $xvars i.year, fe vce(cluster country_id)
predict resid_income, e

capture noisily xtcsd, pesaran abs
capture noisily xtcsd, frees
capture noisily xtcd2 resid_income

********************************************************************
*SERIAL CORRELATION AND SLOPE HETEROGENEITY
********************************************************************

capture noisily xtserial youth_neet $xvars
capture noisily xtserial unemp_youth $xvars
capture noisily xtserial real_income_youth $xvars

*Pesaran–Yamagata slope homogeneity test.*

capture noisily xthst youth_neet $xvars
capture noisily xthst unemp_youth $xvars
capture noisily xthst real_income_youth $xvars

capture noisily xthst youth_neet $xvars, hac
capture noisily xthst unemp_youth $xvars, hac
capture noisily xthst real_income_youth $xvars, hac

********************************************************************
*SECOND-GENERATION PANEL UNIT-ROOT TESTS
********************************************************************

foreach y in youth_neet unemp_youth real_income_youth igg ln_youth_population inflation trade fdi_net hc urban_growth financial_depth digitalisation agriculture_va manufacturing_va services_va {

    display "=================================================="
    display "CIPS test for variable: `y'"
    capture noisily xtcips `y', maxlags(1) bglags(1)
}

** Second-generation panel cointegration tests ****
ssc install xtwest
xtwest unemp_youth igg ln_youth_population hc financial_depth digitalisation trade, constant lags(0) leads(0) bootstrap(100)

xtwest real_income_youth igg ln_youth_population hc financial_depth digitalisation trade, constant lags(0) leads(0) bootstrap(100)

********************************************************************************
* HAUSMAN AND MUNDLAK TESTS
********************************************************************************

*===============================================================================
* Hausman Tests (FE vs RE)
*===============================================================================
global xvars igg ln_youth_population inflation lag_inflation trade fdi_net hc urban_growth financial_depth digitalisation agriculture_va manufacturing_va services_va gov_effectiveness control_corruption PS_score VA_score rule_of_law RQ_score
global interactions c.igg#c.ln_youth_population c.igg#c.hc c.igg#c.financial_depth c.igg#c.digitalisation c.igg#c.agriculture_va c.igg#c.manufacturing_va c.igg#c.services_va c.igg#c.gov_effectiveness c.igg#c.control_corruption c.igg#c.PS_score c.igg#c.VA_score c.igg#c.rule_of_law c.igg#c.RQ_score

* Youth NEET rate 
quietly xtreg youth_neet $xvars $interactions i.year, fe
estimates store fe_neet2 

quietly xtreg youth_neet $xvars $interactions i.year, re
estimates store re_neet2

hausman fe_neet2 re_neet2, sigmamore

* Youth Unemployment rate
quietly xtreg unemp_youth $xvars $interactions i.year, fe
estimates store fe_unemp2

quietly xtreg unemp_youth $xvars $interactions i.year, re
estimates store re_unemp2

hausman fe_unemp2 re_unemp2, sigmamore

* Annual Real Labour Income earned per young person (US$)
quietly xtreg real_income_youth $xvars $interactions i.year, fe
estimates store fe_income2

quietly xtreg real_income_youth $xvars $interactions i.year, re
estimates store re_income2

hausman fe_income2 re_income2, sigmamore

*===============================================================================
* Mundlak Tests (CRE)
*===============================================================================

* Youth NEET Mundlak
quietly xtreg youth_neet $xvars $interactions i.year, cre

estat mundlak

* Youth Unemployment Mundlak
quietly xtreg unemp_youth  $xvars $interactions, cre

estat mundlak

* Annual Real Labour Income earned per young person (US$) Mundlak
quietly xtreg real_income_youth $xvars $interactions i.year, cre

estat mundlak

******** Robustness check using an alternative dependent variable************
xtreg ln_real_income_youth $xvars $interactions i.year, fe
estimates store fe_lnincome

xtreg ln_real_income_youth $xvars $interactions i.year, re
estimates store re_lnincome

hausman fe_lnincome re_lnincome, sigmamore

xtreg ln_real_income_youth $xvars $interactions i.year, cre
estat mundlak

***************************************************************************************************************************************
*MAIN ESTIMATOR: TWO-WAY FIXED-EFFECTS REGRESSION MODEL and Random Effects model is also estimated for the Youth NEET outcome variable
***************************************************************************************************************************************
*Driscoll Kraay Standard errors have used to control for heteroskedasticity, serial correlation and cross-sectional dependence****
ssc install xtscc

global xvars igg ln_youth_population inflation lag_inflation trade fdi_net hc urban_growth financial_depth digitalisation agriculture_va manufacturing_va services_va gov_effectiveness control_corruption PS_score VA_score rule_of_law RQ_score
global interactions c.igg#c.ln_youth_population c.igg#c.hc c.igg#c.financial_depth c.igg#c.digitalisation c.igg#c.agriculture_va c.igg#c.manufacturing_va c.igg#c.services_va c.igg#c.gov_effectiveness c.igg#c.control_corruption c.igg#c.PS_score c.igg#c.VA_score c.igg#c.rule_of_law c.igg#c.RQ_score

**** Model 1: Youth NEET ****

xtscc youth_neet $xvars $interactions i.year, re 

estimates store RE_NEET
*Wald test for joint significance
test $xvars $interactions
estadd scalar wald_chi2 = r(chi2)
estadd scalar wald_df = r(df)
estadd scalar wald_p = r(p)

xtscc youth_neet $xvars $interactions i.year, fe 

estimates store FE_NEET
*F-test for joint significance
test $xvars $interactions
estadd scalar f_FE = r(F)
estadd scalar f_df1 = r(df)
estadd scalar f_df2 = r(df_r)

**** Model 2: Youth unemployment ****

xtscc unemp_youth $xvars $interactions i.year, fe 

estimates store FE_UNEMP
*F-test for joint significance
test $xvars $interactions
estadd scalar f_FE = r(F)
estadd scalar f_df1 = r(df)
estadd scalar f_df2 = r(df_r)

**** Model 3: Real income per young person ****

xtscc real_income_youth $xvars $interactions i.year, fe 

estimates store FE_INCOME
*F-test for joint significance
test $xvars $interactions
estadd scalar f_FE = r(F)
estadd scalar f_df1 = r(df)
estadd scalar f_df2 = r(df_r)

********************************************************************************
* EXPORT TABLE
********************************************************************************
esttab RE_NEET FE_NEET FE_UNEMP FE_INCOME using "Tables\Table2_Main_FE_Results.rtf", replace se star(* 0.10 ** 0.05 *** 0.01) compress label mtitles("Random Effects Estimate Results of Youth NEET rate (%)" "Fixed Effects Estimate Results of Youth NEET rate (%)" "Fixed Effects Estimate Results of Youth Unemployment rate (%)" "Fixed Effects Estimate Results of Real Income-earnings per Young person (US$)") stats(N N_g r2_w wald_chi2 f_FE, labels("Observations" "Countries" "Within R-squared" "Wald chi2(56)" "F-statistic") fmt(%9.2fc %9.2fc %9.2fc %9.2fc %9.2fc)) sfmt(%9.2fc %9.2fc %9.2fc %9.2fc) title("Table 2. Random Effects GLS regression and Two-way Fixed-effects Estimate Results") addnotes("Driscoll-Kraay standard errors in parentheses." "Country and year fixed effects included." "Source: Authors' calculations.") nonumbers interaction(" # ") indicate("Year dummies = *.year")

***************************************************************************************************
*DYNAMIC FIXED-EFFECTS ESTIMATOR FOR ROBUSTNESS CHECKS OF PERSISTENCE OF THE OUTCOME VARIABLES
***************************************************************************************************

*The lagged dependent variable introduces the Nickell bias. Therefore, these estimates are just for robustness checks only of the persistence of the outcome variabes considering their nature.*

xtscc youth_neet L.youth_neet $xvars $interactions i.year, fe 

estimates store DFE_NEET

xtscc unemp_youth L.unemp_youth $xvars $interactions i.year, fe 

estimates store DFE_UNEMP

xtscc real_income_youth L.real_income_youth $xvars $interactions i.year, fe 

estimates store DFE_INCOME

********************************************************************
*FIRST-DIFFERENCE ESTIMATOR FOR ROBUSTNESS CHECKS
********************************************************************

reg D.(youth_neet $xvars $interactions), vce(cluster country_id)

estimates store FD_NEET

reg D.(unemp_youth $xvars $interactions), vce(cluster country_id)

estimates store FD_UNEMP

reg D.(real_income_youth $xvars $interactions), vce(cluster country_id)

estimates store FD_INCOME

********************************************************************
*PANEL QUANTILE REGRESSION USING MOMENT APPROACH
********************************************************************

*Quantile regression is used to investigate heterogeneous effects, not because the dependent variables are non-normal. The preferred mean estimator remains two-way FE with clustered SE. Quantile estimates are supplementary for robustness checks.*

capture which mmqreg
if !_rc {

    mmqreg youth_neet $xvars $interactions , q(10 25 50 75 90)

    estimates store MMQR_NEET

    mmqreg unemp_youth $xvars $interactions , q(10 25 50 75 90)

    estimates store MMQR_UNEMP

    mmqreg real_income_youth $xvars $interactions , q(10 25 50 75 90)

    estimates store MMQR_INCOME
}

*qreg or sqreg are just robustness checks for FE panel models. qreg does not adequately control for country-specific fixed effects.*

*****************************************************************************************************************
*TWO-WAY FIXED-EFFECTS REGRESSION MODEL USING LOG TRANSFORMED REAL INCOMES EARNED PER YOUNG PERSON IN AFRICA
*****************************************************************************************************************
xtscc ln_real_income_youth $xvars $interactions i.year, fe 
estimates store FE_LOGINCOME
********************************************************************
*COMPARISON REGRESSION TABLES
********************************************************************
esttab FE_NEET FE_UNEMP FE_INCOME FE_LOGINCOME DFE_NEET DFE_UNEMP DFE_INCOME FD_NEET FD_UNEMP FD_INCOME MMQR_NEET MMQR_UNEMP MMQR_INCOME using "Tables\Table9_Complete_Regression_Comparison.rtf", replace se star(* 0.10 ** 0.05 *** 0.01) compress label stats(N N_g r2_w, labels("Observations" "Countries" "Within R-squared")) title("Table 9. Main Estimates and Robustness Checks")


********************************************************************
* PRESENT VALUE OF PROSPECTIVE YOUTH LIFETIME LABOUR INCOME
********************************************************************

est restore FE_INCOME

*---------------------------------------------------------------*
* Extract coefficients from the two-way FE model
*---------------------------------------------------------------*

scalar b_igg = _b[igg]

capture scalar b_igg_youth = _b[c.igg#c.ln_youth_population]

if _rc {
    scalar b_igg_youth = 0
}

*---------------------------------------------------------------*
*Extract variance-covariance elements
*---------------------------------------------------------------*

matrix V = e(V)

local var_igg = V["igg","igg"]

capture local var_igg_youth = V["c.igg#c.ln_youth_population","c.igg#c.ln_youth_population"]

if _rc {
    local var_igg_youth = 0
}

capture local cov_igg_youth = V["igg","c.igg#c.ln_youth_population"]

if _rc {
    local cov_igg_youth = 0
}

local se_igg       = sqrt(`var_igg')
local se_igg_youth = sqrt(`var_igg_youth')

*---------------------------------------------------------------*
* Calculate the observed interquartile improvement in IGG
*---------------------------------------------------------------*

summarize igg, detail

scalar igg_p25 = r(p25)
scalar igg_p50 = r(p50)
scalar igg_p75 = r(p75)

scalar delta_igg = igg_p75 - igg_p25

display "IGG P25 = " igg_p25
display "IGG P50 = " igg_p50
display "IGG P75 = " igg_p75
display "IGG interquartile change = " delta_igg

*---------------------------------------------------------------*
* Country-year marginal effect of IGG on youth income
*---------------------------------------------------------------*

gen double marginal_igg_income = b_igg + b_igg_youth * ln_youth_population

label variable marginal_igg_income "Marginal effect of IGG on annual youth labour income"

*---------------------------------------------------------------*
*Correct delta-method standard error
*---------------------------------------------------------------*

gen double se_marginal_igg_income = sqrt(`var_igg' + (ln_youth_population^2) * `var_igg_youth' + 2 * ln_youth_population * `cov_igg_youth' )

*---------------------------------------------------------------*
* 95 percent confidence interval
*---------------------------------------------------------------*

gen double marginal_igg_income_lb = marginal_igg_income - 1.96 * se_marginal_igg_income

gen double marginal_igg_income_ub = marginal_igg_income + 1.96 * se_marginal_igg_income

*---------------------------------------------------------------*
* Annual income gain associated with P25-to-P75 IGG shift
*---------------------------------------------------------------*

gen double annual_income_gain = marginal_igg_income * delta_igg

label variable annual_income_gain "Annual model-implied income gain per young person (US$)"

*---------------------------------------------------------------*
* Corresponding confidence interval for annual income gain
*---------------------------------------------------------------*

gen double annual_income_gain_lb = marginal_igg_income_lb * delta_igg

gen double annual_income_gain_ub = marginal_igg_income_ub * delta_igg
	
********************************************************************
* PVLW SENSITIVITY ANALYSIS
********************************************************************

tempname pvlw_handle

postfile `pvlw_handle' double discount_rate int horizon double annuity_factor double mean_pvlw_per_youth double total_pvlw double total_pvlw_bn using "Tables/PVLW_Sensitivity.dta", replace

foreach rate in 0.017 0.03 0.078 0.10 {

    foreach horizon in 40 45 50 {

        scalar annuity = (1 - (1 + `rate')^(-`horizon')) / `rate'

        quietly summarize annual_income_gain

        scalar mean_gain = r(mean)

        gen double temp_pvlw = annual_income_gain * annuity

        gen double temp_total_pvlw = temp_pvlw * youth_population

        quietly summarize temp_pvlw

        scalar mean_pvlw = r(mean)

        quietly summarize temp_total_pvlw

        scalar total_pvlw = r(sum)

        scalar total_pvlw_bn = total_pvlw / 1000000000

        post `pvlw_handle' (`rate') (`horizon') (annuity) (mean_pvlw) (total_pvlw) (total_pvlw_bn)

        drop temp_pvlw temp_total_pvlw
    }
}

postclose `pvlw_handle'

preserve

use "Tables/PVLW_Sensitivity.dta", clear

export excel using "Tables/Table12_PVLW_Sensitivity.xlsx", firstrow(variables) replace

restore

********************************************************************
* COUNTRY-LEVEL PVLW RESULTS: 2023
********************************************************************

scalar base_rate = 0.078
scalar base_horizon = 50

scalar base_annuity = (1 - (1 + base_rate)^(-base_horizon)) / base_rate

* Present value per young person
gen double pvlw_per_youth_50 = annual_income_gain * base_annuity

* Population in millions for table presentation
gen double youth_population_m = youth_population / 1000000

* Aggregate PVLW in US dollars
gen double aggregate_pvlw_50 = pvlw_per_youth_50 * youth_population

* Aggregate PVLW in billions of US dollars
gen double aggregate_pvlw_50_bn = aggregate_pvlw_50 / 1000000000

* Annual income effect in thousands of US dollars
gen double annual_income_gain_000 = annual_income_gain / 1000

* PVLW per youth in thousands of US dollars
gen double pvlw_per_youth_50_000 = pvlw_per_youth_50 / 1000

preserve

keep if year == 2023

keep country_id country_name country_code year igg youth_population_m marginal_igg_income annual_income_gain annual_income_gain_000 pvlw_per_youth_50 pvlw_per_youth_50_000 aggregate_pvlw_50 aggregate_pvlw_50_bn

sort aggregate_pvlw_50_bn

export excel using "Tables/Table13_Country_PVLW_Results_2023.xlsx", firstrow(variables) replace

restore

log close
