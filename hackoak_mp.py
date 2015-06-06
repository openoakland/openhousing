# script to parse and visualize Oakland major projects spreadsheet

import openpyxl

def parse(sheetname):
    """ Parse spreadsheet
    """

    classlist = [ss.lower() for ss in ['Commercial, Industrial, and Civic Projects', 'Mixed-Use Projects', 'Residential Projects']]
    statelist = [ss.lower() for ss in ['Application Approved','Projects Under Construction','Under Construction','Application Submitted-Under Review','Pre-Application Discussions']]

    wb = openpyxl.load_workbook(sheetname)
    sheets = wb.sheetnames

    d = {}
    for sheet in sheets:
        sh = wb[sheet]
        for row in sh.rows:

            # first define class/state for following rows
            fil = filter(lambda cell: cell.value and type(cell.value) is unicode, row)   # remove Nones and non-unicode
            clfil = filter(lambda cell: cell.value.encode('ascii', 'ignore').lower().strip() in classlist, fil)  # need to convert unicode to string correctly. lowercase and remove trailing empty spaces to match to template
            stfil = filter(lambda cell: cell.value.encode('ascii', 'ignore').lower().strip() in statelist, fil)
            try:
                cl = clfil[0].value.lower()  # define current class of project
            except:
                pass
            try:
                st = stfil[0].value.lower()  # define current state of project
            except:
                pass

            try:
                key = st + ' --- ' + cl    # define keys that are available
                if not d.has_key(key):
                    d[key] = {}  # fill out dict fields
                    d[key]['dist1'] = 0
                    d[key]['dist2'] = 0
                    d[key]['dist3'] = 0
                    d[key]['dist4'] = 0
                    d[key]['dist5'] = 0
                    d[key]['dist6'] = 0
                    d[key]['dist7'] = 0
                    d[key]['total'] = 0
            except:
                continue      # some early rows don't have complete key

            if type(row[0].value) == int:   # this gives us a data row, which is indexed with an int cell
                res = row[5].value.encode('ascii', 'ignore').lower()   # cast description field to string

                # get residential unit count. known to skip lots of cases
                if 'residential' in res:   
                    for bullet in res.split('/n'):   # bullet cast as carriage return
                        units = bullet.split('residential')[0].lstrip('n').rstrip()  # remove a few things from ends
                        try:
                            d[key]['total'] += int(units)   # try to cast into int. if it fails, ignore it.
                            dist = row[4].value
                            if type(dist) == int:
                                d[key]['dist'+str(dist)] += int(units)
                        except:
                            pass

    return d
