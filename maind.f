      PROGRAM MAIND
     
c----------------------------------------------------------------------
c maind.f
c Parallel version with no ion fluid, Nov 24, 2004
c----------------------------------------------------------------------

      
      USE global
      USE dimensions
      USE inputs
      USE mpi
      USE initial
      USE misc
      USE gutsp_dd
      USE gutsp_buf
      USE gutsf
      USE part_init
      USE grid_interp
      USE chem_rates

c      include 'incurv.h'

c----------------------------------------------------------------------
c Listing of all declared variables
c
c Note that the format for specifying variables at different time
c levels is based upon the number of 1/2 time steps that the varible
c is behind the current time level.  For example, 
c uf2 is 1 time step behind uf, ufp2 is 1 time step ahead of uf,
c and b12 is 1 full time step behind b1 (not 12 1/2 steps behind b 
c since b does not exist...right). b1p2 is an exception...this is a
c temporary holder for b1 at m+1 in the predictor/corrector update
c of the magnetic field.
c----------------------------------------------------------------------
c      integer time, t1, t2    !keep track of run time
c      external time

      real b0(nx,ny,nz,3),            !ambient magnetic field
     x     b1(nx,ny,nz,3),    !1st order magnetic field
     x     b12(nx,ny,nz,3),   !b1 at previous time step
     x     b1p2(nx,ny,nz,3),  !temporary b1 at time level m+1
     x     bt(nx,ny,nz,3),    !total magnetic field..mc covarient
c     x     btmf(nx,ny,nz,3),  !main cell contravarient bt field
     x     btc(nx,ny,nz,3),   !btmf at cell center for particle move
c     x     bdp(nx,ny,nz,3),   !dipole magnetic field
c     x     nf(nx,ny,nz),      !ambient fixed fluid density
c     x     nf1(nx,ny,nz),     !nf at n-1/2
c     x     nf3(nx,ny,nz),     !nf at n-3/2
c     x     nfp1(nx,ny,nz),    !nf at n+1/2
c     x     nn(nx,ny,nz),      !neutral cloud density
c     x     nnd(nx,ny,nz),     !neutral cloud density decrement
     x     np(nx,ny,nz),      !particle ion den at time level n, n+1/2
c     x     np_1(nx,ny,nz),
     x     np_2(nx,ny,nz),
c     x     np3(nx,ny,nz,3),
     x     vp(Ni_max,3),      !particle velocity at t level n+1/2
     x     vp1(Ni_max,3),     !particle velocity at t level n
     x     vplus(Ni_max,3),   !v+ used in velocity update
     x     vminus(Ni_max,3),  !v- used in velocity update
     x     up(nx,ny,nz,3),    !particle flow at time level n, n+1/2
     x     xp(Ni_max,3),      !coordinates of ion particles
c     x     xp1(Ni_max,3),     !coordinates of ion particles at previous time step
c     x     uf(nx,ny,nz,3),    !fluid velocity
c     x     uf2(nx,ny,nz,3),   !fluid velcity at time level n-1
c     x     ufp1(nx,ny,nz,3),  !fluid velocity at time level n+1/2
c     x     ufp2(nx,ny,nz,3),  !fluid velocity at time level n+1
c     x     ui(nx,ny,nz,3),    !total ion flow velocity
     x     aj(nx,ny,nz,3),    !curlB/(alpha*n) 
     x     nu(nx,ny,nz),      !collision frequency
c     x     nuin(nx,ny,nz),    !ion-neutral collision frequency
     x     Ep(Ni_max,3),      !Ion particle electric field
c     x     Ef(nx,ny,nz,3),    !fluid electric field
     x     E(nx,ny,nz,3)     !electric field from electron mom eqn
c     x     uplus(nx,ny,nz,3), !u plus used in velocity update
c     x     uminus(nx,ny,nz,3),!u minus used in velocity update
c     x     pf(nx,ny,nz),      !fluid pressure at n
c     x     pf1(nx,ny,nz)      !fluid pressure at n-1/2


      real xp_buf(Ni_max_buf,3)
      real vp_buf(Ni_max_buf,3)
      real Ep_buf(Ni_max_buf,3)
      real vplus_buf(Ni_max_buf,3)
      real vminus_buf(Ni_max_buf,3)

      real xp_out_buf(Ni_max_buf,3)
      real vp_out_buf(Ni_max_buf,3)
      real E_out_buf(Ni_max_buf,3)
      real B_out_buf(Ni_max_buf,3)
      real mrat_out_buf(Ni_max_buf)
c      real m_arr_out_buf(Ni_max_buf)

      real temp_p(nx,ny,nz)
c     x     temp_p_1(nx,ny,nz),
c     x     temp_p_2(nx,ny,nz)

      real Evp,       !total particle kinetic energy
     x     Euf,       !total fluid kinetic energy
     x     EB1,       !total magnetic field energy
     x     EB1x,      !total b1x energy
     x     EB1y,      !total b1y energy
     x     EB1z,      !total b1z energy
     x     EE,        !total electric field energy
     x     EeP        !total electron pressure energy

      real pup(3),      !total particle momentum
     x     puf(3),      !total fluid momentum
     x     peb(3),      !total momentum carried by E and B fields
     x     input_p(3)   !input momentum

