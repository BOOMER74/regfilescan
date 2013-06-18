/*
 * regfilescan v1.1
 */

module main;

import std.stdio, std.conv, std.file, std.string, std.regex, std.algorithm, std.path;

int[] scanRange(string[] lines, int start, int end, string star, string question) {
	int[] outlinesIndex;

	foreach (int i; start..end) {
		foreach (int j; 0..lines.length - 1) {
			if ((i != j) && (std.regex.match(std.array.replace(std.array.replace(lines[i], "?", question), "*", star), std.regex.regex(std.array.replace(std.array.replace(std.array.replace(std.array.replace(lines[j], ".", "\b"), "?", "."), "*", ".*?"), "\b", "\\."))))) {
				outlinesIndex ~= i;
			}
		}
	}

	return outlinesIndex;
}

class scanThread : core.thread.Thread {
public:
	string[] lines;
	bool stoped = false;
	int[] outlinesIndex;
	string star, question;
	int start, end, priorityValue;

	this() {
		super(&threadRun);
	}
private:
	void threadRun() {
		this.priority(priorityValue);

		outlinesIndex = scanRange(lines, start, end, star, question);
	}
}

void main(string[] args) {
	if (args.length >= 2) {
		string fileName = args[1];

		if (exists(fileName)) {
			int threads = 10, priority = 0;
			string star = "test", question = "t";
			string[] lines = splitLines(readText(fileName));

			if (args.length >= 3) {
				foreach (int i; 2..args.length) {
					string[] arg = std.string.split(args[i], "=");

					switch (arg[0]) {
						case "-t": threads = isNumeric(arg[1]) ? to!int(arg[1]) > 1 ? to!int(arg[1]) : threads : threads; break;
						case "-s": star = arg[1].length > 0 ? arg[1] : star; break;
						case "-q": question = arg[1].length > 0 ? arg[1] : question; break;
						case "-p": priority = arg[1] == "min" ? -15 : arg[1] == "max" ? -15 : priority; break;
						default: writeln("Error in arguments!");
					}
				}
			}

			if (lines.length >= threads) {
				scanThread[] threadsArr;

				int now = 0, how = lines.length / threads;

				foreach (int i; 0..threads) {
					threadsArr ~= new scanThread();

					threadsArr[i].name = "#" ~ to!string(i);

					threadsArr[i].lines = lines;

					threadsArr[i].start = now;
					threadsArr[i].end = (i != threads - 1) ? (now + how - 1) : ((now + (lines.length -  now)) - 1);
					threadsArr[i].priorityValue = priority;

					threadsArr[i].star = star;
					threadsArr[i].question = question;

					now += how;
				}

				writefln("Program started with %d threads (%s priority), \"%s\" as star (*) symbol and \"%s\" as question (?) symbol...", threads, priority == 0 ? "normal" : priority < 0 ? "minimum" : "maximum", star, question);

				foreach (core.thread.Thread thread; threadsArr) {
					thread.start();
				}

				while (true) {
					bool stop = false;

					foreach (scanThread thread; threadsArr) {
						if (thread.isRunning()) {
							stop = false;
							break;
						} else {
							if (!thread.stoped) {
								writefln("Thread %s finished!", thread.name);
								thread.stoped = stop = true;
							}
						}
					}

					if (stop) {
						break;
					}
				}

				int[] tempOutlinesIndex, outlinesIndex;

				foreach (scanThread thread; threadsArr) {
					foreach (int i; thread.outlinesIndex) {
						tempOutlinesIndex ~= i;
					}
				}

				foreach (int i; tempOutlinesIndex) {
					bool notFindCopy = true;

					foreach (int j; outlinesIndex) {
						if (lines[i] == lines[j]) {
							notFindCopy = false;
							break;
						}
					}

					if (notFindCopy) {
						outlinesIndex ~= i;
					}
				}

				string writeFile = stripExtension(fileName) ~ "-out" ~ extension(fileName);

				if (std.file.exists(writeFile)) {
					std.file.remove(writeFile);
				}

				foreach (int i, string str; lines) {
					if (find(outlinesIndex, i) == []) {
						if (std.file.exists(writeFile)) {
							std.file.append(writeFile, str ~ "\n");
						} else {
							std.file.write(writeFile, str ~ "\n");
						}
					}
				}
			} else {
				writefln("Program started with one thread (normal priority), \"%s\" as star (*) symbol and \"%s\" as question (?) symbol...", star, question);

				scanRange(lines, 0, lines.length - 1, star, question);
			}
		} else {
			if (args[1] == "/?") {
				writeln("Using:\n\tregfilescan filename [-t] [-s] [-q] [-p]\n\n\tfilename\tName of file with path\n\nProgram arguments:\n\t-t\tNumber of threads (default 10, minimum value 2)\n\t\tExample: -t=100 - scan file with 100 threads\n\n\t-s\tReplace text for star (*) symbol (default \"test\")\n\t\tExample: -s=replace - replace star (*) symbol in mask to \"replace\"\n\n\t-q\tReplace text for question (?) symbol (default \"t\")\n\t\tExample: -q=r - replace question (?) symbol in mask to \"r\" (you can replace question (?) symbol to one character and whole word)\n\n\t-p\tPriority of threads (default Normal, exists values: min, max)\n\t\tExample: -p=min - set minimum priority for all threads\n\nFull example: regfilescan regfile.txt -t=100 -s=replace -q=r -p=min\n\n\tScan regfile.txt with 100 threads (minimum priority), \"replace\" as star (*) symbol and \"r\" as question (?) symbol\n\nTo show help text (this) use /? argument\n\nOn output you get file with name: filename-out.ext\nExample: regfile.txt -> regfile-out.txt");
			} else {
				writeln("File not found!");
			}
		}
	} else {
		writeln("Not found argument with file path! For help use /? argument.");
	}
}