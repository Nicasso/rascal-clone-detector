module Helper

import IO;
import String;

public real computeLOC(loc location){
	real count = 0.0;
	str content = readFile(location);
	commentFree = visit(content){
		case /(\/\*[\s\S]*?\*\/|\/\/[\s\S]*?(\n|\r))/ => ""
	}
	list[str] lines = split("\n",commentFree);
	for( i <- lines, trim(i) != "")
		count += 1;
	return count;
}