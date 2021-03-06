!
! revision log :
!
! 18.11.1998    ggu     check dimensions with dimnos
! 06.04.1999    ggu     some cosmetic changes
! 03.12.2001    ggu     some extra output -> place of min/max
! 09.12.2003    ggu     check for NaN introduced
! 07.03.2007    ggu     easier call
! 08.11.2008    ggu     do not compute min/max in non-existing layers
! 07.12.2010    ggu     write statistics on depth distribution (depth_stats)
! 06.05.2015    ggu     noselab started
! 05.06.2015    ggu     many more features added
! 10.09.2015    ggu     std and rms for averaging implemented
! 11.09.2015    ggu     write in gis format
! 23.09.2015    ggu     handle more than one file (look for itstart)
! 16.10.2015    ggu     started shyelab
! 10.06.2016    ggu     shyplot now plots fem files
! 13.06.2016    ggu     shyplot now plots barotropic vars (layer==0)
!
!**************************************************************

	program shyplot

	use plotutil

	implicit none

	call plotutil_init('SHY')
	call classify_files

	if( shyfilename /= ' ' ) then
	  call plot_shy_file
	else if( femfilename /= ' ' ) then
	  call plot_fem_file
	else if( basfilename /= ' ' ) then
	  call plot_bas_file
	end if

	end

!**************************************************************

	subroutine plot_bas_file

        use mod_depth
        use mod_geom
        use evgeom
        use basin
        use plotutil

	implicit none

	integer ivar

        call read_command_line_file(basfilename)

        call ev_init(nel)
        call set_ev

        call mod_geom_init(nkn,nel,ngr)
        call set_geom

        call mod_depth_init(nkn,nel)

        call makehev(hev)
        call makehkv(hkv)
        call allocate_2d_arrays(nel)

        call init_plot

	ivar = 5			!bathymetry
	call init_nls_fnm
	call read_str_files(-1)
	call read_str_files(ivar)
        call initialize_color

        call qopen
	call plobas
        call qclose

	end

!**************************************************************

	subroutine plot_shy_file

	use clo
	!use elabutil
	use plotutil
	use elabtime
	use shyfile
	use shyutil

        use basin
        use levels
        use evgeom
        use mod_depth
	use mod_hydro_plot
        use mod_hydro
        use mod_hydro_vel
        use mod_hydro_print

	implicit none

	real, allocatable :: cv2(:)
	real, allocatable :: cv3(:,:)
	real, allocatable :: cv3all(:,:,:)

	integer, allocatable :: idims(:,:)
	integer, allocatable :: il(:)
	integer, allocatable :: ivars(:)
	character*80, allocatable :: strings(:)

	logical bhydro,bscalar,bsect
	integer nwrite,nread,nelab,nrec,nin,nold
	integer nvers
	integer nvar,npr
	integer ierr,ivel,iarrow
	integer it
	integer ivar,iaux,nv
	integer ivarplot(2)
	integer iv,j,l,k,lmax,node
	integer ip
	integer ifile,ftype
	integer id,idout,idold
	integer n,m,nndim,nn
	integer naccum
	integer isphe
	integer date,time
	character*80 title,name,file
	character*80 basnam,simnam,varline
	real rnull
	real cmin,cmax,cmed,vtot
	double precision dtime
	double precision atime

	integer iapini
	integer ifem_open_file
	integer getisec
	real getpar