c      integer np_t_flg(Ni_max)
c      integer np_b_flg(Ni_max)
c      real np_t(nx,ny,nz)
c      real np_b(nx,ny,nz)

      real mr

      real chex_rate
      real bill_rate
      real satnp
c      real gradP(nx,ny,nz,3)
c      real etemp(nx,ny,nz)
c      real ugradu(nx,ny,nz,3)
c      real minnf,maxnf
c      real divu(nx,ny,nz)
      real mindt
      integer*4 t1,t2,cnt_rt
      real time
      integer ierr

      real ndot(nx,ny,nz)
      
      integer seedsize
      integer, dimension(:), allocatable :: seeder

      real recvbuf
      integer count
      
      character(3) filenum(129) !max 16 processors                                                                      

      filenum = (/'1 ','2 ','3 ','4 ','5 ','6 ','7 ','8 ','9 ',
     x     '10','11','12','13','14','15','16','17','18','19',
     x     '20','21','22','23','24','25','26','27','28','29',
     x     '30','31','32','33','34','35','36','37','38','39',
     x     '40','41','42','43','44','45','46','47','48','49',
     x     '50','51','52','53','54','55','56','57','58','59',
     x     '60','61','62','63','64','65','66','67','68','69',
     x     '70','71','72','73','74','75','76','77','78','79',
     x     '80','81','82','83','84','85','86','87','88','89',
     x     '90','91','92','93','94','95','96','97','98','99',
     x     '100','101','102','103','104','105','106','107','108','109',
     x     '110','111','112','113','114','115','116','117','118','119',
     x     '120','121','122','123','124','125','126','127','128','129'/)

c----------------------------------------------------------------------

      call readInputs()
      call initparameters()

c      stop

      call MPI_INIT(ierr)
      call MPI_COMM_RANK(MPI_COMM_WORLD, my_rank, ierr)
      call MPI_COMM_SIZE(MPI_COMM_WORLD, procnum, ierr)

c create virtual topology (set dimensions in para.h)

      call MPI_BARRIER(MPI_COMM_WORLD,ierr)

      call MPI_CART_CREATE(MPI_COMM_WORLD, 2, dims, periods, 
     x     reorder,cartcomm, ierr)

      call MPI_COMM_RANK(cartcomm, cart_rank, ierr)
      call MPI_CART_COORDS(cartcomm, cart_rank, cart_dims, cart_coords, 
     x                     ierr)
      call MPI_CART_SHIFT(cartcomm,0,1,nbrs(n_up),nbrs(n_down),ierr)
      call MPI_CART_SHIFT(cartcomm, 1, 1, nbrs(n_left), nbrs(n_right), 
     &     ierr)

      call system_clock(t1,cnt_rt)
c      seed = float(t1)

c----------------------------------------------------------------------
c Initialize all variables
c----------------------------------------------------------------------
      write(*,*) 'initializing variables...'

      Ni_tot = Ni_tot_0
      Ni_tot_sw = Ni_tot
c      Ni_tot_sys = Ni_tot*procnum
      Ni_tot_sys = Ni_tot
      print *,'Ni_tot_sys, Ni_tot..',Ni_tot_sys,Ni_tot,Ni_tot_sw

      if (my_rank .eq. 0) then
         call check_inputs()
         write(*,*) 'Particles per cell....',Ni_tot_sys/(nx*ny*nz)
         write(*,*) ' '
      endif

c      stop

c      Ni_tot = 6
      mstart = 0
      ndiag = 0
      prev_Etot = 1.0
      nuei = 0.0

c initialize seed for each processor

c      call random_seed
c      call random_seed(size = seedsize)
c      allocate(seeder(seedsize))
c      do n = 0,procnum-1 
c         if (my_rank .eq. n) then 
c            call random_seed(get=seeder)
c            call random_seed(put=seeder)
c         endif
c      enddo

      seed = t1 +my_rank*100
      call random_initialize(seed)
      call MPI_BARRIER(MPI_COMM_WORLD,ierr) 

      if (.not.(restart)) then
         do 66 i=1,nx
            do 66 j=1,ny
               do 66 k=1,nz
c                  pf(i,j,k) = nf_init*0.05*kboltz*tempf0
c                  pf1(i,j,k) = nf_init*0.05*kboltz*tempf0
c                  nf(i,j,k) = nf_init*0.0
c                  nf1(i,j,k) = nf_init*0.05  
c                  nf3(i,j,k) = nf_init*0.05 
c                  nfp1(i,j,k) = nf_init*0.05  
                  input_E = 0.0
                  input_p = 0.0
                  input_chex = 0.0
                  input_bill = 0.0
 66               continue
               endif

