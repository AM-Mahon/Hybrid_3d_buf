      MODULE DIMENSIONS

c simulation domain dimensions
      integer nx, ny, nz
      integer num_cells
      integer num_buf_cells

      PARAMETER (nx = 110, ny = 110, nz = 7)
      PARAMETER (num_cells = (nx-1)*(ny-2)*(nz-2))
      PARAMETER (num_buf_cells = (ny-2)*(nz-2))
c particle array dimensions

      integer Ni_max
      PARAMETER (Ni_max = 20000000)

      END MODULE DIMENSIONS
