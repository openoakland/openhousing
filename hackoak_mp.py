#!/usr/bin/env python
#
# script to parse and visualize Oakland major projects spreadsheet

import openpyxl, sys
from fuzzywuzzy import fuzz

classlist = [ss.lower() for ss in ['Commercial, Industrial, and Civic Projects', 'Mixed-Use Projects', 'Residential Projects']]
statelist = [ss.lower() for ss in ['Application Approved', 'Under Construction', 'Application Submitted-Under Review', 'Pre-Application Discussions']]

distrow = 4
unitrow = 5

def parseall(sheetname):
    """ Parse spreadsheet
    """

    wb = openpyxl.load_workbook(sheetname)
    sheets = wb.sheetnames

    d = {}
    for sheet in [sheets[0]]:    # hacky. first sheet probably only one needed
        sh = wb[sheet]
        good = 0; failed = 0; thresh = 75
        for row in sh.rows:
            # first define class/state for following rows
            fil = filter(lambda cell: cell.value and type(cell.value) is unicode, row)   # remove Nones and non-unicode
            if len(fil) == 1:
                clfil = filter(lambda cl: fuzz.ratio(fil[0].value.encode('ascii', 'ignore').lower().strip(), cl) > thresh, classlist)  # need to convert unicode to string correctly. lowercase and remove trailing empty spaces to match to template
                stfil = filter(lambda st: fuzz.ratio(fil[0].value.encode('ascii', 'ignore').lower().strip(), st) > thresh, statelist)  # need to convert unicode to string correctly. lowercase and remove trailing empty spaces to match to template
#                clfil = filter(lambda cell: cell.value.encode('ascii', 'ignore').lower().strip() in classlist, fil)  # need to convert unicode to string correctly. lowercase and remove trailing empty spaces to match to template
#                stfil = filter(lambda cell: cell.value.encode('ascii', 'ignore').lower().strip() in statelist, fil)
                if len(clfil) == 1:
                    cl = clfil[0]
                    print 'class = %s' % cl
                if len(stfil) == 1:
                    st = stfil[0]
                    print 'state = %s' % st

            try:
                key = st + ' --- ' + cl    # define keys that are available
                if not d.has_key(key):
                    d[key] = {}  # fill out dict fields
                    d[key]['d1'] = 0
                    d[key]['d2'] = 0
                    d[key]['d3'] = 0
                    d[key]['d4'] = 0
                    d[key]['d5'] = 0
                    d[key]['d6'] = 0
                    d[key]['d7'] = 0
                    d[key]['units'] = 0
                    d[key]['ad1'] = 0
                    d[key]['ad2'] = 0
                    d[key]['ad3'] = 0
                    d[key]['ad4'] = 0
                    d[key]['ad5'] = 0
                    d[key]['ad6'] = 0
                    d[key]['ad7'] = 0
                    d[key]['aunits'] = 0
            except:
                continue      # some early rows don't have complete key

            if type(row[0].value) == int:   # this gives us a data row, which is indexed with an int cell
                if 'units' in row[unitrow].value.encode('ascii', 'ignore').lower():   # if this cell refers to "units"
                    try:
                        units, aunits = getunits(row[unitrow])
                    except:
                        print
                        print row[unitrow].value
                        try:
                            print '\t*** Auto parse failed. ***'
                            (units, aunits) = input('\t*** Enter (units, affordable units) above? (comma-delimited; type enter to skip) ***')
                        except:
                            print '*** Input not parsed correctly. Second try. ***'
                            (units, aunits) = input('\t*** Enter (units, affordable units) above? (comma-delimited; type enter to skip) ***')
                        failed += 1

                    try:
                        dist = getdist(row[distrow])
                    except:
                        print
                        print row[distrow].value
                        try:
                            dist = int(input('\t*** Auto parse failed. What district is given above? ***'))
                        except SyntaxError:
                            pass
                        failed += 1

                if dist:    # if we parsed both values, then add to dictionary
                    good += 1
                    if units:
                        d[key]['units'] += units
                        d[key]['d'+str(dist)] += units
                    elif aunits:
                        d[key]['aunits'] += aunits
                        d[key]['ad'+str(dist)] += aunits
        print 'Autoparsed %d rows. Parsed %d manually.' % (good, failed)
    return d

def getunits(cell):
    """ Takes description cell value
    Tries to parse it to get residential unit count.
    """

    res = cell.value.encode('ascii', 'ignore').lower()   # cast description field to string

    # get residential unit count. known to skip lots of cases
    for bullet in res.split('\n'):   # bullet cast as carriage return
        words = bullet.split(' ')
        if 'units' in words:
            for loc in range(words.index('units'), -1, -1):
                try:
                    units = int(words[loc].lstrip('n').rstrip())
                except ValueError:
                    pass
                else:
                    if 'affordable' in words:   # are these units affordable?
                        aunits = units
                        units = 0
                    else:
                        aunits = 0
                    print 'Parsed %d units and %d affordable units.' % (units, aunits)
                    break
#        units = int(bullet.split('residential')[0].lstrip('n').lstrip('n').rstrip().rstrip('n'))  # remove a few things from ends

    return (units, aunits)

def getdist(cell):
    """ Parse cell for district info. Can be multiple values, but we just take first one.
    """

    if type(cell.value) == unicode:
        cell2 = cell.value.encode('ascii', 'ignore')
        try:
            dist = int(cell2.split(' and ')[0])
        except:
            dist = int(cell2.split(' & ')[0])
        finally:
            print 'Parsed %s as district %d' % (cell2, dist)
    else:
        dist = int(cell.value)
        print 'Parsed district %d' % (dist)

    return dist

def table(d):
    """ Print out distribution of housing of all types in each district as table
    """

    header = sorted(d[d.keys()[0]].keys())
    print '%60s' % ('category'),
    for h in header:
        print h,
    print

    for category in d.iterkeys():
        print '%60s' % (category),
        for h in header:
            print d[category][h],
        print

if __name__ == '__main__':
    filename = sys.argv[1]
    d = parseall(filename)
    table(d)