c      do 68 i = 1,nx
c         do 68 j = 1,ny
c            do 68 k = 1,nz
c               uf(i,j,k,1) = -vsw
c               uf2(i,j,k,1) = -vsw
c               ufp1(i,j,k,1) = -vsw
c               ufp2(i,j,k,1) = -vsw
c 68            continue

c      Ni_tot = 4000000


      if (.not.(restart)) then
c         m_arr(1:Ni_tot) = mproton
c         m_arr(Ni_tot+1:) = m_pu*mproton !mass N_2+ = 28.0
         mrat(1:Ni_tot) = 1.0
         mrat(Ni_tot+1:) = 1.0/m_pu !mass N_2+ = 28.0
         beta_p(1:Ni_tot) = 1.0
         beta_p(Ni_tot+1:) = beta_pu
      endif

      call grd8()
      call grd6_setup(b0,bt,b12,b1,b1p2,nu)

c      call obstacle_boundary_nu(nu)

      call get_beta()

c         input_E = 0.0
c      do i = 1,nx
c         do j = 1,ny
c            do k = 1,nz
c               input_E = input_E + 
c     x          0.5*dx*dy*dz_grid(k)*nf_init*0.01*mO*(vsw*km_to_m)**2
c            enddo
c         enddo
c      enddo


      if (.not.(restart)) then
c      call sw_part_setup_temp(np,vp,vp1,xp,input_p,up)
c      call sw_part_setup_maxwl(np,vp,vp1,xp,xp1,input_p,up,np_t_flg,
c     x                         np_b_flg)
         call sw_part_setup_maxwl(np,vp,vp1,xp,input_p,up)

         call part_setup_buf(xp_buf,vp_buf)
         
         call part_setup_out_buf(xp_out_buf,vp_out_buf,E_out_buf,
     x        B_out_buf,mrat_out_buf,b0)
                  
         call get_ndot(ndot)
         call predict_B(b0,b1,b12,b1p2,bt,E,aj,up,np,nu) 
         call correct_B(b0,b1,b1p2,E,aj,up,np,nu)

         call f_update_tlev(b1,b12,b1p2,bt,b0)
      endif

c----------------------------------------------------------------------




c----------------------------------------------------------------------
c check for restart flag
c----------------------------------------------------------------------
      write(*,*) 'restart status....',restart
      if (restart) then 
         write(*,*) 'opening restart.vars......'
         open(210,file='restart.vars'//trim(filenum(my_rank)),
     x        status='unknown',
     x        form='unformatted')
         
         read(210)  b0,b1,b12,b1p2,bt,btc,np,np3,
     x        up,aj,nu,E,input_E,input_p,mstart,input_EeP,prev_Etot
     x        Evp,Euf,EB1,EB1x,EB1y,EB1z,EE,EeP

c         open(210,file='restart.vars',status='unknown',
c     x            form='unformatted')
         write(*,*) 'reading restart.vars......'
c         read(210) b0,b1,b12,b1p2,bt,btmf,btc,np,np3,vp,vp1,vplus,
c     x        vminus,up,xp,xp1,aj,nu,Ep,E,Evp,Euf,
c     x        EB1,EB1x,EB1y,EB1z,EE,EeP,input_E,Ni_tot,Ni_tot_sys,
c     x        ijkp,mstart,input_p,input_EeP,prev_Etot,
c     x        mrat,m_arr,xp_buf,vp_buf,Ep_buf,vplus_buf,
c     x        vminus_buf,xp_out_buf,vp_out_buf,E_out_buf,
c     x        B_out_buf,mrat_out_buf,m_arr_out_buf,
c     x        in_bounds,Ni_tot_buf,in_bounds_buf,Ni_tot_out_buf,
c     x        m_arr_buf,mrat_buf
c         write(*,*) 'restarting hybrid.....'

c         if (my_rank .ge. 0) then 
          open(211,file='restart.part'//trim(filenum(my_rank)),
     x           status='unknown',form='unformatted')
          read(211) vp,vp1,vplus,vminus,
     x         xp,Ep,Ni_tot,
     x         Ni_tot_sys,ijkp,
     x         mrat,
     x         xp_buf,vp_buf,Ep_buf,vplus_buf,
     x         vminus_buf,xp_out_buf,vp_out_buf,E_out_buf,
     x         B_out_buf,mrat_out_buf,
     x         in_bounds,Ni_tot_buf,in_bounds_buf,Ni_tot_out_buf,
     x         mrat_buf



