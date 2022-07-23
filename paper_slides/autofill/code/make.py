import os 
import pandas as pd

def main():
    in_main = '../../..'
    output_dir = '../output'

    filelist = pd.read_csv('autofill_files.csv')

    f = open(os.path.join(output_dir, 'autofill.tex'), 'w')

    for col, row in filelist.iterrows():
        tempfile = open(os.path.join(in_main, row[0], row[1] + '.tex'), 'r').read()
        if tempfile[-2:] == '\n\n': #Algunos archivos tienen dos espacios al final
            tempfile = tempfile[:-1]

        tempfile = tempfile.replace("{ ", "{")

        f.write(tempfile)
    f.close()

if __name__ == '__main__':
    main()