!--------------------------------------------------------------
! initialize everything
!--------------------------------------------------------------

	nread=0
	nwrite=0
	nelab=0
	nrec=0
	rnull=0.
	rnull=-1.
	bzeta = .false.		!file has zeta information
	ifile = 0
	id = 0
	idold = 0

	!--------------------------------------------------------------
	! set command line parameters
	!--------------------------------------------------------------

	call init_nls_fnm
	call read_str_files(-1)
	call read_str_files(ivar3)

	!--------------------------------------------------------------
	! open input files
	!--------------------------------------------------------------

	call open_next_file_by_name(shyfilename,idold,id)
	if( id == 0 ) stop

	!--------------------------------------------------------------
	! set up params and modules
	!--------------------------------------------------------------

	call shy_get_params(id,nkn,nel,npr,nlv,nvar)
	call shy_get_ftype(id,ftype)

	call shy_info(id)

        call basin_init(nkn,nel)
        call levels_init(nkn,nel,nlv)

	call shy_copy_basin_from_shy(id)
	call shy_copy_levels_from_shy(id)

        call mod_depth_init(nkn,nel)
	call allocate_2d_arrays(nel)
	call allocate_simulation(0)
	call mod_hydro_plot_init(nkn,nel)

        isphe = nint(getpar('isphe'))
        call set_coords_ev(isphe)
        call set_ev
        call set_geom
        call get_coords_ev(isphe)
        call putpar('isphe',float(isphe))

	!--------------------------------------------------------------
	! set time
	!--------------------------------------------------------------

        call ptime_init
	call shy_get_date(id,date,time)
        call ptime_set_date_time(date,time)
        call elabtime_date_and_time(date,time)
        call elabtime_minmax(stmin,stmax)
	call elabtime_set_inclusive(.false.)

	!--------------------------------------------------------------
	! set dimensions and allocate arrays
	!--------------------------------------------------------------

	bhydro = ftype == 1
	bscalar = ftype == 2

	if( bhydro ) then		!OUS
	  if( nvar /= 4 ) goto 71
	  nndim = 3*nel
	  allocate(il(nel))
	  il = ilhv
	else if( bscalar ) then		!NOS
	  nndim = nkn
	  allocate(il(nkn))
	  il = ilhkv
	else
	  goto 76	!relax later
	end if

	allocate(cv2(nndim))
	allocate(cv3(nlv,nndim))
	allocate(cv3all(nlv,nndim,0:nvar))
	allocate(idims(4,nvar))
	allocate(ivars(nvar),strings(nvar))

	!--------------------------------------------------------------
	! set up aux arrays, sigma info and depth values
	!--------------------------------------------------------------

	call shyutil_init(nkn,nel,nlv)

	call init_sigma_info(nlv,hlv)

	call shy_make_area
	call outfile_make_depth(nkn,nel,nen3v,hm3v,hev,hkv)

	if( bverb ) call depth_stats(nkn,nlvdi,ilhkv)

	!--------------------------------------------------------------
	! initialize plot
	!--------------------------------------------------------------

	call init_plot

	call shy_get_string_descriptions(id,nvar,ivars,strings)
	call choose_var(nvar,ivars,strings,varline,ivarplot) !set bdir, ivar3

	bsect = getisec() /= 0
	call setlev(layer)

	!--------------------------------------------------------------
	! initialize volume
	!--------------------------------------------------------------

	shy_zeta = 0.
	call shy_make_volume

	!--------------------------------------------------------------
	! initialize plot
	!--------------------------------------------------------------

        call initialize_color

	call qopen

