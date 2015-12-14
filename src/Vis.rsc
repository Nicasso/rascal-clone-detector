module Vis

import vis::Figure;
import vis::Render; 
import vis::KeySym;
import Prelude;
import lang::java::m3::AST;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;
import IO;
import List;
import ListRelation;
import Tuple;
import String;
import Relation;
import util::Math;
import util::Editors;
import demo::common::Crawl;
import DateTime;

import CloneDetector;
import Config;

public list[loc] filesInLocation = [];
public list[Figure] dirBoxList = [];
public list[Figure] fileBoxList = [];
public str textField = "";
public Color noCloneColor = color("White");
public Color fullCloneColor = color("Red");
public str defaultDirColor = "LightGrey";
public str highlightDirColor = "DarkGrey";
public loc currentLocation = Config::startLocation;
public lrel[loc location,int LOC, real percentage, set[loc] clones] fileInformation = [];

public void mainVis(int cloneType) {
	CloneDetector::main(cloneType);
	//createFileInformation();
	startVisualization();
}

public void startVisualization() {
	clearMemory();
	createGoUpDirBox();
	createFileAndDirBoxes();
	createTreeMap();
}

public void clearMemory(){
	Vis::textField = "";
	Vis::filesInLocation = [];
	Vis::dirBoxList = [];
	Vis::fileBoxList = [];
}

public void createGoUpDirBox(){
	if(Vis::currentLocation != Config::startLocation){
		bool highlight = false;
		Vis::dirBoxList += box(
						text("..."),
						fillColor(Color () { return highlight ? color(Vis::highlightDirColor) : color(Vis::defaultDirColor); }),
						onMouseEnter(void () { highlight = true; Vis::textField = "Click to open parent folder";}), 
						onMouseExit(void () { highlight = false; Vis::textField = "";}),
						onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers){
							Vis::currentLocation = Vis::currentLocation.parent;
							startVisualization();
							return true;
							})
						);
	}
}

public void createFileAndDirBoxes(){			
	Vis::filesInLocation = Vis::currentLocation.ls;	
	for(loc location <- Vis::filesInLocation){
		loc tmploc = location;
		if(contains(location.extension, "/") || location.extension == ""){
			bool highlight = false;
			str showText = replaceFirst(location.path, Vis::currentLocation.path, "");
			Vis::dirBoxList += box(
								text(showText),
								fillColor(Color () {return highlight ? color(Vis::highlightDirColor) : color(Vis::defaultDirColor);}),
								onMouseEnter(void () {highlight = true; Vis::textField = "Click to open " + showText;}), 
								onMouseExit(void () {highlight = false; Vis::textField = "";}),
								onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers){
									Vis::currentLocation = tmploc;
									startVisualization();
									return true;
									})
								);
		} else if(location.extension == "java"){
			bool highlight = false;
			int boxArea;
			real percentage;
			for(file <- CloneDetector::fileInformation){
				if(file.location == location){
					boxArea = file.LOC;
					percentage = file.percentage * 3 > 1. ? 1. : file.percentage * 3;
					break;
				}
			}
			Vis::fileBoxList += box(
								area(boxArea),
								fillColor(interpolateColor(Vis::noCloneColor, Vis::fullCloneColor, percentage)),
								onMouseEnter(void () {highlight = true; Vis::textField = "Click to open " + tmploc.file + " (<boxArea> LOC)";}), 
								onMouseExit(void () {highlight = false; Vis::textField = "";}),
								onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers){
									Vis::currentLocation = tmploc;
									viewFile();
									return true;
									})
								);
		}
	}
	if(isEmpty(Vis::fileBoxList)){
		Vis::fileBoxList += box(
								text("No .java files in directory")
							);
	}
}

