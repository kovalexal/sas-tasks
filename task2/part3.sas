data cars_combined;
	set sashelp.cars;
	if Type in ('SUV', 'Truck') then Type='SUVTruck';
	if Type in ('Sedan', 'Wagon') then Type = 'SedanWagon';
run;

proc glm data=cars_combined;
	class Type;
	model MPG_Highway=Type;
run;
quit;

proc glm data=cars_combined;
	class Type Origin;
	model MPG_Highway=Type|Origin;
run;
quit;

proc glm data=cars_combined;
	class Type Origin;
	model MPG_Highway=Type Origin;
run;
quit;