!--------------------------------------------------------------
! loop on data
!--------------------------------------------------------------

	dtime = 0.
	cv3 = 0.
	cv3all = 0.

	do

	 !--------------------------------------------------------------
	 ! read new data set
	 !--------------------------------------------------------------

	 call read_records(id,dtime,nvar,nndim,nlvdi,idims
     +				,cv3,cv3all,ierr)

         if(ierr.ne.0) exit

	 call dts_convert_to_atime(datetime_elab,dtime,atime)

	 if( .not. bquiet ) call shy_write_time(.true.,dtime,atime,0)

	 iarrow = 0
	 nread = nread + 1
	 nrec = nrec + nvar

	 !--------------------------------------------------------------
	 ! see if we are in time window
	 !--------------------------------------------------------------

	 if( elabtime_over_time(atime) ) exit
	 if( .not. elabtime_in_time(atime) ) cycle

	 call shy_make_zeta(ftype)
	 !call shy_make_volume		!comment for constant volume

	 if( ifreq > 0 .and. mod(nread,ifreq) /= 0 ) cycle

	 call ptime_set_dtime(dtime)

	 !--------------------------------------------------------------
	 ! loop over single variables
	 !--------------------------------------------------------------

	 do iv=1,nvar

	  n = idims(1,iv)
	  m = idims(2,iv)
	  lmax = idims(3,iv)
	  ivar = idims(4,iv)
	  nn = n * m

	  if( ivar /= ivar3 .and. .not. bdir ) cycle
	  if( ivar == 1 .and. m == 3 ) cycle	!water level in element
	  if( ivar == 1 .and. bdir ) cycle	!want to plot vel/trans
	  if( m /= 1 ) stop 'error stop: m/= 1'

	  cv3(:,:) = cv3all(:,:,iv)

	  nelab = nelab + 1

	  if( .not. bquiet ) then
	    call shy_write_time(.true.,dtime,atime,ivar)
	  end if

	  if( bsect ) then
	    if( ivar == 3 .and. iv == 3 ) utlnv(:,1:nel) = cv3(:,1:nel)
	    if( ivar == 3 .and. iv == 4 ) vtlnv(:,1:nel) = cv3(:,1:nel)
	  else if( b2d ) then
	    call shy_make_vert_aver(idims(:,iv),nndim,cv3,cv2)
	  else
	    if( n == nkn .and. ivar == 1 ) then
	      cv2(:) = cv3(1,:)
	    else if( n == nkn ) then
	      call extnlev(layer,nlvdi,nkn,cv3,cv2)
	    else if( n == nel ) then
	      call extelev(layer,nlvdi,nel,cv3,cv2)
	    else
	      write(6,*) 'n,nkn,nel: ',n,nkn,nel
	      stop 'error stop: n'
	    end if
	  end if

	  call make_mask(layer)

	  call directional_insert(bdir,ivar,ivar3,ivarplot,cv2,ivel)
	  if( bdir .and. ivel == 0 ) cycle

	  write(6,*) 'plotting: ',ivar,layer,n,ivel

          !call prepare_dry_mask
	  !call reset_dry_mask
	  if( bsect ) then
	    if( ivel > 0 ) then
	      call prepare_vel(cv3)
	      call plot_sect(.true.,cv3)
	    else
	      call plot_sect(.false.,cv3)
	    end if
	  else if( ivel > 0 ) then
	    call plo2vel(ivel,'3D ')
	  else if( n == nkn ) then
            call ploval(nkn,cv2,varline)
	  else if( n == nel ) then
            call ploeval(nel,cv2,varline)
	  else
	    write(6,*) 'n,nkn,nel: ',n,nkn,nel
	    stop 'error stop: n'
	  end if

	 end do		!loop on ivar

	 !--------------------------------------------------------------
	 ! finished loop over single variables - handle hydro file
	 !--------------------------------------------------------------

	end do		!time do loop

!--------------------------------------------------------------
! end of loop on data
!--------------------------------------------------------------

	call qclose
	write(6,*) 'total number of plots: ',nelab

!--------------------------------------------------------------
! final write of variables
!--------------------------------------------------------------

!--------------------------------------------------------------
! end of routine
!--------------------------------------------------------------

	stop
   71	continue
	write(6,*) 'ftype = ',ftype,'  nvar = ',nvar
	write(6,*) 'nvar should be 4'
	stop 'error stop shyelab: ftype,nvar'
   74	continue
	stop 'error stop shyelab: general error...'
   75	continue
	write(6,*) 'error writing header, ierr = ',ierr
	write(6,*) 'file = ',trim(file)
	stop 'error stop shyelab: writing header'
   76	continue
	write(6,*) 'ftype = ',ftype,'  expecting 1 or 2'
	stop 'error stop shyelab: ftype'
   77	continue
	write(6,*) 'error reading header, ierr = ',ierr
	write(6,*) 'file = ',trim(file)
	stop 'error stop shyelab: reading header'
	end

