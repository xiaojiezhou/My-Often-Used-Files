/***************************************************************************************************************************************************
	Name:		REPORTS_GRP_PVALUE_SINGLE VERSION 1						  			   									                   *************
	Dated:		18th June 2009	
	Updated:	

 This Macro creates grouping/pvalue reports from output of GROUPING-MACRO

	Inputs:
		Reports   	: List of reports name (grouping, pvalue or both) which needs to be generated
 		Datasets  	: List of datasets required for genearting above mentioned reports in corresponding sequence
 
 	Outputs         
 					: Final report is generated

********************************************************************************************************************************************************/

*make changes here to store the macro catalogue;
*libname a '/data/Trainning/Sunita/P3-PG/P4';
Options macrogen symbolgen;
*options mstored sasmstore=a;

%MACRO ReportSingleGrpPvalue (DATASETS=, REPORTS= );*/store;

*options nomlogic nomprint nosource nosymbolgen nosource2 nomacrogen;

/****************** check for declaration of macro-variables required in this macro ********************************************************************/
/*
data _null_;
	set &datasets;
	call symput("Classtype",vtype(&CLASSVAR));
run;

%if &classtype.=C %then %let classformat=$&classvar; 
%else %let classformat=&classvar; 
*/

%IF  %SYMEXIST(CLASSVAR) NE 1 
     OR %SYMEXIST(SORTVAR) NE 1
     OR %SYMEXIST(TEST) NE 1
     OR &SORTVAR = 
     OR &TEST = 
%THEN 
%DO;
    %PUT UNINITIALIZED: DECLARATION OF MACRO VARIABLES -- "SORTVAR , CLASSVAR and TEST" IS REQUIRED;
     ENDSAS;
%END;

/*******************************************************************************************************************************************************/
*This format is only used in GROUPING Report;    
proc format;    
picture p (round)
			0.0000-<0.0001 = '<.0001*' (noedit)
			other = '9.9999*'
              . = '------'
           &test<-high  = '9.9999'
						;
picture pval (round)
			0.0000-<0.0001 = '<.0001' (noedit)
			other = '9.9999'
						;
run;    
    
/*******************************************************************************************************************************************************/
*Creates macro variables to read and store sort variables values and data types;
%LET svar=;
%LET N = 1;
%DO %WHILE ( %SCAN(&SORTVAR, %EVAL(&N)) NE );
	%LET SVAR&N. = %sysfunc(propcase(%SCAN(&SORTVAR, %EVAL(&N))));
	%LET D = %SCAN(&DATASETS,1,%STR() %STR(,));  
	data temp;
		set &D;
		call symput("svartype&n.",vtype(&&SVAR&N.));
		call symput("Classtype",vtype(&CLASSVAR));
	run; 
	%LET N = %EVAL(&N + 1 );
%END;

%LET N = %EVAL(&N - 1 );

%do i=2 %to %eval(&N);
	%let svar=&svar &&svar&i.;
%END;

%put &svar;

*Creates macro variables to read and store the reports name that needs to be generated ;
%LET COUNT1 = 1;
%DO %WHILE ( %SCAN(&REPORTS, %EVAL(&COUNT1)) NE );  
	%LET M&COUNT1. = %SCAN(&REPORTS, %EVAL(&COUNT1)); 
   	%LET COUNT1=%EVAL(&COUNT1+1);
%END;

%LET COUNT1 = %EVAL(&COUNT1 - 1 );

*Creates macro variables to read and store the dataset name that are used to creat report ;
%LET COUNT2 = 1;
%DO %WHILE ( %SCAN(&DATASETS, %EVAL(&COUNT2),%STR() %STR(,)) NE );
	%LET D&COUNT2. = %SCAN(&DATASETS, %EVAL(&COUNT2),%STR() %STR(,));
	%LET COUNT2=%EVAL(&COUNT2+1);
%END;
%LET COUNT2=%EVAL(&COUNT2-1);   

*Report creation code. This piece can handle multiple by group variables and can pick corresponding formats for
 SORTVAR, CLASSVAR and VAR from format.sas

 This piece also includes logic to read the report name and dataset name from passed parameter. 
 The parameter REPORTS= can have any sequence of reports but the sequence of dataset names in DATASET= should
 match with that of REPORTS=;

%LET COUNT = 1;
%DO %WHILE (%eval(&COUNT)<=%eval(&COUNT1));
	%IF %upcase(&&M&COUNT.)= GROUPING  %THEN
	%do;
		proc sort data=&&D&COUNT. out=&&D&COUNT.;
			by &Sortvar &classvar.;
		run;
		%if (%eval(&COUNT2.)>%eval(&COUNT1.)) %then
		%do;
			proc sort data=&&D&Count2.; 
				by &Sortvar &classvar;
			run;
				    
			data &&D&COUNT.;
            	merge &&D&COUNT.(in=i) &&D&Count2.(in=j rename=(&classvar=&classvar.a)) ;
				by &Sortvar &classvar.a;
				if i=1;
				if Estimate=. then Estimate=0;
			run;
		%end;