c          open(211,file='restart.part'//trim(filenum(my_rank)),
c     x            status='unknown',form='unformatted')
c          read(211)  b0,b1,b12,b1p2,bt,btmf,btc,np,np3,
c     x         vp,vp1,vplus,vminus,
c     x         up,xp,xp1,aj,nu,Ep,E,input_E,Ni_tot,
c     x         Ni_tot_sys,ijkp,mstart,input_p,input_EeP,prev_Etot,
c     x         mrat,m_arr,
c     x         xp_buf,vp_buf,Ep_buf,vplus_buf,
c     x         vminus_buf,xp_out_buf,vp_out_buf,E_out_buf,
c     x         B_out_buf,mrat_out_buf,m_arr_out_buf,
c     x         in_bounds,Ni_tot_buf,in_bounds_buf,Ni_tot_out_buf,
c     x         m_arr_buf,mrat_buf
cc         endif
      endif

      close(210)
      close(211)



c      write(*,*) 'mstart...',mstart
c      stop

c      write(*,*) 'restart status....',restart
c      if (restart) then 
c         write(*,*) 'opening restart.vars......'
c         open(210,file='restart.vars',status='unknown',
c     x            form='unformatted')
c         write(*,*) 'reading restart.vars......'
c         read(210) b1,b12,b1p2,bt,btmf,nn,np,nf,vp,vp1,vplus,vminus,
c     x            up,xp,uf,uf2,ufp2,aj,Ep,Ef,E,uplus,uminus,Evp,Euf,
c     x            EB1,EB1x,EB1y,EB1z,EE,EeP,input_E,Ni_tot,
c     x            ijkp,mstart,input_p,input_EeP,prev_Etot,nf1,nf3,nfp1,
c     x            input_chex,input_bill,pf,pf1,mrat,m_arr
c         write(*,*) 'restarting hybrid.....'

c         if (my_rank .gt. 0) then 
c          open(211,file='restart.part'//trim(filenum(my_rank)),
c     x            status='unknown',form='unformatted')
c          read(211) vp,vp1,vplus,vminus,xp,Ep,input_E,Ni_tot,
c     x              ijkp,input_p,mrat,m_arr
c         endif
c      endif
      
c      close(211)
c----------------------------------------------------------------------


c----------------------------------------------------------------------
c write para.h file

      if (my_rank .eq. 0) then


         open(109, file=trim(out_dir)//'para.dat',
     x        status='unknown',form='unformatted')
         
         write(109) nx,ny,nz,dx,dy,delz
         write(109) nt,dtsub_init,ntsub,dt,nout
         write(109) out_dir
c         write(109) model_choice
c         write(109) nf_init,b0_init
c         write(109) nu_init,lww2,lww1
c         write(109) Mdot,Mdot_part
         write(109) vtop,vbottom
         write(109) Ni_max
         write(109) mproton,m_pu,m_heavy
         write(109) np_top,np_bottom
         write(109) b0_top,b0_bottom
         write(109) vth_top,vth_bottom
c         write(109) RIo
         write(109) alpha,beta
c         write(109) comm_sz
         write(109) RIo
         close(109)

      endif
 
c----------------------------------------------------------------------



c----------------------------------------------------------------------
c Initialize diagnostic output files
c----------------------------------------------------------------------


      open(110,file=trim(out_dir)//
     x     'c.np_'//trim(filenum(my_rank+1))//'.dat',
     x     status='unknown',form='unformatted')
      open(111,file=trim(out_dir)//
     x     'c.np_3d_'//trim(filenum(my_rank+1))//'.dat',
     x     status='unknown',form='unformatted')

      open(115,file=trim(out_dir)//
     x     'c.np_3d_1_'//trim(filenum(my_rank+1))//'.dat',
     x     status='unknown',form='unformatted')
      open(116,file=trim(out_dir)//
     x     'c.np_3d_2_'//trim(filenum(my_rank+1))//'.dat',
     x     status='unknown',form='unformatted')


c      open(115,file=trim(out_dir)//
c     x     'c.nf_'//trim(filenum(my_rank+1))//'.dat',
c     x     status='unknown',
c     x     form='unformatted')
c      open(116,file=trim(out_dir)//
c     x     'c.nf_3d_'//trim(filenum(my_rank+1))//'.dat',
c     x     status='unknown',
c     x     form='unformatted')

c      open(120,file=trim(out_dir)//
c     x     'c.uf_'//trim(filenum(my_rank+1))//'.dat',
c     x     status='unknown',
c     x     form='unformatted')
c      open(121,file=trim(out_dir)//
c     x     'c.uf_3d_'//trim(filenum(my_rank+1))//'.dat',
c     x     status='unknown',
c     x     form='unformatted')

      open(130,file=trim(out_dir)//
     x     'c.b1_'//trim(filenum(my_rank+1))//'.dat',
     x     status='unknown',
     x     form='unformatted')
      open(131,file=trim(out_dir)//
     x     'c.b1_3d_'//trim(filenum(my_rank+1))//'.dat',
     x     status='unknown',
     x     form='unformatted')

      open(140,file=trim(out_dir)//
     x     'c.aj_'//trim(filenum(my_rank+1))//'.dat',
     x     status='unknown',
     x     form='unformatted')

      open(150,file=trim(out_dir)//
     x     'c.E_'//trim(filenum(my_rank+1))//'.dat',
     x     status='unknown',
     x     form='unformatted')