!***************************************************************
!***************************************************************
!***************************************************************

	subroutine plot_fem_file

	use clo
	!use elabutil
	use plotutil
	use elabtime
	use shyfile
	use shyutil

        use basin
        use levels
        use evgeom
        use mod_depth
        use mod_geom

	implicit none

	logical bhasbasin,breg
	logical bsect,bskip
	logical bintp,bplotreg
	integer i,ierr,iformat,irec,l
	integer isphe,iunit,lmax,lmax0,np,np0
	integer ntype,nvar,nvar0,nvers
	integer date,time
	integer datetime(2)
	integer itype(2)
	integer ivarplot(2)
	real regpar(7)
	real flag
	double precision dtime,atime,atime0
	character*80 line,string,varline
        real,allocatable :: data2d(:)
        real,allocatable :: data3d(:,:)
        real,allocatable :: data(:,:,:)
        real,allocatable :: dext(:)
        real,allocatable :: hd(:)
        !real,allocatable :: hlv(:)
        !integer,allocatable :: ilhkv(:)
        integer,allocatable :: ivars(:)
        character*80, allocatable :: strings(:)

	integer getisec
	real getpar

        !--------------------------------------------------------------
        ! set command line parameters
        !--------------------------------------------------------------

        call init_nls_fnm
        call read_str_files(-1)
        call read_str_files(ivar3)

        !--------------------------------------------------------------
        ! open input files
        !--------------------------------------------------------------

	infile = femfilename
        if( infile .eq. ' ' ) stop

        np = 0
        call fem_file_read_open(infile,np,iformat,iunit)
        if( iunit .le. 0 ) stop

        write(6,*) 'file name: ',infile(1:len_trim(infile))
        call fem_file_get_format_description(iformat,line)
        write(6,*) 'format: ',iformat,"  (",line(1:len_trim(line)),")"

        !--------------------------------------------------------------
        ! set up params and modules
        !--------------------------------------------------------------



	!--------------------------------------------------------------
	! read first record
	!--------------------------------------------------------------

        call fem_file_read_params(iformat,iunit,dtime
     +                          ,nvers,np,lmax,nvar,ntype,datetime,ierr)

        if( ierr .ne. 0 ) goto 99

        if( .not. bquiet ) then
          write(6,*) 'nvers:  ',nvers
          write(6,*) 'np:     ',np
          write(6,*) 'lmax:   ',lmax
          write(6,*) 'nvar:   ',nvar
          write(6,*) 'ntype:  ',ntype
        end if

	nlv = lmax
        call levels_init(np,np,nlv)	!first call - will be changed later
        call fem_file_make_type(ntype,2,itype)

        call fem_file_read_2header(iformat,iunit,ntype,lmax
     +                  ,hlv,regpar,ierr)
        if( ierr .ne. 0 ) goto 98

        if( lmax > 1 .and. .not. bquiet ) then
          write(6,*) 'vertical layers: ',lmax
          write(6,*) hlv
        end if
        if( itype(1) .gt. 0 .and. .not. bquiet ) then
          write(6,*) 'date and time: ',datetime
        end if
        breg = .false.
        if( itype(2) .gt. 0 .and. .not. bquiet ) then
          breg = .true.
          write(6,*) 'regpar: ',regpar
        end if

        !--------------------------------------------------------------
        ! configure basin
        !--------------------------------------------------------------

	bhasbasin = basfilename /= ' '

	if( bhasbasin ) then
          call read_command_line_file(basfilename)
	else if( breg ) then
	  call bas_insert_regular(regpar)
	end if

	if( bhasbasin .or. breg ) then
          call ev_init(nel)
          isphe = nint(getpar('isphe'))
          call set_coords_ev(isphe)
          call set_ev
          call get_coords_ev(isphe)
          call putpar('isphe',float(isphe))

          call mod_geom_init(nkn,nel,ngr)
          call set_geom

          call levels_init(nkn,nel,nlv)
          call mod_depth_init(nkn,nel)

          call makehev(hev)
          call makehkv(hkv)
          call allocate_2d_arrays(nel)
	end if

	if( breg ) then
	  bplotreg = .true.
	  bintp = .false.
	  if( bhasbasin ) bintp = .true.
	  if( bregall ) bintp = .false.
	else
	  bplotreg = .false.
	  bintp = .true.
	  if( bhasbasin ) then
	    if( nkn /= np ) goto 93
	    if( basintype /= 'bas' ) goto 92
	  else
	    !goto 94
	  end if
	end if

        nvar0 = nvar
        lmax0 = lmax
        np0 = np
        allocate(strings(nvar))
        allocate(ivars(nvar))
        allocate(dext(nvar))
        allocate(data2d(np))
        allocate(data3d(lmax,np))
        allocate(data(lmax,np,nvar))
        allocate(hd(np))
        !allocate(ilhkv(np))

	!--------------------------------------------------------------
	! choose variable to plot
	!--------------------------------------------------------------

        do i=1,nvar
          call fem_file_skip_data(iformat,iunit
     +                          ,nvers,np,lmax,string,ierr)
          if( ierr .ne. 0 ) goto 97
          strings(i) = string
        end do

	call get_vars_from_string(nvar,strings,ivars)
	call choose_var(nvar,ivars,strings,varline,ivarplot) !set bdir, ivar3

	if( .not. breg .and. .not. bhasbasin ) goto 94

	!--------------------------------------------------------------
	! close and re-open file
	!--------------------------------------------------------------

        close(iunit)

        np = 0
        call fem_file_read_open(infile,np,iformat,iunit)
        if( iunit .le. 0 ) stop

        !--------------------------------------------------------------
        ! set time
        !--------------------------------------------------------------

        call dts_convert_to_atime(datetime,dtime,atime)
        atime0 = atime          !absolute time of first record

	date = datetime(1)
	time = datetime(2)
        call ptime_init
        call ptime_set_date_time(date,time)
        call elabtime_date_and_time(date,time)
        call elabtime_minmax(stmin,stmax)
        call elabtime_set_inclusive(.false.)

	!--------------------------------------------------------------
	! initialize plot
	!--------------------------------------------------------------

        call init_plot

	bsect = getisec() /= 0
	call setlev(layer)
	b2d = layer == 0

        call initialize_color

	call qopen

        !--------------------------------------------------------------
        ! loop on records
        !--------------------------------------------------------------

        irec = 0

        do
          irec = irec + 1
          call fem_file_read_params(iformat,iunit,dtime
     +                          ,nvers,np,lmax,nvar,ntype,datetime,ierr)
          if( ierr .lt. 0 ) exit
          if( ierr .gt. 0 ) goto 99
          if( nvar .ne. nvar0 ) goto 96
          if( lmax .ne. lmax0 ) goto 96
          if( np .ne. np0 ) goto 96

          call dts_convert_to_atime(datetime,dtime,atime)
          call dts_format_abs_time(atime,line)
	  call ptime_set_atime(atime)

          if( bdebug ) write(6,*) irec,atime,line

          call fem_file_read_2header(iformat,iunit,ntype,lmax
     +                  ,hlv,regpar,ierr)
          if( ierr .ne. 0 ) goto 98
	  call init_sigma_info(lmax,hlv)

	  bskip = .false.
	  if( elabtime_over_time(atime) ) exit
	  if( .not. elabtime_in_time(atime) ) bskip = .true.
	  if( ifreq > 0 .and. mod(irec,ifreq) /= 0 ) bskip = .true.

	  write(6,*) irec,atime,line

          do i=1,nvar
            if( bskip ) then
              call fem_file_skip_data(iformat,iunit
     +                          ,nvers,np,lmax,string,ierr)
            else
              call fem_file_read_data(iformat,iunit
     +                          ,nvers,np,lmax
     +                          ,string
     +                          ,ilhkv,hd
     +                          ,lmax,data(1,1,i)
     +                          ,ierr)
            end if
            if( ierr .ne. 0 ) goto 97
            if( string .ne. strings(i) ) goto 95
          end do

	  data3d = data(:,:,ivnum)

	  flag = dflag
	  call adjust_levels_with_flag(nlvdi,np,ilhkv,flag,data3d)

	  if( b2d ) then
	    call fem_average_vertical(nlvdi,np,lmax,ilhkv,hlv,hd
     +					,data3d,data2d)
	  else
	    call extlev(layer,nlvdi,np,ilhkv,data3d,data2d)
	  end if

	  if( bplotreg ) then
	    call ploreg(np,data2d,regpar,varline,bintp,.true.)
	  else
            !call outfile_make_hkv(nkn,nel,nen3v,hm3v,hev,hkv)
            call ilhk2e(nkn,nel,nen3v,ilhkv,ilhv)
            call adjust_layer_index(nel,nlv,hev,hlv,ilhv)
	    call make_mask(l)
	    call ploval(np,data2d,varline)
	  end if

	end do

        !--------------------------------------------------------------
        ! end of routine
        !--------------------------------------------------------------

	return
   92   continue
        write(6,*) 'for non regular file we need bas, not grd file'
        stop 'error stop plot_fem_file: basin'
   93   continue
        write(6,*) 'incompatible node numbers: ',nkn,np
        stop 'error stop plot_fem_file: basin'
   94   continue
        write(6,*) 'fem file with non regular data needs basin'
        write(6,*) 'please specify basin on command line'
        stop 'error stop plot_fem_file: basin'
   95   continue
        write(6,*) 'strings not in same sequence: ',i
        write(6,*) string
        write(6,*) strings(i)
        stop 'error stop plot_fem_file: strings'
   96   continue
        write(6,*) 'nvar,nvar0: ',nvar,nvar0
        write(6,*) 'lmax,lmax0: ',lmax,lmax0    !this might be relaxed
        write(6,*) 'np,np0:     ',np,np0        !this might be relaxed
        write(6,*) 'cannot change number of variables'
        stop 'error stop plot_fem_file'
   97   continue
        write(6,*) 'record: ',irec
        write(6,*) 'cannot read data record of file'
        stop 'error stop plot_fem_file'
   98   continue
        write(6,*) 'record: ',irec
        write(6,*) 'cannot read second header of file'
        stop 'error stop plot_fem_file'
   99   continue
        write(6,*) 'record: ',irec
        write(6,*) 'cannot read header of file'
        stop 'error stop plot_fem_file'
	end

