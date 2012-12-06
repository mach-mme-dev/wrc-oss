wrc-oss
=======

WRC - Berichtsheftgenerator für Azubis (Weekly Report Creator)

The perl script ''WRC.pl'' creates your weekly report automatically. It reads cvs and git logs for users and projects that are specified in the config file or command line.<br>The accordant commit notes are inserted to a weekly report document, that is created automatically with configured and readout data.<br>To enable correct search and output, the files of these projects have to be committed according to the [[Commit_Note_Conventions | commit note conventions]].<br>Additionally the script reads a csv-file (with calendar entries exported from outlook) and fills the document with the team meetings of that week.<br> According to the title of each meeting, these names are inserted under ''Betriebliche Tätigkeit'' ( all meetings except of Daily Scrums and Knowledge Transfers) or under ''Unterweisungen, Lehrgespräche...'' ( if title includes Knowledge Transfer or KT). For this please also look up our [[Meeting Subject Conventions]].<br> The file name of the created document is generated automatically out of the user's full name, the week since start of the traineeship and the year.

===execute the script===

Before you can run the script, ensure, that you have a config file and installed the modules mentioned below. Additionally you can have an accordant csv.-file, but it is not required.

To run the script with the necessary pre-configured parameters, the name of the config-file is needed after '-c ':

 perl WRC.pl -c ''name_of_configfile''


You can also define the calendar week here, which shall be read out for commits, by setting the value after '-w '. To read search for commits of several weeks, use 't '. '-f ' is the option for the output format, '-r ' for the report number and '-o ' for the output path. The values you type in here have higher priority than the ones on your configuration-file.
Final Example:

 perl WRC.pl -c ''name_of_configfile'' -w ''calendar_week'' -t ''timespan_in_weeks'' -r ''report_number'' -o ''output_path'' -f ''output_format''.


Default values:<br>
-w = number_of_current_calendar_week<br>
-t = 1<br>
-r = number_of_weeks_since_start_date<br>
-o = /tmp<br>
-f = odt<br>

===config data===

The config file contains all the data the script needs to read and write according to the user's intention. The file is saved in the '''same folder''' as the script.

 user         = test
 name         = test tester
 team         = teamname
 startDate    = 01.09.2012
 outputformat = odt ''(you can replace odt with [[doc]], if you want to have a word document)''
 outputpath   = /"''yourpath''"
 calendarfile = ''filename''.CSV<br>
 <projects>
   <project1>
    repo = /dir_of_gitrepo
    vcs  = git
    host = host1
    name = projectname1
  </project1>
  <project2>
    repo = /dir_of_cvsrepo
    name = projectname2
    vcs  = cvs
    host = host2
  </project2>
  <project3>
    repo = /dir_of_cvs_repo
    name = projectname3
    vcs  = cvs
    host = host2
  </rms>
 </project3>

===.csv file===

To enable the input of meetings, a .csv file exported from the outlook calendar is necessary in the '''script's folder'''.<br>
 Outlook -> File -> Open -> Import -> Export a File -> Comma Separated Values (Windows)<br> -> Calendar -> path + filename (must conform with the value of the parameter "calendarfile"in the config file)<br> -> Finish -> Select dates of the week -> OK

===script repository location===

host: github.com<br>
path: /mach-mme-dev/wrc-oss/

===external perl modules used===

Config::General<br>
DateTime<br>
Date::Calc<br>
Getopt::Std<br>
File::Basename<br>
File::Util<br>
OpenOffice::OODoc<br>
POSIX<br>
MsOffice::Word::HTML::Writer<br>
Text::CSV<br>
Text::CSV<br>
Test::More (testing only)<br>

===attached perl modules used===

CVSReader.pm<br>
GITReader.pm<br>
CalendarReader.pm<br>
OpenDocWriter.pm<br>
MSWordWriter.pm<br>
Util.pm<br>
WRFormat.pm<br>

===output formats===

The final odt document takes over the margins from the template file (wrc/Writer/template/template.odt).<br>The margins for the doc file are set in the writer module as well as all other format and style configuration (headlines, fonts, size of the text boxes...).<br>
To open the .doc-file MSWord is recommended.

===Commit note conventions===

The Headline should start with a * and contain:

 *Example_header_text

====Description====
 
Use normal text for description, with indentation of 2 spaces: 
   
   this_is_a_commit_text_line

====Comments====

Comments should start with <nowiki>[[ and end with ]]</nowiki> :
 <nowiki>[[review: name_of_reviewer]]</nowiki>
This will not be in the weekly reports

Distinguish between 3 kind of comments:<br>
*review
*pair-programming
*comment

The comment type has to be separated from the text with a colon or equal sign
 <nowiki>[[review: name_of_reviewer]]
[[pair-programming= name_of_co-programmer]]
[[comment: some_general_comment]]</nowiki>

To list more reviewers pair-programmers, separate them with a comma:
 <nowiki>[[pair-programming= co-programmer1,co-programmer2,co-programmer3]]</nowiki>

====Forbidden items====

*More than five dashes (-) or equals (=)

*Line breaks: <nowiki><br></nowiki>

====Example====

 *Script for weekly reports<br>
   wrc/gitreader.pm (add) - created module to read git comments<br>
   wrc/test.conf (edit) - deleted parameter3<br>

===Meeting subject conventions===

====Keywords====

It is necessary to use defined keywords in the subject so that these subjects are written correctly into their weekly reports.<br>
For regular meetings there has to be the '''team name''' at the beginning of the subject.<br>Examples:

 Subject: teamname1 monthly review 
          or
 Subject: teamname2 project planning meeting
          

If the meeting has the purpose of sharing knowledge with colleagues, the keyword '''knowledge''' or '''KT''' has to be part of the subject.<br>Examples:

 Knowledge Transfer in Lisp
           or
 MySQL knowledge transfer
           or
 Git and Eclipse KT



As we don't want to have our weekly reports filled with Daily Scrums, subjects that include "Daily Scrum" are not written into our documents.<br>Examples:

 team1 Daily Scrum
         or
 team2 scrum
         or
 another Dailyscrum


If you have more than one keyword in the subject, there should be no problem:<br>For team name + Knowledge transfer our script handles it as a KT.<br>For team name + Daily scrum it is considered as a Daily Scrum.