c      open(160,file=trim(out_dir)//
c     x     'c.energy_'//trim(filenum(my_rank+1))//'.dat',
c     x     status='unknown',
c     x     form='unformatted')

c      open(170,file=trim(out_dir)//
c     x     'c.chex_'//trim(filenum(my_rank+1))//'.dat',
c     x     status='unknown',
c     x     form='unformatted')

c      open(172,file=trim(out_dir)//
c     x     'c.bill_'//trim(filenum(my_rank+1))//'.dat',
c     x     status='unknown',
c     x     form='unformatted')

c      open(175,file=trim(out_dir)//
c     x     'c.satnp_'//trim(filenum(my_rank+1))//'.dat',
c     x     status='unknown',
c     x     form='unformatted')

      open(180,file=trim(out_dir)//
     x     'c.up_'//trim(filenum(my_rank+1))//'.dat',
     x     status='unknown',
     x     form='unformatted')
      open(181,file=trim(out_dir)//
     x     'c.up_3d_'//trim(filenum(my_rank+1))//'.dat',
     x     status='unknown',
     x     form='unformatted')

c      open(190,file=trim(out_dir)//
c     x     'c.momentum_'//trim(filenum(my_rank+1))//'.dat',
c     x     status='unknown',
c     x     form='unformatted')

c      open(192,file=trim(out_dir)//
c     x     'c.p_conserve_'//trim(filenum(my_rank+1))//'.dat',
c     x     status='unknown',               
c     x     form='unformatted')                 

      open(300,file=trim(out_dir)//
     x     'c.temp_p_'//trim(filenum(my_rank+1))//'.dat',
     x     status='unknown',
     x     form='unformatted')
      open(301,file=trim(out_dir)//
     x     'c.temp_p_3d_'//trim(filenum(my_rank+1))//'.dat',
     x     status='unknown',
     x     form='unformatted')

      open(305,file=trim(out_dir)//
     x     'c.xp_'//trim(filenum(my_rank+1))//'.dat',
     x     status='unknown',
     x     form='unformatted')

      open(310,file=trim(out_dir)//
     x     'c.vp_'//trim(filenum(my_rank+1))//'.dat',
     x     status='unknown',
     x     form='unformatted')

      open(315,file=trim(out_dir)//
     x     'c.beta_p_'//trim(filenum(my_rank+1))//'.dat',
     x     status='unknown',
     x     form='unformatted')

      open(320,file=trim(out_dir)//
     x     'c.mrat_'//trim(filenum(my_rank+1))//'.dat',
     x     status='unknown',
     x     form='unformatted')

      open(320,file=trim(out_dir)//
     x     'c.mrat_'//trim(filenum(my_rank+1))//'.dat',
     x     status='unknown',
     x     form='unformatted')


      open(330,file=trim(out_dir)//
     x     'c.temp_p_3d_1_'//trim(filenum(my_rank+1))//'.dat',
     x     status='unknown',
     x     form='unformatted')

      open(331,file=trim(out_dir)//
     x     'c.temp_p_3d_2_'//trim(filenum(my_rank+1))//'.dat',
     x     status='unknown',
     x     form='unformatted')

      

c      open(320,file='c.uf2.dat',status='unknown',
c     x         form='unformatted')

c      open(330,file='c.ufp2.dat',status='unknown',
c     x         form='unformatted')

c      open(340,file='c.eta.dat',status='unknown',
c     x         form='unformatted')

c      open(350,file=trim(out_dir)//
c     x     'c.pf_'//trim(filenum(my_rank+1))//'.dat',
c     x     status='unknown',
c     x     form='unformatted')
c      open(351,file=trim(out_dir)//
c     x     'c.pf_3d_'//trim(filenum(my_rank+1))//'.dat',
c     x     status='unknown',
c     x     form='unformatted')

c----------------------------------------------------------------------


c======================================================================
c  MAIN LOOP!
c======================================================================

      do 1 m = mstart+1, nt

         if (my_rank .eq. 0) then
            write(*,*) 'time...', m, m*dt
         endif

         !Calculate neutral density


         !Ionize cloud and calculate ion density
         write(*,*) 'Ni_tot...',Ni_tot,Ni_max,my_rank
         call separate_np(np_2,mr)
         if (Ni_tot .lt. 0.8*Ni_max) then
c          call Ionize_Io(np,vp,vp1,xp,xp1,up,ndot)
            mr = 1.0/m_pu
            call Ionize_pluto_mp(np,np_2,vp,vp1,xp,m,input_p,up)
         endif

         call get_interp_weights(xp)
         call update_np(np)             !np at n+1/2
         call update_up(vp,np,up)       !up at n+1/2
         call update_np_boundary(np)

         !energy diagnostics
         
         call get_bndry_Eflux(b1,E)
         call Energy_diag(vp,b0,b1,E,Evp,Euf,EB1,EB1x,EB1y,EB1z,EE,
     x                    EeP,nu,up,np)
         

         call curlB(b1,np,aj)
