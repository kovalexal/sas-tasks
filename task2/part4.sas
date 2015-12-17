proc glmselect data=sashelp.cars plots=all;
	model MPG_City=Length Weight Wheelbase Horsepower Invoice EngineSize Cylinders /
	selection=backward select=sl choose=sbc slstay=0.01 details=steps;
run;
quit;