public void viewFile(){
	clearMemory();
	createGoUpDirBox();
	bool highlight = false;
	int LOC;
	set[loc] clones;
	for(file <- CloneDetector::fileInformation){
		if(file.location == Vis::currentLocation){
			LOC = file.LOC;
			clones = file.clones;
			break;
		}
	}
	int numberOfClones = size(clones);
	//Vis::textField = (numberOfClones == 1) ? "1 clone in this file" : "<numberOfClones> clones in this file";
	if (isEmpty(clones)){
		Vis::fileBoxList += vcat([
						box(
						text("0 clones in this file"),
						onMouseEnter(void () {highlight = true;}), 
						onMouseExit(void () {highlight = false;}),
						onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers){
									return true;
									})
						)
						]);
		createTreeMap();
	} else {
		int endLine = size(readFileLines(Vis::currentLocation));
		list[loc] sortedClones = sortClones(clones);
		bool highlight = false;
		for(clone <- sortedClones){
			loc cloneLocation = clone;
			str text = "Click to open clone in line <clone.begin.line> - <clone.end.line>";
			Vis::fileBoxList += box(
									vcat([
										box(
											vshrink(toReal(clone.begin.line - 1) / toReal(endLine))
										),
										box(
											fillColor("Red")
										),
										box(
											vshrink(toReal(endLine - clone.end.line) / toReal(endLine))
										)
									]),
									onMouseEnter(void () {highlight = true; Vis::textField = text;}), 
									onMouseExit(void () {highlight = false; Vis::textField = "";}),
									onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers){
										iprint(CloneDetector::getCloneClass(cloneLocation));
										return true;
									})
								);
		}
		createFileView();
	}
}

public list[loc] sortClones(set[loc] clones){
	list[loc] unsorted = toList(clones);
	list[loc] sorted = [];
	sorted = insertAt(sorted, 0, head(unsorted));
	unsorted = delete(unsorted, 0);
	for(loc clone1 <- unsorted){
		int i = 0;
		for(loc clone2 <- sorted){
			if(clone1.begin.line > clone2.begin.line){
				i += 1;
			}
		}
		sorted = insertAt(sorted, i, head(unsorted));
		unsorted = delete(unsorted, 0);
	}
	return sorted;
}

public void createTreeMap(){
	t = vcat([
			box(
				text(toString(Vis::currentLocation)),
				fillColor(Vis::defaultDirColor), 
				vshrink(0.04)),
			box(
				treemap(Vis::dirBoxList), 
				vshrink(0.04)),
			box(
				treemap(Vis::fileBoxList), 
				vshrink(0.88)),
			box(
				text(str(){return "<Vis::textField>";}), 
				fillColor(Vis::defaultDirColor),
				vshrink(0.04))
		]);
	render(t);
}

public void createFileView(){
	t = vcat([
			box(
				text(toString(Vis::currentLocation)),
				fillColor(Vis::defaultDirColor), 
				vshrink(0.04)),
			box(
				treemap(Vis::dirBoxList), 
				vshrink(0.04)),
			box(
				hcat(Vis::fileBoxList), 
				vshrink(0.88)),
			box(
				text(str(){return "<Vis::textField>";}), 
				fillColor(Vis::defaultDirColor),
				vshrink(0.04))
		]);
	render(t);
}