c         call obstacle_boundary_B(b0,b1)

c         call cov_to_contra(bt,btmf)
c         call face_to_center(btmf,btc)       !interp bt to cell center
         
         call edge_to_center(bt,btc)

         call extrapol_up(up,vp,vp1,np)
         call get_Ep(Ep,aj,np,up,btc,nu)
         call get_vplus_vminus(Ep,btc,vp,vplus,vminus)
         call improve_up(vp1,vplus,vminus,up,np)
         call get_Ep(Ep,aj,np,up,btc,nu)
         call get_vplus_vminus(Ep,btc,vp,vplus,vminus)
         call get_vp_final(Ep,vp,vp1,vplus)
         
         call move_ion_half(xp,vp,vp1,input_p,Ep)

                  !1/2 step ion move to n+1/2
c         call check_min_den_boundary(np,xp,vp,up)

         call get_Ep_buf(Ep_buf,b0,xp_buf,up)
         call get_vplus_vminus_buf(Ep_buf,vp_buf,vplus_buf,
     x        vminus_buf,b0)
         call get_vp_buf_final(Ep_buf,vp_buf,vplus_buf)
         call move_ion_half_buf(xp_buf,vp_buf,xp,vp,vp1)
c         call part_setup_buf(xp_buf,vp_buf)
         call move_ion_out_buf(xp_out_buf,vp_out_buf,E_out_buf,
     x        B_out_buf,mrat_out_buf)
         call exchange_ion_half(xp,vp,vp1,input_p,xp_buf,vp_buf,E,Bt,
     x                  xp_out_buf,vp_out_buf,E_out_buf,
     x                  B_out_buf,mrat_out_buf)
         call exchange_ion_half_buf(xp_buf,vp_buf,xp,vp,vp1)
         call exchange_ion_out_buf(xp_out_buf,vp_out_buf,E_out_buf,
     x        B_out_buf,mrat_out_buf,xp,vp,vp1)

         call part_setup_buf(xp_buf,vp_buf)

         call get_interp_weights(xp)
         call update_np(np)             !np at n+1/2
         call update_up(vp,np,up)       !up at n+1/2
         ndiag = ndiag + 1
         if (ndiag .eq. nout) then         
            call get_temperature(xp,vp,np,temp_p)
c            mr = 1.0
c            call separate_np(np_1,mr)
c            mr = 1.0/m_pu
c            call separate_np(np_2,mr)
c            mr = 1.0
c            call separate_temp(vp,temp_p_1,mr)
c            mr = 1.0/m_pu
c            call separate_temp(vp,temp_p_2,mr)
         endif
         call update_np_boundary(np)

         
c**********************************************************************
c SUBCYCLING LOOP!
c**********************************************************************

         dtsub = dtsub_init
         ntf = ntsub
call MPI_Barrier(MPI_COMM_WORLD,ierr)

         
         call check_time_step(bt,np)

         count = 1

         call MPI_ALLREDUCE(ntf,recvbuf,count,
     x        MPI_REAL,MPI_MAX,MPI_COMM_WORLD,ierr)

         write(*,*) 'nft max...',recvbuf
         ntf = recvbuf

         call MPI_BARRIER(MPI_COMM_WORLD,ierr)

      do 2 n = 1, ntf

c         write(*,*) 'subcycle step...',n,ntf

         !convert main cell covarient bt to main cell contravarient
c         call cov_to_contra(bt,btmf) 
c         call edge_to_center(bt,btc)
         call curlB(b1,np,aj)     
c         call obstacle_boundary_B(b0,b1)

         !update fluid velocity, uf 

c only need predict_uf when calculating ugradu

cc         call trans_nf_Lax(nf,nf1,nfp1,uf) 
c         call trans_nf_LaxWend1(nf,nf1,nfp1,uf)
c         call trans_pf_LaxWend1(pf,pf1,uf)

c         call get_nuin(nuin,nn,uf)
c         call predict_uf(Ef,b0,b1,b12,uf,uf2,ufp2,nu,np,nf1,uplus, 
c     x                   uminus,ugradu,up,gradP,nuin,bdp,pf1)

c         call predict_nf(nf,nf1,nf3,nfp1,uf,divu,b1)  

c         call get_nuin(nuin,nn,uf)
c         call correct_uf(Ef,btmf,uf,uf2,ufp2,nu,np,nf,uplus,uminus, 
c     x                   ugradu,aj,up,ufp1,gradP,nuin,pf)

c         call trans_nf_LaxWend2(nf,nf1,nfp1,ufp1)
c         call trans_pf_LaxWend2(pf,pf1,ufp1)

         !update magnetic field, b1
c         call predict_B(b1,b12,b1p2,bt,btmf,E,aj,up,uf,uf2,np,nf,nu,
c     x                  gradP) 


         call predict_B(b0,b1,b12,b1p2,bt,E,aj,up,np,nu) 
