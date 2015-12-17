proc reg data=sashelp.cars plots=rsquare outest=cars_model;
	model MPG_City=Length Weight Wheelbase Horsepower Invoice EngineSize Cylinders /
	selection=rsquare details=steps start=2 stop=2;
run;
quit;

/* Filter the best model */
data cars_model;
	set cars_model;
	if _N_ = 1 then output;
run;


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

proc score data=cars_graph_data score=cars_model out=cars_graph_data type=parms;
	var Weight Horsepower;
run;
quit;

proc sgrender data=cars_graph_data
	template=mygraphs.scatter;
run;