public void createFileInformation(){
	Vis::fileInformation = [
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/Column.java|,110,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ColumnExpression.java|,31,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/Columns.java|,48,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/Command.java|,85,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/CommandCreateDatabase.java|,23,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/CommandCreateView.java|,16,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/CommandDelete.java|,16,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/CommandDrop.java|,40,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/CommandInsert.java|,129,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/CommandSelect.java|,363,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/CommandSet.java|,20,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/CommandTable.java|,78,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/CommandUpdate.java|,36,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/CreateFile.java|,41,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/Database.java|,384,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/DataSource.java|,27,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/DataSources.java|,21,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/DateTime.java|,658,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/Distinct.java|,73,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/Expression.java|,128,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionArithmetic.java|,858,0.1083916084,{
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionArithmetic.java|(23138,909,<619,20>,<633,21>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionArithmetic.java|(6533,498,<206,8>,<214,9>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionArithmetic.java|(21213,875,<586,20>,<600,21>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionArithmetic.java|(20168,858,<566,20>,<580,21>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionArithmetic.java|(22147,892,<602,20>,<616,21>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionArithmetic.java|(8109,476,<248,8>,<256,9>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionArithmetic.java|(24150,891,<636,20>,<650,21>)
  }>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunction.java|,59,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionAbs.java|,64,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionACos.java|,8,1.,{|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionACos.java|(0,1607,<1,0>,<44,1>)}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionAscii.java|,19,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionASin.java|,8,1.,{|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionASin.java|(0,1607,<1,0>,<44,1>)}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionATan.java|,8,1.,{|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionATan.java|(0,1607,<1,0>,<44,1>)}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionATan2.java|,11,1.,{|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionATan2.java|(0,1732,<1,0>,<48,1>)}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionBitLen.java|,15,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionCase.java|,116,0.1206896552,{
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionCase.java|(4317,164,<185,25>,<191,2>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionCase.java|(4509,160,<194,21>,<200,2>)
  }>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionCeiling.java|,8,1.,{|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionCeiling.java|(0,1616,<1,0>,<44,1>)}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionChar.java|,17,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionCharLen.java|,14,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionConvert.java|,185,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionCos.java|,8,1.,{|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionCos.java|(0,1603,<1,0>,<44,1>)}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionCot.java|,8,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionDayOfMonth.java|,11,1.,{|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionDayOfMonth.java|(0,1738,<1,0>,<54,3>)}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionDayOfWeek.java|,10,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionDayOfYear.java|,11,1.,{|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionDayOfYear.java|(0,1743,<1,0>,<54,3>)}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionDegrees.java|,8,1.,{|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionDegrees.java|(0,1620,<1,0>,<44,1>)}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionDifference.java|,21,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionExp.java|,8,1.,{|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionExp.java|(0,1603,<1,0>,<44,1>)}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionFloor.java|,12,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionHour.java|,11,1.,{|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionHour.java|(0,1721,<1,0>,<54,3>)}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionIIF.java|,65,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionInsert.java|,40,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionLCase.java|,17,1.,{|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionLCase.java|(0,1893,<1,0>,<62,3>)}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionLeft.java|,25,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionLength.java|,13,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionLocate.java|,19,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionLog.java|,8,1.,{|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionLog.java|(0,1603,<1,0>,<44,1>)}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionLog10.java|,9,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionLTrim.java|,31,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionMinute.java|,11,1.,{|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionMinute.java|(0,1729,<1,0>,<54,3>)}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionMod.java|,11,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionMonth.java|,11,1.,{|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionMonth.java|(0,1727,<1,0>,<54,3>)}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionOctetLen.java|,15,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionPI.java|,10,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionPower.java|,11,1.,{|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionPower.java|(0,1730,<1,0>,<48,1>)}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionRadians.java|,8,1.,{|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionRadians.java|(0,1620,<1,0>,<44,1>)}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionRand.java|,15,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionRepeat.java|,30,0.6666666667,{
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionRepeat.java|(2006,270,<61,43>,<70,2>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionRepeat.java|(1644,311,<49,41>,<58,2>)
  }>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionReplace.java|,61,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionReturnFloat.java|,40,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionReturnInt.java|,36,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionReturnP1.java|,61,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionReturnP1Number.java|,44,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionReturnP1StringAndBinary.java|,36,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionReturnString.java|,37,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionRight.java|,25,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionRound.java|,31,0.3548387097,{|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionRound.java|(1759,188,<50,2>,<60,3>)}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionRTrim.java|,29,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionSign.java|,43,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionSin.java|,8,1.,{|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionSin.java|(0,1603,<1,0>,<44,1>)}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionSoundex.java|,75,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionSpace.java|,24,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionSqrt.java|,8,1.,{|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionSqrt.java|(0,1607,<1,0>,<44,1>)}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionSubstring.java|,40,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionTan.java|,8,1.,{|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionTan.java|(0,1603,<1,0>,<44,1>)}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionTimestampAdd.java|,77,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionTimestampDiff.java|,104,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionTruncate.java|,31,0.3548387097,{|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionTruncate.java|(1768,188,<50,2>,<60,3>)}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionUCase.java|,17,1.,{|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionUCase.java|(0,1893,<1,0>,<62,3>)}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionYear.java|,11,1.,{|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionFunctionYear.java|(0,1722,<1,0>,<54,3>)}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionInSelect.java|,30,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionName.java|,129,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/Expressions.java|,79,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ExpressionValue.java|,564,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/FileIndex.java|,40,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/FileIndexNode.java|,48,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ForeignKey.java|,16,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ForeignKeys.java|,27,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/GroupResult.java|,154,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/Identity.java|,73,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/Index.java|,368,0.07608695652,{
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/Index.java|(14315,322,<418,3>,<431,4>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/Index.java|(12875,332,<359,3>,<372,4>)
  }>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/IndexDescription.java|,162,0.09876543210,{
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/IndexDescription.java|(6136,299,<186,9>,<194,9>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/IndexDescription.java|(6874,179,<213,67>,<219,2>)
  }>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/IndexDescriptions.java|,71,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/IndexNode.java|,239,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/IndexNodeScrollStatus.java|,18,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/IndexScrollStatus.java|,101,0.2277227723,{
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/IndexScrollStatus.java|(4100,428,<120,5>,<131,41>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/IndexScrollStatus.java|(3062,385,<89,5>,<99,6>)
  }>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/Join.java|,161,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/JoinScroll.java|,127,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/JoinScrollIndex.java|,57,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/language/Language.java|,436,0.5825688073,{
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/language/Language.java|(12108,343,<292,33>,<306,2>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/language/Language.java|(23228,5376,<494,1>,<628,3>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/language/Language.java|(13722,9336,<354,1>,<488,3>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/language/Language.java|(12780,353,<318,35>,<332,2>)
  }>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/language/Language_de.java|,122,1.926229508,{
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/language/Language_de.java|(1730,11660,<51,4>,<183,6>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/language/Language_de.java|(0,13393,<1,0>,<184,1>)
  }>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/language/Language_en.java|,3,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/language/Language_it.java|,122,1.926229508,{
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/language/Language_it.java|(0,11817,<1,0>,<185,1>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/language/Language_it.java|(1730,10084,<51,1>,<184,3>)
  }>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/Lobs.java|,12,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/Logger.java|,18,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/LongList.java|,33,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/LongLongList.java|,41,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/LongTreeList.java|,318,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/LongTreeListEnum.java|,10,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/MemoryResult.java|,183,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/MemoryStream.java|,103,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/Money.java|,78,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/Mutable.java|,4,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/MutableDouble.java|,25,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/MutableFloat.java|,25,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/MutableInteger.java|,25,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/MutableLong.java|,25,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/MutableNumeric.java|,427,0.3747072600,{
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/MutableNumeric.java|(14628,787,<515,13>,<532,9>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/MutableNumeric.java|(14133,356,<502,12>,<508,13>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/MutableNumeric.java|(13642,858,<490,8>,<509,9>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/MutableNumeric.java|(15046,358,<525,12>,<531,13>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/MutableNumeric.java|(13732,757,<493,12>,<508,13>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/MutableNumeric.java|(13916,573,<497,12>,<508,13>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/MutableNumeric.java|(13631,876,<489,29>,<510,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/MutableNumeric.java|(14553,862,<513,8>,<532,9>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/MutableNumeric.java|(13717,783,<492,13>,<509,9>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/MutableNumeric.java|(14542,880,<512,31>,<533,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/MutableNumeric.java|(14643,761,<516,12>,<531,13>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/MutableNumeric.java|(14828,576,<520,12>,<531,13>)
  }>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/NoFromResult.java|,77,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/RowSource.java|,49,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/Scrollable.java|,146,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SmallSQLException.java|,96,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SortedResult.java|,196,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SQLParser.java|,1668,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SQLToken.java|,22,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SQLTokenizer.java|,837,0.01911589008,{
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SQLTokenizer.java|(25545,216,<635,4>,<642,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SQLTokenizer.java|(35322,361,<870,4>,<877,5>)
  }>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSCallableStatement.java|,343,0.4577259475,{
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSCallableStatement.java|(4082,243,<108,49>,<116,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSCallableStatement.java|(4990,226,<136,8>,<142,9>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSCallableStatement.java|(5299,305,<144,74>,<153,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSCallableStatement.java|(3293,238,<84,55>,<92,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSCallableStatement.java|(3590,247,<93,57>,<101,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSCallableStatement.java|(4378,244,<117,51>,<125,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSCallableStatement.java|(4093,225,<109,8>,<115,9>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSCallableStatement.java|(6980,238,<193,55>,<201,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSCallableStatement.java|(6278,275,<173,51>,<182,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSCallableStatement.java|(5660,237,<154,54>,<162,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSCallableStatement.java|(7283,300,<202,63>,<211,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSCallableStatement.java|(4677,245,<126,53>,<134,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSCallableStatement.java|(4389,226,<118,8>,<124,9>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSCallableStatement.java|(3601,229,<94,8>,<100,9>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSCallableStatement.java|(6616,307,<183,61>,<192,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSCallableStatement.java|(4688,227,<127,8>,<133,9>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSCallableStatement.java|(5950,275,<163,51>,<172,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSCallableStatement.java|(4979,244,<135,55>,<143,5>)
  }>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSConnection.java|,249,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSDatabaseMetaData.java|,664,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSDriver.java|,72,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSPreparedStatement.java|,227,0.03524229075,{|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSPreparedStatement.java|(8312,261,<247,5>,<254,4>)}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSResultSet.java|,704,0.265625,{
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSResultSet.java|(25526,442,<758,75>,<770,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSResultSet.java|(6568,290,<190,71>,<199,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSResultSet.java|(3307,257,<98,67>,<106,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSResultSet.java|(3871,235,<114,8>,<120,9>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSResultSet.java|(26912,452,<798,85>,<810,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSResultSet.java|(4176,254,<122,61>,<130,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSResultSet.java|(26214,442,<778,75>,<790,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSResultSet.java|(3318,239,<99,8>,<105,9>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSResultSet.java|(4187,236,<123,8>,<129,9>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSResultSet.java|(4495,255,<131,63>,<139,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSResultSet.java|(11185,310,<319,73>,<328,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSResultSet.java|(5540,247,<159,64>,<167,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSResultSet.java|(4817,256,<140,65>,<148,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSResultSet.java|(5850,285,<168,61>,<177,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSResultSet.java|(6210,285,<180,61>,<189,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSResultSet.java|(4506,237,<132,8>,<138,9>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSResultSet.java|(10148,251,<289,65>,<297,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSResultSet.java|(4828,238,<141,8>,<147,9>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSResultSet.java|(3860,253,<113,59>,<121,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSResultSet.java|(5159,315,<149,84>,<158,5>)
  }>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSResultSetMetaData.java|,244,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSSavepoint.java|,18,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSStatement.java|,256,0.03125,{|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/SSStatement.java|(6966,346,<269,13>,<276,13>)}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/Store.java|,24,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/StoreImpl.java|,1290,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/StoreNoCurrentRow.java|,52,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/StoreNull.java|,58,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/StorePage.java|,42,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/StorePageLink.java|,12,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/StorePageMap.java|,109,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/Strings.java|,32,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/Table.java|,391,0.07161125320,{
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/Table.java|(13602,350,<388,20>,<394,21>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/Table.java|(12895,245,<370,6>,<376,7>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/Table.java|(7488,199,<221,56>,<227,2>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/Table.java|(12314,314,<357,6>,<364,7>)
  }>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/TableResult.java|,244,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/TableStorePage.java|,31,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/TableStorePageInsert.java|,19,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/TableView.java|,97,0.09278350515,{|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/TableView.java|(3908,209,<105,3>,<113,3>)}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/TableViewMap.java|,22,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/TableViewResult.java|,47,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/TransactionStep.java|,12,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/UnionAll.java|,143,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/Utils.java|,354,0.1073446328,{
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/Utils.java|(4996,213,<160,40>,<167,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/Utils.java|(4738,214,<151,42>,<158,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/Utils.java|(4308,142,<133,38>,<139,2>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/Utils.java|(4112,153,<125,32>,<131,2>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/Utils.java|(6369,282,<205,43>,<212,5>)
  }>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/View.java|,74,0.09459459459,{|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/View.java|(4377,198,<138,56>,<144,2>)}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/ViewResult.java|,136,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/database/Where.java|,100,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/AllTests.java|,71,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/BasicTestCase.java|,282,0.1134751773,{
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/BasicTestCase.java|(4356,498,<125,8>,<137,9>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/BasicTestCase.java|(4858,372,<138,2>,<150,3>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/BasicTestCase.java|(3576,237,<102,48>,<109,2>)
  }>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/BenchTest.java|,589,0.04074702886,{
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/BenchTest.java|(8192,563,<207,12>,<219,13>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/BenchTest.java|(13127,561,<321,12>,<333,13>)
  }>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestAlterTable.java|,96,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestAlterTable2.java|,60,0.5,{
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestAlterTable2.java|(2515,532,<71,47>,<80,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestAlterTable2.java|(547,561,<29,53>,<38,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestAlterTable2.java|(1174,525,<41,52>,<50,5>)
  }>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestDataTypes.java|,279,0.05734767025,{
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestDataTypes.java|(13046,219,<327,47>,<333,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestDataTypes.java|(3075,279,<68,26>,<77,5>)
  }>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestDBMetaData.java|,217,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestDeleteUpdate.java|,94,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestExceptionMethods.java|,231,0.1298701299,{
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestExceptionMethods.java|(5771,541,<165,60>,<179,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestExceptionMethods.java|(6379,550,<182,61>,<196,5>)
  }>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestExceptions.java|,89,0.1685393258,{
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestExceptions.java|(3521,233,<76,40>,<83,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestExceptions.java|(4815,212,<114,47>,<120,5>)
  }>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestFunctions.java|,370,0.04324324324,{
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestFunctions.java|(23713,210,<406,47>,<412,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestFunctions.java|(22546,279,<374,26>,<383,5>)
  }>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestGroupBy.java|,263,0.09125475285,{
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestGroupBy.java|(5399,452,<168,43>,<179,2>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestGroupBy.java|(4295,430,<141,48>,<152,2>)
  }>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestIdentifer.java|,21,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestJoins.java|,156,0.08974358974,{
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestJoins.java|(10225,202,<195,47>,<201,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestJoins.java|(10508,180,<204,75>,<210,5>)
  }>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestLanguage.java|,185,0.08648648649,{
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestLanguage.java|(7526,399,<251,12>,<259,13>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestLanguage.java|(7050,309,<237,3>,<245,4>)
  }>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestMoneyRounding.java|,66,0.1363636364,{|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestMoneyRounding.java|(1809,279,<53,26>,<62,5>)}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestOperatoren.java|,208,0.1105769231,{
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestOperatoren.java|(11380,212,<253,47>,<259,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestOperatoren.java|(11816,180,<267,75>,<273,5>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestOperatoren.java|(5171,279,<95,26>,<104,5>)
  }>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestOrderBy.java|,613,0.3099510604,{
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestOrderBy.java|(9228,601,<329,47>,<352,2>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestOrderBy.java|(13329,591,<493,48>,<516,2>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestOrderBy.java|(19300,752,<729,57>,<757,2>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestOrderBy.java|(6650,619,<226,59>,<251,2>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestOrderBy.java|(5971,612,<198,56>,<223,2>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestOrderBy.java|(18492,744,<698,53>,<726,2>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestOrderBy.java|(11327,605,<414,51>,<437,2>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestOrderBy.java|(12678,596,<467,50>,<490,2>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestOrderBy.java|(13970,591,<519,43>,<542,2>)
  }>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestOther.java|,227,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestResultSet.java|,185,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestScrollable.java|,229,0.2227074236,{
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestScrollable.java|(1514,988,<43,49>,<61,2>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestScrollable.java|(4387,1001,<108,50>,<126,2>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestScrollable.java|(2969,997,<76,49>,<94,2>)
  }>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestStatement.java|,242,0.03305785124,{|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestStatement.java|(1551,235,<48,43>,<55,5>)}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestThreads.java|,111,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestTokenizer.java|,71,0.,{}>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestTransactions.java|,345,0.2260869565,{
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestTransactions.java|(15688,731,<427,48>,<446,2>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestTransactions.java|(3670,924,<110,58>,<135,2>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestTransactions.java|(5716,929,<169,60>,<194,2>),
    |file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/junit/TestTransactions.java|(14906,727,<405,50>,<424,2>)
  }>,
  <|file:///Users/robinkulhan/Documents/Eclipse%20Workspace/smallsql0.21_src/src/smallsql/tools/CommandLine.java|,65,0.,{}>
];
}