c         call predict_B(b0,b1,b12,b1p2,bt,btmf,E,aj,up,np,nu) 


c         call correct_nf(nf,nf1,ufp1)

c         call correct_B(b0,b1,b1p2,E,aj,up,uf,np,nfp1,nu,gradP,bdp)
         call correct_B(b0,b1,b1p2,E,aj,up,np,nu)


c         call f_update_tlev(uf,uf2,b1,b12,b1p2,bt,b0,bdp)
         call f_update_tlev(b1,b12,b1p2,bt,b0)

c         call Momentum_diag(up,uf,np,nf,E,b1,pup,puf,peb,input_p)
c         call check_momentum(uf,nf,bt,ugradu)
c         write(192) m
c         write(192) n
c         write(192) surf_tot, graduu_tot, ugradu_tot



 2     continue
c**********************************************************************


         call move_ion_half(xp,vp,vp1,input_p,Ep)

         call move_ion_half_buf(xp_buf,vp_buf,xp,vp,vp1)
c         call part_setup_buf(xp_buf,vp_buf)

         call move_ion_out_buf(xp_out_buf,vp_out_buf,E_out_buf,
     x        B_out_buf,mrat_out_buf)
         

         call exchange_ion_half(xp,vp,vp1,input_p,xp_buf,vp_buf,E,Bt,
     x                      xp_out_buf,vp_out_buf,E_out_buf,
     x                      B_out_buf,mrat_out_buf)

         call exchange_ion_half_buf(xp_buf,vp_buf,xp,vp,vp1)

         call exchange_ion_out_buf(xp_out_buf,vp_out_buf,E_out_buf,
     x        B_out_buf,mrat_out_buf,xp,vp,vp1)

c         call check_min_den_boundary(np,xp,vp,up)

         call check_min_den(np,xp,vp,vp1,up,bt)

         if (Ni_tot .lt. 0.8*Ni_max) then
            call res_chex(xp,vp,vp1)
         endif

c         endif

c         write(*,*) 'Momentum conservation...'
c         write(*,*) '  Particles.............',pup(1),pup(2),pup(3)
c         write(*,*) '  Fluid.................',puf(1),puf(2),puf(3)
c         write(*,*) '  ExB...................',peb(1),peb(2),peb(3)
c         write(*,*) '  Normalized............',
c     x                        (pup(1)+puf(1)+peb(1))/input_p(1),
c     x                        (pup(2)+puf(2)+peb(2))/input_p(2),
c     x                        (pup(3)+puf(3)+peb(3))/input_p(3)

c         call get_np3(np,np3)

c         call update_mixed


c----------------------------------------------------------------------
c diagnostic output
c----------------------------------------------------------------------

         call MPI_BARRIER(MPI_COMM_WORLD,ierr)

c         if (my_rank .eq. 0) then
c            write(160) m
c            write(160) input_E,input_EeP,Evp,Euf,EB1,EB1x,EB1y,EB1z,EE,
c     x           EeP,input_chex,input_bill
c            write(190) m
c            write(190) pup, puf, peb, input_p
c            write(320) np(ri-20,rj,rk),np(ri-40,rj,rk),
c     x                 np(ri-40,rj,rk+50),np(ri+5,rj,rk)
c         endif


         if (ndiag .eq. nout) then

c            call separate_np(np_1,1.0)
c            call separate_np(np_2,1/m_pu)
c            call get_temperature(xp,vp,np,temp_p)
c            call separate_temp(temp_p_1,1.0)
c            call separate_temp(temp_p_2,1/m_pu)

            nproc_2rio = nint(100*rio/(delz*nz))
c            write(*,*) 'nproc_2rio....',nproc_2rio,
c     x           (comm_sz/2)-nproc_2rio

            call MPI_BARRIER(MPI_COMM_WORLD,ierr)
c save 3d arrays------------------------
            if ((my_rank .ge. comm_sz/2-nproc_2rio) .and. 
     x           (my_rank .lt. comm_sz/2+nproc_2rio)) then
               write(111) m
               write(111) np
c               write(115) m
c               write(115) np_1
c               write(116) m
c               write(116) np_2
               write(131) m
               write(131) bt
c               write(140) m
c               write(140) aj
c               write(150) m
c               write(150) E
               write(181) m
               write(181) up
               write(301) m
               write(301) temp_p/1.6e-19
               write(305) m
               write(305) xp
               write(310) m
               write(310) vp
               write(315) m
               write(315) beta_p
               write(320) m
               write(320) mrat
c               write(330) m 
c               write(330) temp_p_1/1.6e-19
c               write(331) m 
c               write(331) temp_p_2/1.6e-19

           endif


c save 2d arrays----------------------
               write(110) m
               write(110) np(:,ny/2,:),np(:,:,2)
               write(130) m
               write(130) bt(:,ny/2,:,:),bt(:,:,2,:)