!***************************************************************
!***************************************************************
!***************************************************************

	subroutine prepare_hydro(bvel,nndim,cv3all,znv,uprv,vprv)

	use basin
	use levels
	use mod_depth
	
	implicit none

	logical bvel
	integer nndim
	real cv3all(nlvdi,nndim,0:4)
	real znv(nkn)
	real uprv(nlvdi,nkn)
	real vprv(nlvdi,nkn)

	real, allocatable :: zenv(:)
	real, allocatable :: uv(:,:)
	real, allocatable :: vv(:,:)

	allocate(zenv(3*nel))
	allocate(uv(nlvdi,nel))
	allocate(vv(nlvdi,nel))

        znv(1:nkn)     = cv3all(1,1:nkn,1)
        zenv(1:3*nel)  = cv3all(1,1:3*nel,2)
        uv(:,1:nel)    = cv3all(:,1:nel,3)
        vv(:,1:nel)    = cv3all(:,1:nel,4)

	call shy_transp2vel(bvel,nel,nkn,nlv,nlvdi,hev,zenv,nen3v
     +                          ,ilhv,hlv,uv,vv
     +                          ,uprv,vprv)

	deallocate(zenv,uv,vv)

	end

!***************************************************************

	subroutine make_mask(level)

	use levels
        use mod_plot2d
        !use mod_hydro

	implicit none

	integer level

        call reset_dry_mask

        call set_level_mask(bwater,ilhv,level)        !element has this level
        call make_dry_node_mask(bwater,bkwater)       !copy elem to node mask

        call adjust_no_plot_area
        call make_dry_node_mask(bwater,bkwater) !copy elem to node mask
        call info_dry_mask(bwater,bkwater)

	end

