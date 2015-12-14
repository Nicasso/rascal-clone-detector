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

public void mainVis(int cloneType) {
	CloneDetector::main(cloneType);
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
						onMouseEnter(void () { highlight = true;}), 
						onMouseExit(void () { highlight = false;}),
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
			Vis::dirBoxList += box(
								text(replaceFirst(location.path, Vis::currentLocation.path, "")),
								fillColor(Color () {return highlight ? color(Vis::highlightDirColor) : color(Vis::defaultDirColor);}),
								onMouseEnter(void () {highlight = true;}), 
								onMouseExit(void () {highlight = false;}),
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
								onMouseEnter(void () {highlight = true; Vis::textField = tmploc.file + " (<boxArea> LOC)";}), 
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
	Vis::textField = (numberOfClones == 1) ? "1 clone in this file" : "<numberOfClones> clones in this file";
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
		iprintln(clones);
		int currentLine = 1;
		real shrink = 1.0;
		int endLine = size(readFileLines(Vis::currentLocation));
		list[loc] sortedClones = sortClones(clones);
		for(clone <- sortedClones){
			Vis::fileBoxList += box(
									//text("line: <currentLine> - <clone.begin.line - 1>"),
									vshrink(toReal((clone.begin.line) - (currentLine)) / toReal(endLine))
									);
									shrink -= (toReal((clone.begin.line) - (currentLine)) / toReal(endLine));
									//iprintln("<currentLine> - <clone.begin.line - 1>");
									//iprintln(clone.begin.line - currentLine);
									//iprintln(toReal((clone.begin.line) - (currentLine)) / toReal(endLine));
									//println();
			Vis::fileBoxList += box(
									//text("line: <clone.begin.line> - <clone.end.line>"),
									fillColor("Red"),
									vshrink(toReal((clone.end.line) - (clone.begin.line) + 1) / toReal(endLine))
									);
									shrink -= (toReal((clone.end.line) - (clone.begin.line) + 1) / toReal(endLine));
									//iprintln("CLONE <clone.begin.line> - <clone.end.line>");
									//iprintln(clone.end.line - clone.begin.line + 1);
									//iprintln(toReal((clone.end.line) - (clone.begin.line) + 1) / toReal(endLine));
									//println();
			currentLine = clone.end.line + 1;
		}
		Vis::fileBoxList += box(
								//text("line: <currentLine> - <endLine>"),
								vshrink(shrink - 0.00001)
								);
								//iprintln("<currentLine> - <endLine>");
								//iprintln(endLine - currentLine + 1);
								//iprintln(shrink);
								//println();
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
				vcat(Vis::fileBoxList), 
				vshrink(0.88)),
			box(
				text(str(){return "<Vis::textField>";}), 
				fillColor(Vis::defaultDirColor),
				vshrink(0.04))
		]);
	render(t);
}
