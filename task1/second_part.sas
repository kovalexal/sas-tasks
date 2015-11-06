/***********************************
* Author: Alexander Kovalchuk
* Group: 520 
***********************************/

%let INPUT_FILE=/folders/myfolders/output.txt;


%macro wordcount(list);
%* Count the number of words in &LIST;
%local count;
%let count=0;
%do %while(%qscan(&list,&count+1,%str( )) ne %str());
	%let count = %eval(&count+1);
%end;
&count
%mend wordcount;


%* Preread input file to get list of available types;
%let auto_types=;
data _null_;
	infile "&INPUT_FILE" dlm=' ' truncover;
	length line $ 200;
	input Make $ Origin $;
	input @1 line $200.;
	
	line = prxchange('s/Count//', -1, line);
	line = prxchange('s/=\d*//', -1, line);
	call symputx('auto_types', line);
	
	stop;
run;


%* Input a variable from *=number;
%macro in_var(prefix, list);
%do i=1 %to %wordcount(&list);
	%let cur_type=%scan(&list, &i, ' ');
	
	input tmp_str :$40. @@;
	tmp_str = prxchange("s/&prefix&cur_type=//", -1, tmp_str);
	&prefix&cur_type = input(tmp_str, 10.);
	put &prefix.&cur_type.=;
%end;
input;
%mend in_var;


%* Read file into dataset;
data cars_info(drop=tmp_str patternID position length makeorigin);
	infile "&INPUT_FILE" dlm=' ' truncover;
	input makeorigin $200.;
	put makeorigin=;
	patternID = prxparse('/\(\w*\)/');
	call prxsubstr(patternID, makeorigin, position, length);
	Make = trim(prxchange('s/\(\w*\)//', -1, makeorigin));
	Origin = substr(makeorigin, position, length);
	Origin=compress(Origin, '()', '');

	%in_var(Count, &auto_types);
	%in_var(Median, &auto_types);
	%in_var(Distance, &auto_types);
run;


%* Converts variables to column;
%macro var_to_row(list);
%do i=1 %to %wordcount(&auto_types);
	%let cur_type=%scan(&list, &i, ' ');
	if Count&cur_type^=0 then do;
		Type="&cur_type.";
		Count=Count&cur_type.;
		Median=Median&cur_type;
		output;
	end;
%end;
%mend var_to_row;


%* Convert Type, Count, Median to row;
data cars_info(keep=Make Origin Type Count Median);
	format Type Make Median Count Origin;
	set cars_info;
	%var_to_row(&auto_types);
run;


%* Sort dataset;
proc sort data=cars_info;
	by Type descending Median;
run;


%* Remove Make with 2 max Medians (by Type);
data cars_info(drop=cur_group_obs Make Median);
	format Type Origin Count;
	set cars_info;
	by Type;
	
	retain cur_group_obs 0;
	
	if first.Type=1 then cur_group_obs=0;
	cur_group_obs+1;
	
	if 1<=cur_group_obs<=2 then delete;
run;


%* Sort dataset again;
proc sort data=cars_info;
	by Type Origin;
run;


%* Calculate sum over Types and Origins;
data cars_info(drop=Count rename=(sum=Count));
	set cars_info;
	by Type Origin;
	
	retain sum 0;
	if first.Origin=1 then sum=0;
	sum+Count;
	if last.Origin=1 then output;
	return;
run;


%* Get all available Origins in regions macro "array";
proc sort data=cars_info out=regions nodupkey;
	by Origin;
run;
data regions(keep=Origin);
	set regions;
run;
%let regions =;
data _null_;
	set regions;
	call symput('regions',trim(resolve('&regions'))||' '||trim(Origin));
run;
%put &regions;


%* Transpose cell from column value to row;
%macro gen_var(list);
%do i=1 %to %wordcount(&list);
	%let cur_region=%scan(&list, &i, ' ');
	if Origin="&cur_region" then do;
		&cur_region.=Count;
	end;
%end;
%mend gen_var;


%* Get the result dataset;
data result_data(keep=Type &regions);
	set cars_info;
	by Type;
	
	retain &regions;
	
	%gen_var(&regions);
	if last.Type=1 then output;
	return;
run;

proc print data=result_data;
run;