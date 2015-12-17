proc glm data=sashelp.cars alpha=0.01;
	class Type;
	model MPG_Highway=Type;
	means Type / HOVTEST=bartlett;
	lsmeans Type / adjust=t pdiff=all;
run;
quit;

data cars_combined;
	set sashelp.cars;
	if Type in ('SUV', 'Truck') then Type='SUVTruck';
	if Type in ('Sedan', 'Wagon') then Type = 'SedanWagon';
run;

proc glm data=cars_combined alpha=0.01;
	class Type;
	model MPG_Highway=Type;
	means Type / HOVTEST=bartlett;
	lsmeans Type / adjust=t pdiff=all;
run;
quit;