c               write(140) m
c               write(140) aj
c               write(150) m
c               write(150) E
               write(180) m
               write(180) up(:,ny/2,:,:),up(:,:,2,:)
               write(300) m
               write(300) temp_p(:,ny/2,:)/1.6e-19,
     x                    temp_p(:,:,2)/1.6e-19
               ndiag = 0

         endif

c----------------------------------------------------------------------


c----------------------------------------------------------------------
c Write restart file
c----------------------------------------------------------------------

c         if (my_rank .eq. 0) then
c            if (m .eq. mrestart) then
c               open(220,file='restart.vars.new',status='unknown',
c     x              form='unformatted')
c               write(220) b0,b1,b12,b1p2,bt,btmf,btc,np,np3,vp,vp1,
c     x              vplus,vminus,
c     x              up,xp,xp1,aj,nu,Ep,E,Evp,Euf,
c     x              EB1,EB1x,EB1y,EB1z,EE,EeP,input_E,Ni_tot,
c     x              Ni_tot_sys,
c     x              ijkp,mrestart,input_p,input_EeP,prev_Etot,
c     x              mrat,m_arr,xp_buf,vp_buf,Ep_buf,vplus_buf,
c     x              vminus_buf,xp_out_buf,vp_out_buf,E_out_buf,
c     x              B_out_buf,mrat_out_buf,m_arr_out_buf,
c     x              in_bounds,Ni_tot_buf,in_bounds_buf,Ni_tot_out_buf,
c     x              m_arr_buf,mrat_buf
cc                    write(220) b1,b12,b1p2,bt,btmf,nn,np,nf,vp,vp1,
cc     x           vplus,vminus,
cc     x          up,xp,uf,uf2,ufp2,aj,Ep,Ef,E,uplus,uminus,Evp,Euf,
cc     x          EB1,EB1x,EB1y,EB1z,EE,EeP,input_E,Ni_tot,
cc     x          ijkp,mrestart,input_p,input_EeP,prev_Etot,nf1,nf3,nfp1,
cc     x          input_chex,input_bill,pf,pf1,mrat,m_arr  
c            endif
c         endif
         
         if (my_rank .ge. 0) then
         if (m .eq. mrestart) then
            write(*,*) 'writing restart file....',
     x  'restart.part'//trim(filenum(my_rank))//'.new'

          open(220,file='restart.vars'//trim(filenum(my_rank))//'.new',
     x           status='unknown',
     x           form='unformatted')

          write(220)  b0,b1,b12,b1p2,bt,btc,np,np3,
     x         up,aj,nu,E,input_E,input_p,mrestart,input_EeP,prev_Etot,
     x         Evp,Euf,EB1,EB1x,EB1y,EB1z,EE,EeP

          open(221,file='restart.part'//trim(filenum(my_rank))//'.new',
     x           status='unknown',form='unformatted')
          write(221) vp,vp1,vplus,vminus,
     x         xp,Ep,Ni_tot,
     x         Ni_tot_sys,ijkp,
     x         mrat,
     x         xp_buf,vp_buf,Ep_buf,vplus_buf,
     x         vminus_buf,xp_out_buf,vp_out_buf,E_out_buf,
     x         B_out_buf,mrat_out_buf,
     x         in_bounds,Ni_tot_buf,in_bounds_buf,Ni_tot_out_buf,
     x         mrat_buf
            
c       write(211) b0,b1,b12,b1p2,bt,btmf,btc,np,np3
c     x         vp,vp1,vplus,vminus,xp,xp1,Ep,input_E,Ni_tot,
c     x         ijkp,input_p,mrat,m_arr,
c     x         xp_buf,vp_buf,Ep_buf,vplus_buf,
c     x         vminus_buf,xp_out_buf,vp_out_buf,E_out_buf,
c     x         B_out_buf,mrat_out_buf,m_arr_out_buf,
c     x         in_bounds,Ni_tot_buf,in_bounds_buf,Ni_tot_out_buf,
c     x         m_arr_buf,mrat_buf
            
         endif
         endif

c----------------------------------------------------------------------


         call MPI_BARRIER(MPI_COMM_WORLD,ierr)


 1     continue
c======================================================================

c       if(my_rank .eq. 0) then

          close(110)
          close(115)
          close(116)
          close(120)
          close(130)
          close(140)
          close(150)
          close(160)
          close(170)
          close(172)
          close(175)
          close(180)
          close(190)
          close(192)
          close(210)
          close(211)
          close(220)
          close(221)
          close(300)
          close(305)
          close(310)
          close(315)
          close(320)
          close(330)
          close(331)
c     close(340)
          close(350)

c       endif

       call system_clock(t2,cnt_rt)
       time = (real(t2) - real(t1))/real(cnt_rt)
       if (my_rank .eq. 0) then
          write(*,*) 
          write(*,*) 'Elapsed time....',time,' sec'
          write(*,*)
       endif

         call MPI_BARRIER(MPI_COMM_WORLD,ierr)

       call MPI_FINALIZE(ierr)

       stop 
       end


















