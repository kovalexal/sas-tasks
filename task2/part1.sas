proc glm data=sashelp.cars plots=boxplot;
	class Type;
	model MPG_Highway=Type;
	means Type / HOVTEST=bartlett;
run;
quit;