!***************************************************************
!***************************************************************
!***************************************************************

        subroutine initialize_color

        implicit none

        integer icolor
        real getpar
	logical has_color_table

        call colsetup
	call admin_color_table

	if( has_color_table() ) call putpar('icolor',8.)

        icolor = nint(getpar('icolor'))
        call set_color_table( icolor )
        call set_default_color_table( icolor )

	call write_color_table

        end

!***************************************************************

c*****************************************************************

        subroutine allocate_2d_arrays(npd)

        use mod_hydro_plot
        use mod_plot2d
        use mod_geom
        use mod_depth
        use evgeom
        use basin, only : nkn,nel,ngr,mbw

        implicit none

        integer npd

        integer np

        np = max(nel,npd)

        call ev_init(nel)
        call mod_geom_init(nkn,nel,ngr)

        call mod_depth_init(nkn,nel)

        call mod_plot2d_init(nkn,nel,np)
        call mod_hydro_plot_init(nkn,nel)

        write(6,*) 'allocate_2d_arrays: ',nkn,nel,ngr,np

        end

c*****************************************************************

        subroutine read_command_line_file(file)

        use basin
        !use basutil

        implicit none

        character*(*) file
        logical is_grd_file

        if( basin_is_basin(file) ) then
          write(6,*) 'reading BAS file ',trim(file)
          call basin_read(file)
          !breadbas = .true.
        else if( is_grd_file(file) ) then
          write(6,*) 'reading GRD file ',trim(file)
          call grd_read(file)
          call grd_to_basin
          call estimate_ngr(ngr)
	  call basin_set_read_basin(.true.)
          !breadbas = .false.
        else
          write(6,*) 'Cannot read this file: ',trim(file)
          stop 'error stop read_given_file: format not recognized'
        end if

        end