/*
	    data &&D&COUNT.;
			set &&D&Count.;
			*calculate geometric mean;
			gm 	= 10**(lsmean);
			*Include %change from baseline;
			if estimate = 0 then
			do;
				cfb1 = 0;
				cmsefb1 = 0;
				cpsefb1 = 0;	
			end;

			else if estimate ne 0 then
			do;
				cfb1 	=	(10**(estimate) - 1)*100;
				cmsefb1	=	(10**(estimate-stderr)-1)*100;
				cpsefb1	=	(10**(estimate+stderr)-1)*100;;
			end;
		run;
*/

		data &&D&Count.;
			set &&D&Count.;
			Treatment= cats(put(&classvar, &classvar..),' - ',put(_&classvar, &classvar..));
		run;

		proc sort data=&&D&COUNT.;
			by &SORTVAR;
		run;

		%let per = %sysevalf((1.0-&test)*100);

		ods rtf select all;	
   		ods listing close;
		proc report data=&&D&COUNT. nowd headline split='?'  spacing=0 box style(header)=[background=white font_size=10 pt  ];
		column	Treatment &svar1. &svar
		 		%if (%eval(&COUNT2.)>%eval(&COUNT1.)) %then estimate; 
				estimate stderr lower upper;
		define Treatment / order left width=5;
  		define &classvar.	/ order	left	format=%if &Classtype =C %then $&classvar..;
		%else &classvar..; width=4;
  		define &svar1.		/ order  	noprint;
  		%DO i=2 %to %eval(&N);
	        define &&SVAR&i./ order	left format=%if &&svartype&i..=C %then $&&SVAR&i...; 
			%else &&SVAR&i...; width=12 id "&&SVAR&i." ;
	    %end;
		%if (%eval(&COUNT2.)>%eval(&COUNT1.)) %then ;
		define estimate		/ analysis sum center  format=7.3    width=6  'Week 3 ?Adjusted Mean Difference' ;
 		define stderr		/ analysis sum center  format=5.3    width=5  'Standard Error';
		define lower		/ display center format=6.3 "Lower?&per.% Confidence?Bound";
		define upper		/ display center format=6.3 "Upper?&per.% Confidence?Bound";
		run;
		%end;
				
/*		%IF %upcase(&&M&COUNT.)= PVALUE  %THEN 
		%DO;
		    *Data preparation for P-VALUE report;
		   	data s;
				set &&D&COUNT.;
				prob=probt;
			run;

			data a;
				set s; 
				vara=&classvar;
				varb=_&classvar;
			run;

			data b;
				set s;
				varb=&classvar;
				vara=_&classvar;
				call symput("Classtype",vtype(&CLASSVAR));
			run;

			data dreport;
				set a b;
			run;

			proc sort data=dreport;
				by &sortvar;
			run;

			*Report creation code. This piece can handle multiple by group variables and can pick corresponding formats for SORTVAR, CLASSVAR and VAR from format.sas;

			options orientation=portrait;
			ods rtf select all;
			ods listing close;

			proc report data=dreport nowd headline split='*' spacing=1  style(Header)=[BACKGROUND=white FONT_SIZE=10 pt  ];
  				column (&sortvar vara prob,varb vara=vara2);
  				%DO i=1 %to %eval(&N);
		    		define &&SVAR&i. / group        left format=%if &&svartype&i..=C %then $&&SVAR&i...; %else &&SVAR&i...; width=12 id "&&SVAR&i." ;
		        %end;
  				define vara / group        left format=%if &Classtype.=C %then $&classvar.s.; %else &classvar.s.;   width=3  'Treatment' id;
  				define varb / across       center format=%if &Classtype.=C %then $&classvar.s.; %else &classvar.s.;            ' ' style(Column)=[ASIS=ON];
  				define prob / analysis sum center format=p.    width=6  ' ';
  				define vara2/ group        left   format=%if &Classtype.=C %then $&classvar..; %else &classvar..; width=42 'Treatment Code Key' spacing=3;
  				compute before _page_;
                line 'P-Values for Treatment Mean Pairwise Comparisons';
                endcomp;
  				compute after &Svar1.;
				line ' ';
				endcomp;
  				compute after;
    			line "A p-value with a '*' indicates a significant difference between treatments (P<=&TEST).";
  				endcomp;
			run;
			ods listing;
		%end;	
		*/
	%LET COUNT = %EVAL(&COUNT+1);
%end;
options mlogic symbolgen;
%mend;
