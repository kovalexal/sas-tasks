ods pdf file="~/Task2_Kovalchuk/report.pdf";

/* Step 3 */

data cars_combined;
	set sashelp.cars;
	if Type in ('SUV', 'Truck') then Type='SUVTruck';
	if Type in ('Sedan', 'Wagon') then Type = 'SedanWagon';
run;

ods select GLM.ANOVA.MPG_Highway.OverallANOVA GLM.ANOVA.MPG_Highway.FitStatistics;
proc glm data=cars_combined alpha=0.01;
	class Type Origin;
	model MPG_Highway=Type Origin;
run;
quit;

/* Step 4 */
ods select GLMSelect.Summary.CoefficientPanel;
proc glmselect data=sashelp.cars plots=all;
	model MPG_City=Length Weight Wheelbase Horsepower Invoice EngineSize Cylinders /
	selection=backward select=sl choose=sbc slstay=0.01 details=steps;
run;
quit;

/* Step 6 */
ods select none;
proc reg data=sashelp.cars outest=cars_model;
	model MPG_City=Weight Horsepower;
run;
quit;

data cars_model;
	set cars_model;
	if _N_ = 1 then output;
run;

ods select none;
proc template;
define statgraph mygraphs.scatter;
begingraph;
	layout overlay3d / rotate=60;
	surfaceplotparm x=Horsepower y=Weight z=MODEL1;
	endlayout;
endgraph;
end;
run;

proc sql noprint;
	select
		min(Weight), max(Weight), min(HorsePower), max(HorsePower)
	into
		:min_weight, :max_weight, :min_horsepower, :max_horsepower
	from sashelp.cars;
run;

data cars_graph_data;
	do Weight=&min_weight. to &max_weight. by (&max_weight.-&min_weight.)/19;
		do HorsePower=&min_horsepower. to &max_horsepower. by (&max_horsepower.-&min_horsepower.)/19;
			output;
		end;
	end;
run;

ods select none;
proc score data=cars_graph_data score=cars_model out=cars_graph_data type=parms;
	var Weight Horsepower;
run;
quit;

ods select SGRender.SGRender;
proc sgrender data=cars_graph_data
	template=mygraphs.scatter;
run;

ods pdf close;