c*****************************************************************
c*****************************************************************
c*****************************************************************
c routines for directional plots
c*****************************************************************
c*****************************************************************
c*****************************************************************

	subroutine directional_init(nvar,ivars,ivar3,bdir,ivarplot)

	implicit none

	integer nvar
	integer ivars(nvar)
	integer ivar3
	logical bdir
	integer ivarplot(2)

	logical bvel,bwave
	integer ivar,iv,nv,ivel

	ivarplot = ivar3

	bwave = ivar3 > 230 .and. ivar3 < 240		!wave plot
	bvel = ivar3 >= 2 .and. ivar3 <= 3		!velocity/transport

	bdir = bdir .or. bvel				!bvel implies bdir
	if( .not. bwave .and. .not. bvel ) bdir = .false.

	if( .not. bdir ) return

	if( bvel ) ivarplot = 3
	if( bwave ) ivarplot = (/ivar3,233/)

	nv = 0
	do iv=1,nvar
	  ivar = ivars(iv)
	  if( ivar3 == ivar .or. any( ivarplot == ivar ) ) then
	    nv = nv + 1
	  end if
	end do

	if( bdir .and. nv /= 2 ) then
	  write(6,*) 'file does not contain needed varid: ',ivar3
          stop 'error stop shyplot'
	end if

	end

c*****************************************************************

	subroutine directional_insert(bdir,ivar,ivar3,ivarplot,cv2,ivel)

	use basin
	use mod_hydro_plot

	implicit none

	logical bdir
	integer ivar
	integer ivar3
	integer ivarplot(2)
	real cv2(*)
	integer ivel		!on return indicates if and what to plot

	logical bwave,bvel
	integer, save :: iarrow = 0

	ivel = 0

	if( .not. bdir ) return

	bwave = ivar3 > 230 .and. ivar3 < 240		!wave plot
	bvel = ivar3 >= 2 .and. ivar3 <= 3		!velocity/transport

	if( bvel ) then
	  if( ivar == 3 ) then
	    iarrow = iarrow + 1
	    if( iarrow == 1 ) utrans(1:nel) = cv2(1:nel)
	    if( iarrow == 2 ) vtrans(1:nel) = cv2(1:nel)
	  end if
	  if( iarrow == 2 ) then
	    ivel = ivar3 - 1
	    !call make_vertical_velocity
	    wsnv = 0.		!FIXME
	  end if
	end if

	if( bwave ) then
	  if( ivarplot(1) == ivar ) then
	    iarrow = iarrow + 1
	    uvspeed(1:nkn) = cv2(1:nkn)
	  else if( ivarplot(2) == ivar ) then
	    iarrow = iarrow + 1
	    uvdir(1:nkn) = cv2(1:nkn)
	  end if
	  if( iarrow == 2 ) then
	    ivel = 4
	    call polar2xy(nkn,uvspeed,uvdir,uvnode,vvnode)
	  end if
	end if

	if( ivel > 0 ) iarrow = 0

	end

c*****************************************************************

	subroutine choose_var(nvar,ivars,strings,varline,ivarplot)

	use plotutil
	use levels

