/***********************************
* Author: Alexander Kovalchuk
* Group: 520 
***********************************/

%let OUTPUT_FILE=/folders/myfolders/output.txt;


%* Count the number of words in &LIST;
%macro wordcount(list);
%local count;
%let count=0;
%do %while(%qscan(&list,&count+1,%str( )) ne %str());
	%let count = %eval(&count+1);
%end;
&count
%mend wordcount;


%* Generates retain variable calculating and zeroing on previous group start;
%macro gen_var(list, prev_group, prefix, var);
%do i=1 %to %wordcount(&list);
	%let cur_type=%scan(&list, &i, ' ');
	
	retain &prefix&cur_type 0;
	
	if first.&prev_group=1 then &prefix&cur_type=0;
	
	if Type="&cur_type" then do;
		&prefix&cur_type=&var;
	end;
%end;
%mend gen_var;


%* Generates dataset with columns Count{Type}, Median{Type}, Distance{Type};
%macro gen_dataset(in_dataset, out_dataset);
data &out_dataset(drop=Type Count Median Distance);
	set &in_dataset;
	by Make Origin;
	
	%gen_var(&auto_types, Origin, Count, Count);
	%gen_var(&auto_types, Origin, Median, Median);
	%gen_var(&auto_types, Origin, Distance, Distance);

	if last.Origin=1 then output;
	return;
run;
%mend gen_dataset;


%* Outputs variables from list, name of variable starts with prefix;
%macro out_var(prefix, list);
%do i=1 %to %wordcount(&list);
	%let cur_type=%scan(&list, &i, ' ');
	
	put &prefix&cur_type=@;
%end;
%mend out_var;


%* Keep only needed columns and change their order;
data cars_info(keep=Make Origin Type Invoice);
	format Make Origin Type Invoice;
	set sashelp.cars;
run;


%* Sort dataset;
proc sort data=cars_info;
	by Make Origin Type Invoice;
run;


%* Count num of occurences by Type;
data cars_info_count(drop=Invoice);
	set cars_info;
	by Make Origin Type;
	
	retain Count 0;
	
	if first.Type=1 then Count=0;
	Count+1;
	if last.Type=1 then output;
	return;
run;


%* Add count back to dataset;
data cars_info;
	merge cars_info cars_info_count;
	by Make Origin Type;
run;


%* Calculate median and interquartile distance;
data cars_info (keep=Make Origin Type Count Median Distance);
	set cars_info;
	by Make Origin Type;
	
	retain pos_in_current_subgroup 0;
	retain pos_median 0;
	retain pos_first_quartile 0;
	retain pos_third_quartile 0;
	retain Median 0;
	retain Distance 0;
	retain FirstQuartile 0;
	retain ThirdQuartile 0;
	
	InvoiceLag=lag(Invoice);
	
	%* On group start initialize needed variables;
	if first.Type=1 then do;
		pos_in_current_subgroup=0;
		pos_median=int(Count/2)+1;
		pos_first_quartile=int(Count/4)+1;
		pos_third_quartile=int(Count*3/4)+1;
	end;
	
	%* Increment current position in group;
	pos_in_current_subgroup+1;
	
	%* Check, whether we can calculate median;
	if pos_in_current_subgroup=pos_median then do;
		if mod(Count, 2)=1 then do;
			Median=Invoice;
		end;
		else do;
			Median=(Invoice+InvoiceLag)/2;
		end;
	end;
	
	%* Check, whether we can calculate first quartile;
	if pos_in_current_subgroup=pos_first_quartile then do;
		if mod(Count, 2)=1 then do;
			FirstQuartile=Invoice;
		end;
		else do;
			FirstQuartile=(Invoice+InvoiceLag)/2;
		end;
	end;
	
	%* Check, whether we can calculate first quartile;
	if pos_in_current_subgroup=pos_third_quartile then do;
		if mod(Count, 2)=1 then do;
			ThirdQuartile=Invoice;
		end;
		else do;
			ThirdQuartile=(Invoice+InvoiceLag)/2;
		end;
		Distance=ThirdQuartile-FirstQuartile;
	end;
	
	%* If this is the last record in group, output statistics;
	if last.Type=1 then output;
	return;
run;

%* Get unique auto types;
proc sort data=cars_info(keep=Type) out=available_types nodupkey;
	by Type;
run;

%* Create macro array with types;
%let auto_types =;
data _null_;
	set available_types;
	call symput('auto_types',trim(resolve('&auto_types'))||' '||trim(Type));
run;


%gen_dataset(cars_info, cars_info);

%* Output dataset to file;
data _null_;
	set cars_info;
	
	file "&OUTPUT_FILE";
	
	OriginWithBraces=cats('(',Origin,')');
	put Make OriginWithBraces;
	
	%out_var(Count, &auto_types);
	put;
	%out_var(Median, &auto_types);
	put;
	%out_var(Distance, &auto_types);
	put;
run;

