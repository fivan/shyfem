c
c revision log :
c
c 06.05.2015    ggu     noselab started
c 05.06.2015    ggu     many more features added
c 30.07.2015    ggu     shyelab started
c 14.09.2015    ggu     support for ext files added
c 05.10.2015    ggu     support for flx files added
c
c**************************************************************

	program shyelab

	use clo
	use elabutil
	use shyfile

c elaborates output file

	implicit none

	integer nc
	character*80 file

	logical check_nos_file,check_ous_file
	logical check_ext_file,check_flx_file
	logical filex

c--------------------------------------------------------------

c--------------------------------------------------------------
c set command line parameters
c--------------------------------------------------------------

	call elabutil_init('SHY')

        nc = command_argument_count()
        if( nc .le. 0 ) then
          write(6,*) 'Usage: shyelab file'
          stop 'error stop shyelab: no files given'
        end if

        call clo_get_file(1,file)

	if( .not. filex(file) ) then
	  write(6,*) 'file does not exists: ',trim(file)
	  stop 'error stop shyelab'
	else if( shy_is_shy_file(file) ) then
	  write(6,*) 'file is of SHY type'
	  call shyelab1
	else if( check_nos_file(file) ) then
	  write(6,*) 'file is of NOS type'
	  write(6,*) 'please convert to SHY format or use noselab'
	  stop 'error stop shyelab'
	else if( check_ous_file(file) ) then
	  write(6,*) 'file is of OUS type'
	  write(6,*) 'please convert to SHY format or use ouselab'
	  stop 'error stop shyelab'
	else if( check_ext_file(file) ) then
	  write(6,*) 'file is of EXT type'
	  write(6,*) 'please use extelab, splitext, extinf'
	  stop 'error stop shyelab'
	else if( check_flx_file(file) ) then
	  write(6,*) 'file is of FLX type'
	  write(6,*) 'please use flxelab, splitflx, flxinf'
	  stop 'error stop shyelab'
	else
	  write(6,*) 'unknown file type: ',trim(file)
	end if
	
        end

c***************************************************************

