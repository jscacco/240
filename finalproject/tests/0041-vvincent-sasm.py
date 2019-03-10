#chmod a+x sasm
#!/usr/bin/python2

import sys

found = False

"""
class Line():
    def __init__(self, f):
        self._line = f.readline() 

    def returnline():
        return self._line

    def cutoff40(self):
        pass

    def detabify(self):
        pass

    def checkiflabel(self):
    #   self._label = dehwueiue
    #   if self_label == fnjrmrf 
        pass

    def returnlabel(self):
        return self._label

def create_hash_table():
    file_name = sys.argv[1]
    file = open(file_name, "r")
    lines = []
    for line in file:
        this_line = file.readline()
        lines.append(this_line)
        print(this_line)
        
        #this_line = Line(file)
        #idk = this_line.returnline()
        #print(idk)
        #this_line.cutoff40()
        #this_line.detabify()
        #this_line.checkiflabel()
        #if this_line == True:
        #   newlabel = this._line.returnlabel()

def output_hash_table():
    pass

def main():
    create_hash_table()

main()
"""

#instruction_length = {
#    add = 

#}


labels = {}


def cutoff40(l):
    return l[:40]


def add_label(l, loc):
    labels[l.upper()] = loc
    return


def check_if_label(l):
    possible_label = ""
    for char in l:
        if char == ":":
            global found
            found = True
            return possible_label
        possible_label = possible_label + char
    return possible_label


def output_hash():
    for key, value in labels.iteritems():
        string = "  " + key + ": " + str(value)
        print(string)
    return


def main():
    file_name = sys.argv[1]
    file = open(file_name, "r")
    loc = 0

    print("Symbols:")

    for line in file:
        line_new = cutoff40(line)
        label = check_if_label(line_new)
        global found
        if found is True:
            add_label(label, loc)
        loc = loc + 3
        found = False

    output_hash()
    return

main()