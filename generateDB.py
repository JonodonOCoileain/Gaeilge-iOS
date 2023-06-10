import sqlite3

separators = ["plc", "adv", "n3", "n4", "nf","n1","n2","nf1","nf2","nf3","nf4","nf5","nm","nm1","nm2","nm3","nm4","nm5","vb","adjn","adj","nmbr", "n", "prep", "npl", "prefx","cnj","cphrs","pron", "nmadj", "nidiom", "nadj", "adjf"]

sqliteConnection = sqlite3.connect('GaeilgeAppData.db')

cursor = sqliteConnection.cursor()

# SQL command to create a table in the database
sql_command = """CREATE TABLE entries (
filename VARCHAR(30) PRIMARY KEY,
definition VARCHAR(40),
frequency INTEGER,
pronounceableLocally BOOL);"""
 
# execute the statement
cursor.execute(sql_command)

entriesFile = open('/Users/jonotdonocoileain/Gaeilge/CollinsToCoileain-iOS/clean.txt', 'r')
entriesLines = entriesFile.readlines()
words = []

for line in entriesLines:
    values = line.split()
    storedValue = ""
    indexOfSeparator = 0
    enumeratedValues = enumerate(values)
    separtor = ""
    for (index, value) in enumeratedValues:
        for separatore in separators:
            if separatore == value:
                separator = value
                indexOfSeparator = index
        
    if indexOfSeparator != 0:
        word = " ".join(values[0:indexOfSeparator])
        pronounceableLocally = values.pop(len(values)-1)
        frequency = values.pop(len(values)-1)
        newValues = []
        for value in values:
            if value != " ":
                if value != "":
                    newValues.append(value)
            else:
                print("array value was space for: " + values)
        if (indexOfSeparator+1 == len(newValues) - 1):
            print(newValues)
            definition = separator + " " + newValues[indexOfSeparator+1]
        else:
            print(newValues)
            definition = separator + " " + " ".join(newValues[indexOfSeparator+1:len(newValues)-1])
    
        containsWord = 0
        for oldWord in words:
            if oldWord == word:
                containsWord = 1

        if containsWord == 0:
            words.append(word)
            print(definition)
            #command = "INSERT INTO entries (filename, definition, frequency, pronounceableLocally) VALUES (?,?,?,?)",(word, definition, frequency, pronounceableLocally)
            cursor.execute("INSERT INTO entries (filename, definition, frequency, pronounceableLocally) VALUES (?,?,?,?)",(word, definition, frequency, pronounceableLocally))

sqliteConnection.commit()
# close the connection
cursor.close()