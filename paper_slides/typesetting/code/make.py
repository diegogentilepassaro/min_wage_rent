import os
import shutil
import re

def main():
    
    in_paper    = '../../paper'
    in_autofill = '../../autofill/output'
    outstub     = '../output/typesetting'

    clear_output_folders(outstub)
    move_biblio(outstub)
    
    all_inputs = move_tex_files(in_paper, outstub)
    
    move_inputs_and_graphics(all_inputs, outstub)
    
    shutil.make_archive(outstub, 'zip', outstub)
    shutil.rmtree(outstub)
    ## IMPORTANT: Need to manually add the file .bbl for the references to work

def clear_output_folders(outstub):
    
    if os.path.isdir(outstub):
        for filename in os.listdir(outstub):
            file_path = os.path.join(outstub, filename)
            
            if os.path.isfile(file_path):
                os.unlink(file_path)
            elif os.path.isdir(file_path):
                shutil.rmtree(file_path)
    else:
        os.mkdir(outstub)
        os.unlink(outstub + '.zip')
        
    for foldername in ['figures', 'tables', 'graphics']:
        os.mkdir(os.path.join(outstub, foldername))

def move_biblio(outstub):
    
    shutil.copy(src = '../../biblio.bib',
                dst = os.path.join(outstub, 'biblio.bib'))

def move_tex_files(in_paper, outstub):
    
    with open(os.path.join(in_paper, "min_wage_rent.tex")) as f:
        paper = f.read()
    
    paper = paper.replace(r'\addbibresource{../biblio.bib}',
                          r'\addbibresource{biblio.bib}')
    paper = paper.replace(r'\graphicspath{{../../analysis}{../../descriptive}}',
                          r'\graphicspath{{graphics}}')
    paper = paper.replace(r'\usepackage{epstopdf}\n',
                          r'')
    
    p          = re.compile("input{(.*?)}")
    all_inputs = p.findall(paper)
    
    for full_filename in all_inputs:
        input_parts = full_filename.split('/')
        
        if len(input_parts) == 1:
            shutil.copy(src = os.path.join(in_paper, full_filename + '.tex'),
                        dst = os.path.join(outstub, full_filename + '.tex'))
        else:
            filename = input_parts[-1]
            
            if input_parts[1] == 'figures':
                folder_path = 'figures'
            elif input_parts[1] == 'tables':
                folder_path = 'tables'
            else:
                folder_path = ''
            
            
            paper.replace(r'\input{' + full_filename + '}',
                          r'\input{' + folder_path + '/' + filename + '}')
            
            if 'autofill' in full_filename:
                shutil.copy(src = os.path.join('..', full_filename),
                            dst = os.path.join(outstub, filename))
    
    paper = paper.replace('../autofill/output/', '')
    paper = paper.replace('../figures/',         'figures/')
    paper = paper.replace('../tables/output/',   'tables/')    
    
    with open(os.path.join(outstub, "min_wage_rent.tex"), 'w') as f:
        f.write(paper)
    
    return(all_inputs)


def move_inputs_and_graphics(all_inputs, outstub):
    
    # Tables
    tab_inputs = [inp for inp in all_inputs if 'tables' in inp]
    out_folder = os.path.join(outstub, 'tables')
    
    for full_filename in tab_inputs:
        filename = full_filename.split('/')[-1]
        
        shutil.copy(src = os.path.join('..', full_filename),
                    dst = os.path.join(outstub, 'tables', filename))
    
    # Figures
    fig_inputs = [inp for inp in all_inputs if 'figures' in inp]
    out_folder = os.path.join(outstub, 'figures')

    for full_filename in fig_inputs:
        filename = full_filename.split('/')[-1]
        
        with open(os.path.join('..', full_filename), 'r') as f:
            fig = f.read()
        
        p            = re.compile("[\s\]]{(.*?)}")
        all_graphics = p.findall(fig)
        
        for graphic in all_graphics:
            graphic_filename = graphic.split('/')[-1]
            
            is_eps = len(graphic_filename.split('.')) == 1
            
            if is_eps:
                fig = fig.replace(graphic, graphic_filename + '.pdf')
            else:
                fig = fig.replace(graphic, graphic_filename)
            
            for instub in ['descriptive', 'analysis']:
                
                src_fullname = '../../../' + instub + '/' + graphic
                dst_fullname = os.path.join(outstub, 'graphics', graphic_filename)
                
                if is_eps:
                    if os.path.isfile(src_fullname + '.eps'):
                        os.system('epstopdf ' + src_fullname + '.eps')   # Transform eps to pdf
                        
                        src_fullname = src_fullname + '.pdf'
                        dst_fullname = dst_fullname + '.pdf'
                
                if os.path.isfile(src_fullname):
                    shutil.copy(src = src_fullname, dst = dst_fullname)

                    if is_eps:    # Drop transformed eps
                        os.unlink(src_fullname)
        
        with open(os.path.join(out_folder, filename), 'w') as f:
            f.write(fig)
    


if __name__ == '__main__':
    main()