c choses variable to be plotted

	implicit none

	integer nvar
	integer ivars(nvar)
	character*80 strings(nvar)
	character*80 varline
	integer ivarplot(2)

	integer nv,iv,ivar

	write(6,*) 'available variables to be plotted: '
	write(6,*) 'total number of variables: ',nvar
	write(6,*) '   varnum     varid    varname'
	do iv=1,nvar
	  ivar = ivars(iv)
	  write(6,'(2i10,4x,a)') iv,ivar,trim(strings(iv))
	end do

	if( ivnum > 0 ) then
	  if( ivnum > nvar ) then
	    write(6,*) 'ivnum too big for nvar'
	    write(6,*) 'ivnum,nvar: ',ivnum,nvar
            stop 'error stop shyplot'
	  end if
	  ivar3 = ivars(ivnum)
	  call read_str_files(ivar3)
	end if

	if( nvar == 1 .and. ivar3 == 0 ) then
	  ivnum = 1
	  ivar3 = ivars(ivnum)
	  call read_str_files(ivar3)
	end if
        if( ivar3 == 0 ) then
          write(6,*) 'no variable given to be plotted: ',ivar3
          stop 'error stop shyplot'
        end if

	write(6,*) 
	write(6,*) 'varid to be plotted:       ',ivar3
	!write(6,*) 'total number of variables: ',nvar
	!write(6,*) '   varnum     varid    varname'
	nv = 0
	do iv=1,nvar
	  ivar = ivars(iv)
	  !write(6,'(2i10,4x,a)') iv,ivar,trim(strings(iv))
	  if( ivar == ivar3 ) nv = nv + 1
	  if( ivnum == 0 .and. ivar == ivar3 ) ivnum = iv
	end do

	call directional_init(nvar,ivars,ivar3,bdir,ivarplot)

	if( nv == 0 .and. .not. bdir ) then
	  call ivar2string(ivar3,varline)
          write(6,*) 'no such variable in file: ',ivar3,varline
          stop 'error stop shyplot'
        end if

	if( layer > nlv ) then
          write(6,*) 'no such layer: ',layer
          write(6,*) 'maximum layer available: ',nlv
          stop 'error stop shyplot'
	end if

	call mkvarline(ivar3,varline)
	write(6,*) 
	write(6,*) 'information for plotting:'
	write(6,*) 'varline: ',trim(varline)
	write(6,*) 'ivnum: ',ivnum
	write(6,*) 'ivar3: ',ivar3
	write(6,*) 'layer: ',layer
	write(6,*) 

	end

c*****************************************************************

	subroutine fem_average_vertical(nlvddi,np,lmax,ilhkv,hlv,hd
     +					,data,data2d)

	implicit none

	integer nlvddi
	integer np,lmax
	integer ilhkv(np)
	real hlv(nlvddi)
	real hd(np)
	real data(nlvddi,np)
	real data2d(np)

	real hl(nlvddi)
	integer nsigma,k,lm,l,nlv
	real zeta,hsigma,h,hh
	double precision vacu,dacu

        call get_sigma_info(nlv,nsigma,hsigma)
	zeta = 0.

	do k=1,np

	  lm = min(lmax,ilhkv(k))
	  if( lm <= 1 ) then
	    data2d(k) = data(1,k)
	    cycle
	  end if
	  h = hd(k)
	  if( h < -990. ) h = hlv(lm)
	  if( h == -1. ) h = 1.
          call get_layer_thickness(lm,nsigma,hsigma
     +                          ,zeta,h,hlv,hl)

	  vacu = 0.
	  dacu = 0.
	  do l=1,lm
	    hh = hl(l)
	    vacu = vacu + data(l,k)*hh
	    dacu = dacu + hh
	  end do
	  data2d(k) = vacu / dacu

	end do

	end

c*****************************************************************

	subroutine adjust_levels_with_flag(nlvddi,np,ilhkv,flag,data3d)

	implicit none

	integer nlvddi,np
	integer ilhkv(np)
	real flag
	real data3d(nlvddi,np)

	integer i

	do i=1,np
	  if( ilhkv(i) <= 0 ) then
	    ilhkv(i) = 1
	    data3d(1,i) = flag
	  end if
	end do

	end

c*****************************************************************

