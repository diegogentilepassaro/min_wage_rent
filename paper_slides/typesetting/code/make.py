import os
import shutil
import re

def main():
    
    in_paper    = '../../paper'
    in_autofill = '../../autofill/output'
    outstub     = '../output'

    clear_output_folders(outstub)
    move_biblio(outstub)
    
    all_inputs = move_tex_files(in_paper, outstub)
    move_images(all_inputs)

def clear_output_folders(outstub):
    
    for filename in os.listdir(outstub):
        file_path = os.path.join(outstub, filename)
        
        if os.path.isfile(file_path):
            os.unlink(file_path)
        elif os.path.isdir(file_path):
            shutil.rmtree(file_path)
            
    for foldername in ['body', 'figures', 'tables', 'images']:
        os.mkdir(os.path.join(outstub, foldername))

def move_biblio(outstub):
    
    shutil.copy(src = '../../biblio.bib',
                dst = os.path.join(outstub, 'biblio.bib'))

def move_tex_files(in_paper, outstub):
    
    with open(os.path.join(in_paper, "min_wage_rent.tex")) as f:
        paper = f.read()
        
    paper = paper.replace(r'\graphicspath{{../../analysis}{../../descriptive}}',
                          r'\graphicspath{{figures}}')
    
    p          = re.compile("input{(.*?)}")
    all_inputs = p.findall(paper)
    
    for full_filename in all_inputs:
        input_parts = full_filename.split('/')
        
        if len(input_parts) == 1:
            shutil.copy(src = os.path.join(in_paper, full_filename + '.tex'),
                        dst = os.path.join(outstub, 'body', full_filename + '.tex'))
                    
        else:
            filename = input_parts[-1]
            
            if input_parts[1] == 'figures':
                out_folder = os.path.join(outstub, 'figures')
                folder_path = 'figures'
            elif input_parts[1] == 'tables':
                out_folder = os.path.join(outstub, 'tables')
                folder_path = 'tables'
            else:
                out_folder = os.path.join(outstub)
                folder_path = ''
            
            shutil.copy(src = os.path.join('..', full_filename),
                        dst = os.path.join(out_folder, filename))
            
            paper.replace(r'\input{' + full_filename + '}',
                          r'\input{' + folder_path + '/' + filename + '}')
    
    
    paper = paper.replace('../autofill/output/', '')
    paper = paper.replace('../figures/',         'figures/')
    paper = paper.replace('../tables/output/',   'tables/')
    
    
    with open(os.path.join(outstub, "min_wage_rent.tex"), 'w') as f:
        f.write(paper)
    
    return(all_inputs)

if __name__ == '__main__':
    main()

