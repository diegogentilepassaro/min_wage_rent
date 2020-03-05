clear all

cap cd "C:\Users\dgentil1\Desktop\min_wage\min_wage_rent\base\code"
* cd cote

shell rm -r ../output/
shell mkdir ../output
shell rm -r ../temp/
shell mkdir ../temp

shell Rscript RenameZillowVars_zipLevel.R
shell Rscript cleanGeoRelationshipFIles.R
do state_mw.do
do substate_mw.do
